#' Set up an IDE for a Pixi project
#'
#' @description
#' Set an IDE up to use the R in the project's Pixi environment. [use_pixi()]
#' calls these with its `ide` argument.
#'
#' * `use_pixi_rstudio()` adds, or replaces, an `rstudio` task in `pixi.toml`, for each of
#'   the project's platforms, that starts a new RStudio with the
#'   environment's R and the project's `.Rproj` file. It creates the `.Rproj`
#'   file if there isn't one. Start RStudio with `pixi run rstudio`.
#' * `use_pixi_positron()` turns on Positron's discovery of R in Pixi
#'   environments, and makes the default environment's R Positron's default
#'   for the project, in `.vscode/settings.json`. Positron (2026.10 or later)
#'   then starts that R when the project opens, until you pick another R
#'   there. The path is for the operating system you run it on; on another
#'   one, Positron ignores it.
#' * `use_pixi_vscode()` adds languageserver, and the console if it isn't R,
#'   to the environment. It points the R extension for VS Code, and the
#'   editors based on it such as VSCodium, Cursor and Windsurf, at the
#'   environment's R and the console, in `.vscode/settings.json`. On
#'   Windows, the environment's R only starts when the environment is
#'   activated, so it leaves R and the console to be found on the `PATH`
#'   instead: start VS Code with `pixi run code .` (or `codium`, `cursor` or
#'   `windsurf` instead of `code`).
#'
#' In an interactive session, `use_pixi_vscode()` asks which console to use,
#' unless `console` is given. Otherwise it keeps the console already set up,
#' or R.
#'
#' Existing settings in `.vscode/settings.json` are kept. In a package,
#' `.vscode` is added to `.Rbuildignore`.
#'
#' @param path The project. Defaults to the working directory.
#' @param console For `use_pixi_vscode()`: the R console, `"R"`,
#'   [`"arf"`](https://github.com/eitsupi/arf) or
#'   [`"radian"`](https://github.com/randy3k/radian). `NULL` asks.
#' @param default_r For `use_pixi_positron()`: if `TRUE`, make the default
#'   environment's R Positron's default for the project.
#' @returns The file they changed, invisibly.
#' @name use_pixi_ide
#' @examples
#' \dontrun{
#' use_pixi_rstudio()
#' use_pixi_positron()
#' use_pixi_vscode(console = "arf")
#' }
NULL

#' @rdname use_pixi_ide
#' @export
use_pixi_rstudio <- function(path = NULL) {
  root <- require_project(path)
  rproj <- rstudio_project_file(root)

  for (platform in project_platforms(root)) {
    task <- rstudio_task(platform, basename(rproj))
    if (is.null(task)) {
      next
    }
    # Replace the task if it's there, e.g. from an earlier run. Pixi says if
    # it isn't, without failing.
    run_pixi(
      c("task", "remove", "rstudio", "--platform", platform),
      path = root
    )
    run_pixi(
      c(
        "task",
        "add",
        "rstudio",
        task$cmd,
        "--platform",
        platform,
        if (!is.null(task$env)) c("--env", task$env),
        "--description",
        "Start RStudio with the project's R"
      ),
      path = root,
      echo = TRUE
    )
  }

  cli::cli_alert_info("Start RStudio with {.code pixi run rstudio}.")
  invisible(file.path(root, "pixi.toml"))
}

#' @rdname use_pixi_ide
#' @export
use_pixi_positron <- function(path = NULL, default_r = TRUE) {
  root <- require_project(path)
  settings <- list("positron.r.interpreters.pixiDiscovery" = TRUE)
  if (isTRUE(default_r)) {
    settings[["positron.r.interpreters.default"]] <- positron_default_r()
  }
  file <- update_vscode_settings(root, settings)
  if (isTRUE(default_r)) {
    cli::cli_alert_info(
      "Positron (2026.10 or later) now starts the project's R when you open the project; restart it if it's open. If you've picked another R in this project before, pick {.val R (Pixi: default)} once."
    )
  } else {
    cli::cli_alert_info(
      "In Positron, pick {.val R (Pixi: default)} in the interpreter picker. Positron remembers it for the project. If it isn't listed, run {.strong Interpreter: Discover All Interpreters} from the Command Palette."
    )
  }
  invisible(file)
}

# The default environment's R, as Positron's settings take it: relative to
# the project, for this operating system
positron_default_r <- function() {
  environment_r("${workspaceFolder}", "default")
}

#' @rdname use_pixi_ide
#' @export
use_pixi_vscode <- function(path = NULL, console = NULL) {
  root <- require_project(path)
  consoles <- c("R", "arf", "radian")
  if (is.null(console)) {
    console <- vscode_console(root)
    if (is_interactive()) {
      choice <- ask_choice(
        "Which R console should VS Code start? If it isn't R, it's added to the environment.",
        consoles
      )
      if (!is.na(choice)) console <- consoles[choice]
    }
  }
  console <- match.arg(console, consoles)
  # sess and jgd, which the R extension also uses, aren't on conda-forge yet
  # (#56)
  run_pixi(
    c("add", "r-languageserver", if (console != "R") console),
    path = root,
    echo = TRUE
  )

  file <- update_vscode_settings(root, vscode_settings("default", console))
  if (is_windows()) {
    cli::cli_alert_info(
      "Start VS Code from the project's environment, with {.code pixi run code .}: on Windows, its R only starts when the environment is activated."
    )
    vscode_forks_hint()
  }
  cli::cli_alert_info(
    "When the R extension offers to install its {.pkg sess} package, accept."
  )
  invisible(file)
}

# VSCodium, Cursor and Windsurf read the same settings, but have their own
# command
vscode_forks_hint <- function() {
  cli::cli_alert_info(
    "For VSCodium, Cursor or Windsurf, use {.code codium}, {.code cursor} or {.code windsurf} instead of {.code code}."
  )
}

# The R extension's settings for an environment's R, and a console. The
# console comes from the default environment, where use_pixi_vscode() adds
# it: arf and radian don't depend on R, so they can start any environment's.
# On Windows, R only starts in an activated environment, so they're left to
# be found on the PATH. A NULL removes a setting.
vscode_settings <- function(environment, console) {
  if (is_windows()) {
    return(list(
      "r.consolePath" = if (console != "R") console,
      "r.consoleArgs" = NULL,
      "r.bracketedPaste" = if (console != "R") TRUE
    ))
  }
  prefix <- paste0("${workspaceFolder}/.pixi/envs/", environment)
  r <- paste0(prefix, "/bin/R")
  args <- switch(
    console,
    R = NULL,
    arf = list(
      "--r-home",
      paste0(prefix, "/lib/R"),
      "--no-save",
      "--no-restore"
    ),
    radian = list(paste0("--r-binary=", r))
  )
  list(
    "r.executablePath" = r,
    "r.consolePath" = if (console == "R") {
      r
    } else {
      paste0("${workspaceFolder}/.pixi/envs/default/bin/", console)
    },
    "r.consoleArgs" = args,
    "r.bracketedPaste" = if (console != "R") TRUE
  )
}

# The console the R extension is set up with, from its settings
vscode_console <- function(root) {
  file <- file.path(root, ".vscode", "settings.json")
  path <- NULL
  if (file.exists(file)) {
    path <- tryCatch(
      jsonlite::read_json(file)[["r.consolePath"]],
      error = function(e) NULL
    )
  }
  console <- sub("[.]exe$", "", basename(path %||% "R"))
  if (console %in% c("arf", "radian")) console else "R"
}

require_project <- function(path, call = parent.frame()) {
  root <- find_project_root(path %||% getwd())
  if (is.null(root)) {
    cli::cli_abort(
      c(
        "There's no Pixi project in {.path {path %||% getwd()}}.",
        "i" = "Create one with {.code use_pixi()}."
      ),
      call = call
    )
  }
  root
}

# Platforms of the project's default environment
project_platforms <- function(path) {
  info <- run_pixi("info", path = path, json = TRUE)
  envs <- info$environments_info
  envs$platforms[[which(envs$name == "default")]]$name
}

# The command, and environment variable, that start RStudio on a platform
rstudio_task <- function(platform, rproj) {
  if (startsWith(platform, "osx")) {
    list(cmd = paste("open -n -a RStudio", rproj))
  } else if (startsWith(platform, "linux")) {
    list(cmd = paste("rstudio", rproj))
  } else if (startsWith(platform, "win")) {
    # Pixi doesn't set RSTUDIO_WHICH_R on Windows, and RStudio isn't on the
    # PATH there
    list(
      cmd = paste('"C:/Program Files/RStudio/rstudio.exe"', rproj),
      env = "RSTUDIO_WHICH_R=$CONDA_PREFIX/lib/R/bin/x64/R.exe"
    )
  }
}

# The project's .Rproj file, created if there isn't one
rstudio_project_file <- function(root) {
  existing <- list.files(root, pattern = "\\.Rproj$", full.names = TRUE)
  if (length(existing) > 0) {
    return(existing[1])
  }
  file <- file.path(root, paste0(basename(root), ".Rproj"))
  writeLines(
    c(
      "Version: 1.0",
      "",
      "RestoreWorkspace: No",
      "SaveWorkspace: No",
      "AlwaysSaveHistory: Default",
      "",
      "EnableCodeIndexing: Yes",
      "Encoding: UTF-8",
      "",
      "AutoAppendNewline: Yes",
      "StripTrailingWhitespace: Yes"
    ),
    file
  )
  cli::cli_alert_success("Created {.path {basename(file)}}.")
  file
}

#' Add settings to the project's `.vscode/settings.json`
#'
#' Keeps the settings already there; a `NULL` value removes one. VS Code
#' allows comments in the file, which jsonlite can't keep, so a file with
#' comments isn't changed.
#' @noRd
update_vscode_settings <- function(root, values, call = parent.frame()) {
  file <- file.path(root, ".vscode", "settings.json")
  remove <- vapply(values, is.null, logical(1))
  if (all(remove) && !file.exists(file)) {
    return(invisible(file))
  }
  settings <- list()
  if (file.exists(file)) {
    settings <- tryCatch(
      {
        # jsonlite reads comments, but writing the file back would drop them
        if (has_json_comments(readLines(file, warn = FALSE))) {
          stop("comments")
        }
        jsonlite::read_json(file)
      },
      error = function(e) {
        set <- values[!remove]
        lines <- character()
        if (length(set) > 0) {
          lines <- paste0(
            "\"",
            names(set),
            "\": ",
            vapply(set, jsonlite::toJSON, character(1), auto_unbox = TRUE)
          )
        }
        cli::cli_abort(
          c(
            "Can't update {.path {file}}: it isn't plain JSON, e.g. because it has comments.",
            if (length(set) > 0) c("i" = "Add these settings yourself:"),
            stats::setNames(cli_escape(lines), rep(" ", length(lines))),
            if (any(remove)) {
              c("i" = "Remove {.field {names(values)[remove]}}.")
            }
          ),
          call = call
        )
      }
    )
  }
  settings[names(values)[!remove]] <- values[!remove]
  settings[names(values)[remove]] <- NULL

  dir.create(dirname(file), showWarnings = FALSE)
  jsonlite::write_json(settings, file, auto_unbox = TRUE, pretty = TRUE)
  cli::cli_alert_success(
    "Updated {.path {file.path('.vscode', 'settings.json')}}."
  )
  build_ignore(root, ".vscode")
  invisible(file)
}

# A // that isn't part of a URL (as in "https://"), or a /*
has_json_comments <- function(lines) {
  any(grepl("(^|[^:])//|/[*]", lines))
}
