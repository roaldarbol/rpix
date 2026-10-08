#' Remove dependencies

#' @description
#' `remove()` will remove dependencies from the pixi.toml.
#'
#' For more information, see https://pixi.sh/latest/reference/cli/pixi/remove/
#'
#' @param packages Package name(s) to be removed.
#' @param dry_run Just show command or also run.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the pixi call (invisibly).
#' @import cli
#' @export remove
#' @examples
#' \dontrun{
#' remove("tibble")
#' }

remove <- function(packages, dry_run = FALSE) {
  run_pixi(c("remove", paste0("r-", packages)), echo = TRUE, dry_run = dry_run)
}
