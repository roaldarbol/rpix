#' Deprecated functions
#'
#' @description
#' * `add()` is now [pixi_add()].
#'
#' `remove()` and `search()` were removed rather than deprecated, because they
#' masked the base R functions of the same name. Use [pixi_remove()] and
#' [pixi_search()].
#'
#' @inheritParams pixi_add
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
