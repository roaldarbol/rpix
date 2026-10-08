#' Switch to another environment's R
#'
#' @description
#' Move your work to the R of another of the project's environments, e.g. one
#' with another version of R. A running R can't change its own version or
#' library, so this starts the other R the way your IDE needs:
#'
#' * RStudio: starts a new RStudio with the environment's R, in the project.
#'   Close the old one when you're done with it.
#' * Positron: opens the interpreter picker, to pick the environment's R.
#' * VS Code: points the R extension at the environment's R, in the project's
#'   `.vscode/settings.json`. Reload the window to use it. On Windows, start VS
#'   Code from the environment instead.
#' * Elsewhere: shows the command that starts the environment's R.
#'
#' The environment is installed first, if it isn't yet.
#'
#' @param environment The environment.
#' @param ide Optional. The IDE: `"rstudio"`, `"positron"` or `"vscode"`.
#'   Defaults to the one you're in.
#' @inheritParams pixi_environments
#' @returns The environment's R, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_switch("r44")
#' }
pixi_switch <- function(environment, ide = NULL, path = NULL) {
  root <- require_project(path)
  ide <- ide %||% detect_ide()
  environments <- pixi_environments(root)$name
  if (!environment %in% environments) {
    cli::cli_abort(c(
      "There's no {.val {environment}} environment in the project.",
      "i" = "Its environments are {.val {environments}}."
    ))
  }
  run_pixi(c("install", "--environment", environment), path = root)
  r <- environment_r(root, environment)

  switch(
    if (is.na(ide)) "none" else ide,
    rstudio = switch_rstudio(root, environment),
    positron = switch_positron(environment),
    vscode = switch_vscode(root, environment),
    none = cli::cli_alert_info(
      "Start its R with {.code pixi run --environment {environment} R}."
    )
  )
  invisible(r)
}

# Where an environment's R is
environment_r <- function(root, environment) {
  prefix <- file.path(root, ".pixi", "envs", environment)
  if (is_windows()) {
    file.path(prefix, "lib", "R", "bin", "x64", "R.exe")
  } else {
    file.path(prefix, "bin", "R")
  }
}

switch_rstudio <- function(root, environment) {
  rproj <- rstudio_project_file(root)
  task <- rstudio_task(pixi_info(root)$platform, basename(rproj))
  # The command runs in Pixi's shell, which understands `VAR=value command`
  command <- paste(c(task$env, task$cmd), collapse = " ")
  start_detached(c("run", "--environment", environment, command), root)
  cli::cli_alert_success(
    "Started RStudio with the {.val {environment}} environment's R. Close this RStudio when you're done with it."
  )
}

# Start Pixi in the background, and let it outlive this R
start_detached <- function(args, root) {
  processx::process$new(
    pixi_binary(),
    add_manifest_arg(args, find_manifest(root)),
    wd = root,
    env = pixi_env("never"),
    cleanup = FALSE
  )
}

switch_positron <- function(environment) {
  cli::cli_alert_info(
    "Pick {.val (Pixi: {environment})} in the interpreter picker."
  )
  execute <- positron_command()
  if (!is.null(execute)) {
    execute("workbench.action.languageRuntime.selectRuntime")
  }
}

# Positron's R runs its commands with this function, which Ark defines
positron_command <- function() {
  get0(".ps.ui.executeCommand", envir = globalenv(), mode = "function")
}

switch_vscode <- function(root, environment) {
  if (is_windows()) {
    cli::cli_alert_info(
      "Close VS Code, and start it again from the environment with {.code pixi run --environment {environment} code .}."
    )
    return(invisible())
  }
  r <- paste0("${workspaceFolder}/.pixi/envs/", environment, "/bin/R")
  update_vscode_settings(
    root,
    list("r.executablePath" = r, "r.consolePath" = r)
  )
  cli::cli_alert_info(
    "Run {.strong Developer: Reload Window} from the Command Palette to use it."
  )
}
