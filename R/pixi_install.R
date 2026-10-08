#' Install and update the project's packages
#'
#' @description
#' * `pixi_install()` installs an environment as `pixi.lock` describes it,
#'   e.g. after cloning a project. `pixi run` does this by itself, too.
#' * `pixi_update()` updates packages to the newest versions `pixi.toml`
#'   allows, in `pixi.lock`.
#' * `pixi_upgrade()` updates packages beyond that, and raises the versions in
#'   `pixi.toml` to match.
#' * `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
#'   installing anything.
#'
#' Package names are translated like in [pixi_add()].
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/install/>,
#' <https://pixi.sh/latest/reference/cli/pixi/update/>,
#' <https://pixi.sh/latest/reference/cli/pixi/upgrade/> and
#' <https://pixi.sh/latest/reference/cli/pixi/lock/>.
#'
#' @param environment Optional. The environment. Defaults to `default`.
#' @param all If `TRUE`, install all the project's environments.
#' @param packages Optional. Only update these packages. Defaults to all.
#' @param feature Optional. Only upgrade the packages of this feature.
#' @inheritParams pixi_environments
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_install()
#' pixi_update("dplyr")
#' pixi_upgrade()
#' }
pixi_install <- function(
  environment = NULL,
  all = FALSE,
  path = NULL,
  dry_run = FALSE
) {
  args <- c(
    "install",
    if (!is.null(environment)) c("--environment", environment),
    if (all) "--all"
  )
  run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
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
  run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
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
  run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
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
