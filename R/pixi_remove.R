#' Remove packages
#'
#' @description
#' Remove packages from the Pixi manifest. Package names are translated like in
#' [pixi_add()]: `"dplyr"` removes `r-dplyr` and `"bioc::DESeq2"` removes
#' `bioconductor-deseq2`.
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/remove/>.
#'
#' @param packages Package names.
#' @param dry_run If `TRUE`, show the Pixi command without running it.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_remove("tibble")
#' }
pixi_remove <- function(packages, dry_run = FALSE) {
  parsed <- parse_packages(packages)
  if (any(nzchar(parsed$constraint))) {
    cli::cli_abort(
      "{.fn pixi_remove} takes package names without version constraints."
    )
  }
  run_pixi(c("remove", parsed$name), echo = TRUE, dry_run = dry_run)
}
