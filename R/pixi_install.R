#' Install and update the project's packages
#'
#' @description
#' * `pixi_install()` installs an environment as `pixi.lock` describes it,
#'   e.g. after cloning a project. `pixi run` does this by itself, too. If
#'   `pixi.lock` is out of date with `pixi.toml`, Pixi updates it first,
#'   unless `locked` or `frozen` says otherwise.
#' * `pixi_update()` updates packages to the newest versions `pixi.toml`
#'   allows, in `pixi.lock`.
#' * `pixi_upgrade()` updates packages beyond that, and raises the versions in
#'   `pixi.toml` to match.
#' * `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
#'   installing anything.
#'
#' Package names are translated like in [pixi_add()]. If Pixi skips an install
#' script that a package needs, such as the ones Bioconductor's data packages
#' download their data with, these functions offer to allow them in the
#' project, as [pixi_add()] does.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/install/>,
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/update/>,
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/upgrade/> and
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/lock/>.
#'
#' @param environment Optional. The environment. Defaults to `default`.
#' @param all If `TRUE`, install all the project's environments.
#' @param locked If `TRUE`, fail if `pixi.lock` is out of date with
#'   `pixi.toml`, rather than updating it, e.g. to check that a collaborator
#'   or CI gets exactly what's committed.
#' @param frozen If `TRUE`, install exactly what `pixi.lock` says, without
#'   checking it against `pixi.toml`.
#' @param packages Optional. Only update these packages. Defaults to all.
#' @param feature Optional. Only upgrade the packages of this feature.
#' @inheritParams pixi_environments
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' pixi_install(path = project, dry_run = TRUE)
#' pixi_update("dplyr", path = project, dry_run = TRUE)
#' pixi_upgrade(path = project, dry_run = TRUE)
pixi_install <- function(
  environment = NULL,
  all = FALSE,
  locked = FALSE,
  frozen = FALSE,
  path = NULL,
  dry_run = FALSE
) {
  if (isTRUE(locked) && isTRUE(frozen)) {
    cli::cli_abort(
      c(
        "Use {.arg locked} or {.arg frozen}, not both.",
        "i" = "{.arg locked} fails if {.file pixi.lock} is out of date; {.arg frozen} doesn't check."
      )
    )
  }
  args <- c(
    "install",
    if (!is.null(environment)) c("--environment", environment),
    if (all) "--all",
    if (isTRUE(locked)) "--locked",
    if (isTRUE(frozen)) "--frozen"
  )
  result <- run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
  if (!isTRUE(dry_run)) {
    check_post_link(result, path = path, environment = environment)
  }
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_update <- function(
  packages = NULL,
  environment = NULL,
  path = NULL,
  dry_run = FALSE
) {
  args <- c(
    "update",
    package_names(packages),
    if (!is.null(environment)) c("--environment", environment)
  )
  result <- run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
  if (!isTRUE(dry_run)) {
    check_post_link(result, path = path, environment = environment)
  }
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_upgrade <- function(
  packages = NULL,
  feature = NULL,
  path = NULL,
  dry_run = FALSE
) {
  args <- c(
    "upgrade",
    package_names(packages),
    if (!is.null(feature)) c("--feature", feature)
  )
  result <- run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
  if (!isTRUE(dry_run)) {
    check_post_link(result, path = path)
  }
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_lock <- function(path = NULL, dry_run = FALSE) {
  run_pixi("lock", path = path, echo = TRUE, dry_run = dry_run)
}

# Conda names of packages, or nothing for none
package_names <- function(packages) {
  if (length(packages) == 0) {
    return(NULL)
  }
  parse_packages(packages)$name
}

# After pixi add and pixi remove, Pixi only installs when the project has one
# environment (https://github.com/roaldarbol/rpix/issues/202). Otherwise,
# install the environment this R runs in, or else the default one, if the
# change applies to it, so what was added can be loaded straight away.
install_changed_environment <- function(feature = NULL, path = NULL) {
  if (tolower(Sys.getenv("PIXI_NO_INSTALL")) %in% c("1", "true")) {
    return(NULL)
  }
  # The change is made by now, so not knowing the environments doesn't fail it
  environments <- tryCatch(pixi_environments(path), error = function(e) NULL)
  if (is.null(environments) || nrow(environments) <= 1) {
    return(NULL)
  }
  running <- pixi_r_location(r_home())
  root <- find_project_root(path %||% getwd())
  environment <- if (
    !is.null(running) &&
      !is.null(root) &&
      same_path(running$root, root) &&
      running$name %in% environments$name
  ) {
    running$name
  } else {
    "default"
  }
  features <- environments$features[[match(environment, environments$name)]]
  if (!(feature %||% "default") %in% features) {
    return(NULL)
  }
  cli::cli_alert_info(
    "Installing the {.val {environment}} environment, as Pixi doesn't by itself in a project with several environments."
  )
  run_pixi(
    c("install", "--environment", environment),
    path = path,
    echo = TRUE
  )
}

# Install an environment, saying so the first time, when it takes a while.
# Pixi only shows progress bars in a terminal, so show what it prints.
install_environment <- function(environment, root) {
  args <- c("install", "--environment", environment)
  if (dir.exists(file.path(root, ".pixi", "envs", environment, "conda-meta"))) {
    return(run_pixi(args, path = root))
  }
  cli::cli_alert_info(
    "Installing the {.val {environment}} environment (first time only){cli::symbol$ellipsis}"
  )
  run_pixi(args, path = root, echo = TRUE, announce = FALSE)
}
