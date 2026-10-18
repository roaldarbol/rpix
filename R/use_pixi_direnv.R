#' Activate the project's environment with direnv
#'
#' @description
#' Write a `.envrc` file that activates the project's Pixi environment with
#' [direnv](https://direnv.net) whenever you're in the project's folder: in a
#' shell with direnv's hook, and in editors that load direnv, such as Emacs,
#' Neovim and Zed (see [use_pixi_emacs()]). R, languageserver and anything
#' else started there then come from the environment.
#'
#' If the project has a `.envrc` already, its other lines are kept. direnv
#' only loads a `.envrc` you've allowed, and again after it changes: in an
#' interactive session, `use_pixi_direnv()` offers to allow it. Install
#' direnv with `pixi global install direnv`. In a package, `.envrc` is added
#' to `.Rbuildignore`.
#'
#' @param environment The environment to activate.
#' @inheritParams use_pixi_ide
#' @returns The `.envrc` file, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi_direnv()
#' use_pixi_direnv(environment = "r44")
#' }
use_pixi_direnv <- function(path = NULL, environment = "default") {
  root <- require_project(path)
  file <- file.path(root, ".envrc")
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  writeLines(set_envrc_environment(lines, environment), file)
  cli::cli_alert_success(
    "Set {.path .envrc} to activate the {.val {environment}} environment."
  )
  build_ignore(root, ".envrc")
  allow_direnv(root)
  invisible(file)
}

# The .envrc lines that activate an environment. A line that already
# activates one, e.g. from an earlier run, or direnv's `layout pixi`, is
# changed; otherwise rpix's lines are added.
set_envrc_environment <- function(lines, environment) {
  hook <- paste0(
    'eval "$(pixi shell-hook --shell bash --environment ',
    environment,
    ')"'
  )
  shell_hook <- grep("pixi shell-hook", lines, fixed = TRUE)
  layout <- grep("^\\s*layout pixi", lines)
  if (length(shell_hook) > 0) {
    lines[shell_hook] <- hook
  } else if (length(layout) > 0) {
    lines[layout] <- paste("layout pixi --environment", environment)
  } else {
    lines <- c(
      lines,
      "# Activate the project's Pixi environment (written by rpix)",
      "watch_file pixi.toml pixi.lock",
      hook
    )
  }
  lines
}

# Ask to allow the .envrc, or say how
allow_direnv <- function(root) {
  direnv <- direnv_binary()
  if (!nzchar(direnv)) {
    cli::cli_alert_info(
      "Install direnv with {.code pixi global install direnv}, and hook it into your shell ({.url https://direnv.net/docs/hook.html}). Then run {.code direnv allow} in the project."
    )
  } else if (
    is_interactive() && ask_yes_no("Allow direnv to load the project's .envrc?")
  ) {
    processx::run(direnv, c("allow", root))
    cli::cli_alert_success("Allowed {.path .envrc}.")
  } else {
    cli::cli_alert_info(
      "Run {.code direnv allow} in the project to let direnv load it."
    )
  }
}

direnv_binary <- function() {
  Sys.which("direnv")
}

# Whether the project's .envrc activates the environment as rpix writes it
envrc_activates <- function(root, environment) {
  file <- file.path(root, ".envrc")
  if (!file.exists(file)) {
    return(FALSE)
  }
  lines <- readLines(file, warn = FALSE)
  identical(set_envrc_environment(lines, environment), lines)
}

# Whether the project's .envrc activates a Pixi environment
direnv_set_up <- function(root) {
  file <- file.path(root, ".envrc")
  file.exists(file) &&
    any(grepl(
      "pixi shell-hook|^\\s*layout pixi",
      readLines(file, warn = FALSE)
    ))
}
