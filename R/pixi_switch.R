#' Switch to another environment's R
#'
#' @description
#' Move your work to the R of another of the project's environments, e.g. one
#' with another version of R. A running R can't change its own version or
#' library, so this starts the other R the way your IDE needs:
#'
#' * RStudio: starts a new RStudio with the environment's R, in the project.
#'   Close the old one when you're done with it.
#' * Positron: looks for interpreters again, and opens the interpreter
#'   picker, to pick the environment's R.
#' * VS Code, and editors based on it: points the R extension at the
#'   environment's R, in the project's `.vscode/settings.json`, keeping its
#'   console (R, arf or radian; see [use_pixi_vscode()]). Reload the window
#'   to use it. On Windows, start the editor from the environment instead.
#' * Emacs, Neovim and Zed: points the project's `.envrc` at the environment
#'   (see [use_pixi_direnv()]). Reload direnv in the editor, and restart R.
#'   On Windows, start the editor from the environment instead.
#' * Elsewhere: shows the command that starts the environment's R.
#'
#' The environment is installed first, if it isn't yet.
#'
#' @param environment The environment. In an interactive session, leave it
#'   out to pick one from a menu.
#' @param ide Optional. The IDE: `"rstudio"`, `"positron"`, `"vscode"`,
#'   `"emacs"`, `"neovim"` or `"zed"`.
#'   Defaults to the one you're in.
#' @inheritParams pixi_environments
#' @returns The environment's R, invisibly, or `NULL` if you cancel the menu.
#' @export
#' @examples
#' \dontrun{
#' pixi_switch("r44")
#' # Pick from a menu
#' pixi_switch()
#' }
pixi_switch <- function(environment = NULL, ide = NULL, path = NULL) {
  root <- require_project(path)
  ide <- ide %||% detect_ide()
  environments <- pixi_environments(root)$name
  if (is.null(environment)) {
    environment <- pick_environment(environments)
    if (is.na(environment)) {
      return(invisible(NULL))
    }
  }
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
    emacs = ,
    neovim = ,
    zed = switch_direnv(root, environment, ide),
    none = cli::cli_alert_info(
      "Start its R with {.code pixi run --environment {environment} R}."
    )
  )
  invisible(r)
}

# Ask which environment to switch to, marking the one R runs in. NA if
# cancelled.
pick_environment <- function(environments, call = parent.frame()) {
  if (!is_interactive()) {
    cli::cli_abort(
      c(
        "Which environment? Give {.arg environment}.",
        "i" = "The project's environments are {.val {environments}}."
      ),
      call = call
    )
  }
  current <- environments == Sys.getenv("PIXI_ENVIRONMENT_NAME")
  labels <- paste0(environments, ifelse(current, " (current)", ""))
  choice <- ask_choice("Which environment do you want to switch to?", labels)
  environments[choice]
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
    "Pick the R labelled {.val (Pixi: {environment})} in the interpreter picker."
  )
  execute <- positron_command()
  if (!is.null(execute)) {
    # Positron doesn't list environments added since it last looked, e.g.
    # one added while it's open
    execute("workbench.action.language.runtime.discoverAllRuntimes")
    execute("workbench.action.languageRuntime.selectRuntime")
  } else {
    cli::cli_alert_info(
      "If it isn't listed, run {.strong Interpreter: Discover All Interpreters} from the Command Palette."
    )
  }
}

# Positron's R runs its commands with this function, which Ark defines
positron_command <- function() {
  get0(".ps.ui.executeCommand", envir = globalenv(), mode = "function")
}

switch_vscode <- function(root, environment) {
  console <- vscode_console(root)
  # vscode_settings() takes the console from the default environment, but on
  # Windows from the PATH, i.e. the environment VS Code starts in
  home <- if (is_windows()) environment else "default"
  if (
    console != "R" && !file.exists(environment_console(root, home, console))
  ) {
    add <- if (home == "default") {
      "Add it with {.code pixi_add(\"{console}\")}."
    } else {
      "Add it to one of its features with {.code pixi_add(\"{console}\", feature = ...)}."
    }
    cli::cli_alert_warning(c(
      "The {.val {home}} environment doesn't have {console}. ",
      add
    ))
  }
  if (is_windows()) {
    cli::cli_alert_info(
      "Close VS Code, and start it again from the environment with {.code pixi run --environment {environment} code .}."
    )
    vscode_forks_hint()
    return(invisible())
  }
  update_vscode_settings(root, vscode_settings(environment, console))
  cli::cli_alert_info(
    "Run {.strong Developer: Reload Window} from the Command Palette to use it."
  )
}

switch_direnv <- function(root, environment, ide) {
  name <- ide_name(ide)
  if (is_windows()) {
    cli::cli_alert_info(
      "Close {name}, and start it again from the environment with {.code pixi run --environment {environment} {editor_command(ide)}}."
    )
    return(invisible())
  }
  use_pixi_direnv(root, environment)
  cli::cli_alert_info(switch(
    ide,
    emacs = "Run {.strong M-x envrc-reload} in Emacs, then restart R.",
    neovim = "Restart Neovim from the project (or reload direnv in it), then restart R.",
    zed = "Reopen the project in Zed, then restart R."
  ))
}

# Where an environment's console is
environment_console <- function(root, environment, console) {
  prefix <- file.path(root, ".pixi", "envs", environment)
  if (!is_windows()) {
    return(file.path(prefix, "bin", console))
  }
  switch(
    console,
    arf = file.path(prefix, "Library", "bin", "arf.exe"),
    radian = file.path(prefix, "Scripts", "radian.exe")
  )
}
