#' Remove dependencies
#'
#' @description
#' `remove()` removes packages from the pixi manifest. Package names are
#' translated like in [add()], so `"dplyr"` removes `r-dplyr` and
#' `"bioc::DESeq2"` removes `bioconductor-deseq2`.
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/remove/>.
#'
#' @param packages Package names.
#' @param dry_run If `TRUE`, show the pixi command without running it.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the pixi call (invisibly).
#' @import cli
#' @export remove
#' @examples
#' \dontrun{
#' remove("tibble")
#' }
remove <- function(packages, dry_run = FALSE) {
  parsed <- parse_packages(packages)
  if (any(nzchar(parsed$constraint))) {
    cli::cli_abort(
      "{.fn remove} takes package names without version constraints."
    )
  }
  run_pixi(c("remove", parsed$name), echo = TRUE, dry_run = dry_run)
}
