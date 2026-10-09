#' Run a Pixi command
#'
#' @description
#' Internal workhorse that every exported function uses to call Pixi. It
#' locates the pixi binary, points Pixi at the right project with
#' `--manifest-path`, captures the output and turns failures into R errors.
#'
#' @param args Character vector of arguments passed to pixi, e.g.
#'   `c("add", "r-dplyr")`. Each element is passed as a single argument, so no
#'   shell quoting is needed.
#' @param project Whether the command needs a Pixi project:
#'   * `"required"`: find the project and pass `--manifest-path`; error if
#'     there is none.
#'   * `"optional"`: pass `--manifest-path` if a project is found.
#'   * `"none"`: never pass `--manifest-path`.
#' @param path Where to look for the project. Defaults to the project of the
#'   running pixi environment (`PIXI_PROJECT_ROOT`), and otherwise the working
#'   directory. See `find_project_root()`.
#' @param json If `TRUE`, add `--json` and return the parsed output.
#' @param echo If `TRUE`, stream Pixi's output to the console while it runs.
#' @param announce If `TRUE`, say which command runs before streaming its
#'   output.
#' @param dry_run If `TRUE`, show the command without running it.
#' @param secrets Values, such as tokens, that are never shown: they're
#'   replaced with `<hidden>` in the command rpix shows, in Pixi's output and
#'   in errors.
#' @param call The calling environment, used in error messages.
#'
#' @returns
#' * With `dry_run = TRUE`: the command as a string, invisibly.
#' * With `json = TRUE`: the parsed JSON output.
#' * Otherwise: a list with `command`, `status`, `stdout` and `stderr`,
#'   invisibly.
#' @noRd
run_pixi <- function(
  args,
  project = c("required", "optional", "none"),
  path = NULL,
  json = FALSE,
  echo = FALSE,
  announce = echo,
  dry_run = FALSE,
  secrets = NULL,
  call = parent.frame()
) {
  project <- match.arg(project)

  manifest <- NULL
  if (project != "none") {
    manifest <- find_manifest(path)
    if (is.null(manifest) && project == "required") {
      cli::cli_abort(
        c(
          "Could not find a Pixi project.",
          "i" = "Looked for {.file pixi.toml} or a {.file pyproject.toml} with a {.code [tool.pixi]} table in {.path {path %||% getwd()}} and its parents.",
          "i" = "Create one with {.code pixi init}."
        ),
        class = "rpix_error_no_project",
        call = call
      )
    }
  }

  if (json) {
    args <- c(args, "--json")
    echo <- FALSE
  }

  # Show the manifest relative to the working directory to keep the command
  # readable; it's equivalent when run from there
  shown <- args
  shown[shown %in% secrets] <- "<hidden>"
  command <- format_command(add_manifest_arg(shown, display_path(manifest)))
  args <- add_manifest_arg(args, manifest)

  if (isTRUE(dry_run)) {
    cli::cli_alert_info("Would run: {.code {command}}")
    return(invisible(command))
  }

  if (echo && announce) {
    cli::cli_alert_info("Running {.code {command}}")
  }

  use_color <- echo && cli::num_ansi_colors() > 1
  # Pixi reports progress on stderr, which processx's echo turns red, so show
  # both streams as they are, and keep them apart in the result
  show <- if (echo) function(x, process) cat(hide_secrets(x, secrets))
  result <- processx::run(
    pixi_binary(call = call),
    args,
    error_on_status = FALSE,
    stdout_callback = show,
    stderr_callback = show,
    env = pixi_env(if (use_color) "always" else "never")
  )

  result$stdout <- hide_secrets(result$stdout, secrets)
  result$stderr <- hide_secrets(result$stderr, secrets)

  if (result$status != 0) {
    abort_pixi_failure(command, result, echoed = echo, call = call)
  }

  if (json) {
    return(jsonlite::fromJSON(result$stdout))
  }

  invisible(list(
    command = command,
    status = result$status,
    stdout = result$stdout,
    stderr = result$stderr
  ))
}

# Replace secrets in text with <hidden>
hide_secrets <- function(text, secrets) {
  for (secret in secrets[nzchar(secrets)]) {
    text <- gsub(secret, "<hidden>", text, fixed = TRUE)
  }
  text
}

#' Locate the pixi executable
#'
#' Looks, in order, at the `rpix.pixi_path` option, the `PATH`, and pixi's
#' default installation directory (`$PIXI_HOME/bin`, which defaults to
#' `~/.pixi/bin`).
#' @noRd
pixi_binary <- function(call = parent.frame()) {
  option <- getOption("rpix.pixi_path")
  if (!is.null(option)) {
    if (!file.exists(option)) {
      cli::cli_abort(
        "The {.code rpix.pixi_path} option points to {.path {option}}, which doesn't exist.",
        class = "rpix_error_pixi_not_found",
        call = call
      )
    }
    return(normalizePath(option, winslash = "/"))
  }

  on_path <- Sys.which("pixi")
  if (nzchar(on_path)) {
    return(unname(on_path))
  }

  exe <- if (is_windows()) "pixi.exe" else "pixi"
  pixi_home <- Sys.getenv("PIXI_HOME", file.path(home_dir(), ".pixi"))
  default <- file.path(pixi_home, "bin", exe)
  if (file.exists(default)) {
    return(normalizePath(default, winslash = "/"))
  }

  cli::cli_abort(
    c(
      "Could not find Pixi.",
      "i" = "Install it from {.url https://pixi.prefix.dev}.",
      "i" = "If it's installed somewhere unusual, set {.code options(rpix.pixi_path = \"/path/to/pixi\")}."
    ),
    class = "rpix_error_pixi_not_found",
    call = call
  )
}

#' Find the root of a Pixi project
#'
#' If `path` is `NULL`, uses the project of the running Pixi environment
#' (`PIXI_PROJECT_ROOT`) when set, and otherwise starts from the working
#' directory. Walks up from there until it finds a `pixi.toml`, or a
#' `pyproject.toml` with a `[tool.pixi]` table.
#'
#' @returns The project root, or `NULL` if there is none.
#' @noRd
find_project_root <- function(path = NULL) {
  manifest <- find_manifest(path)
  if (is.null(manifest)) {
    return(NULL)
  }
  dirname(manifest)
}

#' Find the manifest of a Pixi project
#'
#' Same search as `find_project_root()`, but returns the manifest file.
#' @returns The path to the manifest file, or `NULL` if there is none.
#' @noRd
find_manifest <- function(path = NULL) {
  if (is.null(path)) {
    path <- Sys.getenv("PIXI_PROJECT_ROOT", getwd())
  }
  dir <- normalizePath(path, winslash = "/", mustWork = FALSE)

  repeat {
    pixi_toml <- file.path(dir, "pixi.toml")
    if (file.exists(pixi_toml)) {
      return(pixi_toml)
    }
    pyproject <- file.path(dir, "pyproject.toml")
    if (file.exists(pyproject) && has_pixi_table(pyproject)) {
      return(pyproject)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      return(NULL)
    }
    dir <- parent
  }
}

has_pixi_table <- function(pyproject) {
  lines <- readLines(pyproject, warn = FALSE)
  any(grepl("^\\s*\\[tool\\.pixi[].]", lines))
}

#' Format pixi arguments as a copy-pasteable shell command
#' @noRd
format_command <- function(args) {
  needs_quotes <- !grepl("^[A-Za-z0-9_./=:@+-]+$", args) & args != "<hidden>"
  args[needs_quotes] <- paste0(
    "\"",
    gsub("\"", "\\\\\"", args[needs_quotes]),
    "\""
  )
  paste(c("pixi", args), collapse = " ")
}

# `pixi run` passes everything after the command on to it, so the manifest has
# to come straight after `run` there
# Environment variables for Pixi: this R's, without the ones R sets for
# itself, which would point another environment's R at this R's files
pixi_env <- function(color) {
  env <- Sys.getenv()
  r_session <- c(
    "R_HOME",
    "R_SHARE_DIR",
    "R_INCLUDE_DIR",
    "R_DOC_DIR",
    "R_ARCH",
    "R_LIBS_SITE"
  )
  env <- env[!names(env) %in% r_session]
  c(stats::setNames(as.character(env), names(env)), PIXI_COLOR = color)
}

add_manifest_arg <- function(args, manifest) {
  if (is.null(manifest)) {
    return(args)
  }
  manifest_arg <- c("--manifest-path", manifest)
  if (identical(args[1], "run")) {
    return(c("run", manifest_arg, args[-1]))
  }
  c(args, manifest_arg)
}

display_path <- function(path) {
  if (is.null(path)) {
    return(NULL)
  }
  wd <- paste0(normalizePath(getwd(), winslash = "/"), "/")
  if (startsWith(path, wd)) substring(path, nchar(wd) + 1) else path
}

abort_pixi_failure <- function(command, result, echoed, call) {
  # Pixi's output has already been shown, so don't repeat it
  if (echoed) {
    details <- c("i" = "See Pixi's output above.")
  } else {
    details <- pixi_output_bullets(result)
  }

  cli::cli_abort(
    c(
      "{.code {command}} failed with exit status {result$status}.",
      details
    ),
    class = "rpix_error_pixi",
    status = result$status,
    stdout = result$stdout,
    stderr = result$stderr,
    call = call
  )
}

pixi_output_bullets <- function(result) {
  output <- strip_ansi(result$stderr)
  if (!nzchar(trimws(output))) {
    output <- strip_ansi(result$stdout)
  }
  lines <- strsplit(trimws(output), "\n", fixed = TRUE)[[1]]
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) > 20) {
    lines <- c("...", utils::tail(lines, 20))
  }
  stats::setNames(cli_escape(lines), rep(" ", length(lines)))
}

strip_ansi <- function(x) {
  gsub("\033\\[[0-9;]*[A-Za-z]", "", x)
}

# Escape braces so cli doesn't try to interpolate text coming from pixi
cli_escape <- function(x) {
  x <- gsub("{", "{{", x, fixed = TRUE)
  gsub("}", "}}", x, fixed = TRUE)
}

is_windows <- function() {
  .Platform$OS.type == "windows"
}

home_dir <- function() {
  if (is_windows()) Sys.getenv("USERPROFILE") else path.expand("~")
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
