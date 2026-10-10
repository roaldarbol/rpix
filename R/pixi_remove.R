#' Remove packages
#'
#' @description
#' Remove packages from the Pixi manifest. Package names are translated like in
#' [pixi_add()]: `"dplyr"` removes `r-dplyr` and `"bioc::DESeq2"` removes
#' `bioconductor-deseq2`.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/remove/>.
#'
#' @param packages Package names.
#' @inheritParams pixi_add
#' @param dry_run If `TRUE`, show the Pixi command without running it.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_remove("tibble")
#' }
pixi_remove <- function(
  packages,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE
) {
  github <- packages[is_github(packages)]
  names <- vapply(github, function(p) parse_github(p)$name, character(1))
  others <- packages[!is_github(packages)]
  parsed <- if (length(others) > 0) {
    parse_packages(others)
  } else {
    data.frame(name = character(), constraint = character())
  }
  if (any(nzchar(parsed$constraint))) {
    cli::cli_abort(
      "{.fn pixi_remove} takes package names without version constraints."
    )
  }
  run_pixi(
    c("remove", parsed$name, unname(names), scope_args(feature, platform)),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}
