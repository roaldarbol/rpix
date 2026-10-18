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
#'   running pixi environment (`PIXI_WORKSPACE_ROOT`), unless the working
#'   directory is in another project. See `find_project_root()`.
#' @param json If `TRUE`, add `--json` and return the parsed output.
#' @param echo If `TRUE`, stream Pixi's output to the console while it runs.
#' @param announce If `TRUE`, say which command runs.
#' @param on_output Optional. A function called with each piece of Pixi's
#'   output as it comes, e.g. to show progress while the output is kept back.
#' @param dry_run If `TRUE`, show the command without running it.
#' @param secrets Values, such as tokens, that are never shown: they're
#'   replaced with `<hidden>` in the command rpix shows, in Pixi's output and
#'   in errors.
#' @param call The calling environment, used in error messages.
#'
#' @returns
#' * With `dry_run = TRUE`: the command as a string, invisibly.
#' * With `json = TRUE`: the parsed JSON output.
#' * Otherwise: a list with `command`, `status`, `stdout`, `stderr` and
#'   `output` (both streams, in the order Pixi wrote them), invisibly. A
#'   failure's error has the same fields, and `echoed`.
#' @importFrom rlang abort
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
  on_output = NULL,
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

  # Pixi would activate the project's old location from its cache
  if (!is.null(manifest) && args[1] %in% c("run", "shell", "shell-hook")) {
    remove_stale_activation_cache(dirname(manifest))
  }

  if (announce) {
    cli::cli_alert_info("Running {.code {command}}")
  }

  use_color <- echo && cli::num_ansi_colors() > 1
  # Pixi reports progress on stderr, which processx's echo turns red, so show
  # both streams as they are, and keep them apart in the result. Both are
  # also kept together, in order, to show later if they were kept back.
  output <- character()
  show <- function(x, process) {
    output <<- c(output, x)
    if (echo) {
      cat(hide_secrets(x, secrets))
    }
    if (!is.null(on_output)) {
      on_output(x)
    }
  }
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
  result$output <- hide_secrets(paste(output, collapse = ""), secrets)

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
    stderr = result$stderr,
    output = result$output
  ))
}

# Whether to show Pixi's output that rpix otherwise keeps back, such as build
# logs
rpix_verbose <- function() {
  isTRUE(getOption("rpix.verbose"))
}

# Show Pixi's output that was kept back while it ran
show_pixi_output <- function(result) {
  cat(result$output)
}

# For a failure whose output was kept back, e.g. to try something else first,
# and that rpix can't handle: show the output in full, and return the error
# as if it had been shown
reveal_pixi_failure <- function(e) {
  if (isTRUE(e$echoed)) {
    return(e)
  }
  show_pixi_output(e)
  tryCatch(
    abort_pixi_failure(e$command, e, echoed = TRUE, call = e$call),
    rpix_error_pixi = identity
  )
}

# Run a long Pixi step with its output kept back, e.g. a build log: say `step`
# while it runs, and show the output only if it fails. In a console that can
# redraw the line, a spinner turns as Pixi writes; elsewhere each turn would
# be a line of its own. With `options(rpix.verbose = TRUE)`, show the output
# as it runs.
run_pixi_step <- function(args, step, done = step, path = NULL) {
  if (rpix_verbose()) {
    return(run_pixi(args, path = path, echo = TRUE))
  }
  id <- cli::cli_progress_step(
    "{step}{cli::symbol$ellipsis}",
    msg_done = "{done}",
    spinner = TRUE
  )
  tryCatch(
    run_pixi(
      args,
      path = path,
      on_output = if (cli::is_dynamic_tty()) {
        function(x) cli::cli_progress_update(id = id)
      }
    ),
    rpix_error_pixi = function(e) {
      cli::cli_progress_done(id = id, result = "failed")
      stop(reveal_pixi_failure(e))
    }
  )
}

# Pixi's output as plain text: without colours, the error tree's
# box-drawing characters and line breaks. Bytes rather than characters, so it
# works in any locale.
plain_pixi_output <- function(text) {
  text <- gsub("\033\\[[0-9;]*m", "", text, useBytes = TRUE)
  text <- gsub("[^ -~]+", " ", text, useBytes = TRUE)
  gsub("[[:space:]]+", " ", text, useBytes = TRUE)
}

# When a channel refused access (401 or 403), the status and host. NULL for
# other errors.
access_denied <- function(text) {
  text <- plain_pixi_output(text)
  pattern <- "\\((401|403) [A-Za-z ]+\\) for url \\(?[a-z0-9+.-]+://([^/ )]+)"
  match <- regmatches(text, regexec(pattern, text))[[1]]
  if (length(match) == 0) {
    return(NULL)
  }
  list(status = match[2], host = match[3])
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
#' `~/.pixi/bin`). If Pixi isn't there, and `offer_install` is `TRUE`, offers
#' to install it in an interactive session.
#' @noRd
pixi_binary <- function(offer_install = TRUE, call = parent.frame()) {
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

  if (offer_install && is_interactive()) {
    cli::cli_alert_warning("rpix needs Pixi, which isn't installed.")
    installed <- tryCatch(install_pixi(), rpix_cancelled = function(e) NULL)
    if (!is.null(installed)) {
      return(normalizePath(installed, winslash = "/"))
    }
  }

  cli::cli_abort(
    c(
      "Could not find Pixi.",
      "i" = "Install it with {.code install_pixi()}, or as {.url https://pixi.prefix.dev/latest/installation/} describes.",
      "i" = "If it's installed somewhere unusual, set {.code options(rpix.pixi_path = \"/path/to/pixi\")}."
    ),
    class = "rpix_error_pixi_not_found",
    call = call
  )
}

#' Find the root of a Pixi project
#'
#' If `path` is `NULL`, uses the project of the running Pixi environment
#' (`PIXI_WORKSPACE_ROOT`) when the working directory is in it, or in no
#' project, and otherwise starts from the working directory. Walks up from
#' there until it finds a `pixi.toml`, or a `pyproject.toml` with a
#' `[tool.pixi]` table.
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

# The root of the running Pixi environment's project, or "". Pixi 0.82 names
# it PIXI_WORKSPACE_ROOT, and keeps PIXI_PROJECT_ROOT, which older versions
# set, as an alias.
pixi_root_env <- function() {
  root <- Sys.getenv("PIXI_WORKSPACE_ROOT")
  if (!nzchar(root)) {
    root <- Sys.getenv("PIXI_PROJECT_ROOT")
  }
  root
}

#' Find the manifest of a Pixi project
#'
#' Same search as `find_project_root()`, but returns the manifest file.
#' @returns The path to the manifest file, or `NULL` if there is none.
#' @noRd
find_manifest <- function(path = NULL) {
  if (is.null(path)) {
    return(running_manifest())
  }
  search_manifest(path)
}

# The manifest of the running Pixi environment's project, unless the working
# directory is in another project: in a copied or moved project, Pixi's
# activation cache can point PIXI_WORKSPACE_ROOT to the original (#217)
running_manifest <- function() {
  here <- search_manifest(getwd())
  root <- pixi_root_env()
  if (!nzchar(root)) {
    return(here)
  }
  running <- search_manifest(root)
  if (is.null(here) || identical(running, here)) {
    return(running)
  }
  var <- if (nzchar(Sys.getenv("PIXI_WORKSPACE_ROOT"))) {
    "PIXI_WORKSPACE_ROOT"
  } else {
    "PIXI_PROJECT_ROOT"
  }
  cli::cli_inform(
    c(
      "!" = "{.envvar {var}} points to {.path {root}}, so using the working directory's project, {.path {dirname(here)}}.",
      "i" = "If the project was copied or moved, check it with {.code pixi_sitrep()}."
    ),
    .frequency = "once",
    .frequency_id = "rpix_other_workspace_root"
  )
  here
}

search_manifest <- function(path) {
  dir <- normalizePath(path, winslash = "/", mustWork = FALSE)

  repeat {
    manifest <- manifest_in(dir)
    if (!is.null(manifest)) {
      return(manifest)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      return(NULL)
    }
    dir <- parent
  }
}

# The manifest in the folder itself, not in a parent folder, or NULL
manifest_in <- function(dir) {
  pixi_toml <- file.path(dir, "pixi.toml")
  if (file.exists(pixi_toml)) {
    return(pixi_toml)
  }
  pyproject <- file.path(dir, "pyproject.toml")
  if (file.exists(pyproject) && has_pixi_table(pyproject)) {
    return(pyproject)
  }
  NULL
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
  denied <- access_denied(paste(result$stderr, result$stdout))
  if (!is.null(denied)) {
    details <- c(
      details,
      "i" = "{.val {denied$host}} refused access ({denied$status}), so Pixi probably needs credentials for it.",
      "i" = "Log in with {.code pixi_auth_login(\"{denied$host}\")}, and see {.fn pixi_auth_login} for other ways to log in."
    )
  }

  cli::cli_abort(
    c(
      "{.code {command}} failed with exit status {result$status}.",
      details
    ),
    class = c(if (!is.null(denied)) "rpix_error_access", "rpix_error_pixi"),
    command = command,
    status = result$status,
    stdout = result$stdout,
    stderr = result$stderr,
    output = result$output,
    echoed = echoed,
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
