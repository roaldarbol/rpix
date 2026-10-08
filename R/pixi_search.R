#' Search for packages
#'
#' @description
#' Show the available versions of a conda package and their dependencies.
#'
#' The package name is translated like in [pixi_add()]: `"dplyr"` searches for
#' `r-dplyr`, `"bioc::DESeq2"` for `bioconductor-deseq2` on bioconda, and
#' `"conda::gdal"` for `gdal`.
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/search/>.
#'
#' @param package A package name.
#' @param channel Optional. A conda channel to search. Inside a project, the
#'   project's channels are searched by default, and conda-forge otherwise.
#' @inheritParams pixi_add
#' @param dry_run If `TRUE`, show the Pixi command without running it.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_search("tibble")
#' pixi_search("bioc::DESeq2")
#' pixi_search("conda::numpy", channel = "conda-forge")
#' }
pixi_search <- function(
  package,
  channel = NULL,
  path = NULL,
  dry_run = FALSE
) {
  if (length(package) != 1) {
    cli::cli_abort(
      "{.fn pixi_search} takes a single package name, not {length(package)}."
    )
  }

  parsed <- parse_packages(package)
  channel <- channel %||% stats::na.omit(parsed$channel)

  args <- c("search", parsed$name)
  if (length(channel) > 0) {
    args <- c(args, "--channel", channel)
  }

  run_pixi(
    args,
    project = "optional",
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}
