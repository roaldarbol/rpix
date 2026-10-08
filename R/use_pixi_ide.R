#' Set up an IDE for a Pixi project
#'
#' @description
#' Set an IDE up to use the R in the project's Pixi environment. [use_pixi()]
#' calls these with its `ide` argument.
#'
#' * `use_pixi_rstudio()` adds an `rstudio` task to `pixi.toml`, for each of
#'   the project's platforms, that starts a new RStudio with the
#'   environment's R and the project's `.Rproj` file. It creates the `.Rproj`
#'   file if there isn't one. Start RStudio with `pixi run rstudio`.
#' * `use_pixi_positron()` turns on Positron's discovery of R in Pixi
#'   environments, in `.vscode/settings.json`. Pick the project's R ("R
#'   (Pixi: default)") once in Positron's interpreter picker; Positron
#'   activates the environment when it starts R.
#' * `use_pixi_vscode()` adds languageserver to the environment, and points
#'   the R extension for VS Code (and VSCodium) at the environment's R, in
#'   `.vscode/settings.json`. On Windows, the environment's R only starts
#'   when the environment is activated, so it leaves R to be found on the
#'   `PATH` instead: start VS Code with `pixi run code .`.
#'
#' Existing settings in `.vscode/settings.json` are kept.
#'
#' @param path The project. Defaults to the working directory.
#' @returns The file they changed, invisibly.
#' @name use_pixi_ide
#' @examples
#' \dontrun{
#' use_pixi_rstudio()
#' use_pixi_positron()
#' use_pixi_vscode()
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
use_pixi_positron <- function(path = NULL) {
  root <- require_project(path)
  file <- update_vscode_settings(
    root,
    list("positron.r.interpreters.pixiDiscovery" = TRUE)
  )
  cli::cli_alert_info(
    "In Positron, pick {.val R (Pixi: default)} in the interpreter picker. Positron remembers it for the project."
  )
  invisible(file)
}

#' @rdname use_pixi_ide
#' @export
use_pixi_vscode <- function(path = NULL) {
  root <- require_project(path)
  # sess and jgd, which the R extension also uses, aren't on conda-forge yet
  # (#56)
  run_pixi(c("add", "r-languageserver"), path = root, echo = TRUE)

  if (is_windows()) {
    file <- file.path(root, ".vscode", "settings.json")
    cli::cli_alert_info(
      "Start VS Code from the project's environment, with {.code pixi run code .}: on Windows, its R only starts when the environment is activated."
    )
  } else {
    r <- "${workspaceFolder}/.pixi/envs/default/bin/R"
    file <- update_vscode_settings(
      root,
      list("r.executablePath" = r, "r.consolePath" = r)
    )
  }
  cli::cli_alert_info(
    "When the R extension offers to install its {.pkg sess} package, accept."
  )
  invisible(file)
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
#' Keeps the settings already there. VS Code allows comments in the file,
#' which jsonlite can't keep, so a file with comments isn't changed.
#' @noRd
update_vscode_settings <- function(root, values, call = parent.frame()) {
  file <- file.path(root, ".vscode", "settings.json")
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
        lines <- paste0(
          "\"",
          names(values),
          "\": ",
          vapply(values, jsonlite::toJSON, character(1), auto_unbox = TRUE)
        )
        cli::cli_abort(
          c(
            "Can't update {.path {file}}: it isn't plain JSON, e.g. because it has comments.",
            "i" = "Add these settings yourself:",
            stats::setNames(cli_escape(lines), rep(" ", length(lines)))
          ),
          call = call
        )
      }
    )
  }
  settings[names(values)] <- values

  dir.create(dirname(file), showWarnings = FALSE)
  jsonlite::write_json(settings, file, auto_unbox = TRUE, pretty = TRUE)
  cli::cli_alert_success(
    "Updated {.path {file.path('.vscode', 'settings.json')}}."
  )
  invisible(file)
}

# A // that isn't part of a URL (as in "https://"), or a /*
has_json_comments <- function(lines) {
  any(grepl("(^|[^:])//|/[*]", lines))
}
