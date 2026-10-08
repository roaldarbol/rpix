#' Deprecated functions
#'
#' @description
#' * `add()` is now [pixi_add()].
#' * `setup_pixi()` is now [use_pixi()].
#'
#' `remove()` and `search()` were removed rather than deprecated, because they
#' masked the base R functions of the same name. Use [pixi_remove()] and
#' [pixi_search()].
#'
#' @inheritParams pixi_add
#' @inheritParams use_pixi
#' @keywords internal
#' @name rpix-deprecated
NULL

#' @rdname rpix-deprecated
#' @export
add <- function(packages, versions = NULL, channel = NULL, dry_run = FALSE) {
  lifecycle::deprecate_soft("0.4.0", "add()", "pixi_add()")
  pixi_add(
    packages = packages,
    versions = versions,
    channel = channel,
    dry_run = dry_run
  )
}

#' @rdname rpix-deprecated
#' @export
setup_pixi <- function(
  r_version = NULL,
  init_if_missing = TRUE,
  install_rpix = TRUE
) {
  lifecycle::deprecate_soft("0.5.0", "setup_pixi()", "use_pixi()")
  use_pixi(
    r_version = r_version,
    init_if_missing = init_if_missing,
    install_rpix = install_rpix
  )
}
