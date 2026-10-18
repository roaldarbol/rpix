#' Search for packages
#'
#' @description
#' Show the available versions of a conda package and their dependencies.
#'
#' The package name is translated like in [pixi_add()]: `"dplyr"` searches for
#' `r-dplyr`, `"bioc::DESeq2"` for `bioconductor-deseq2` on bioconda, and
#' `"conda::gdal"` for `gdal`. A package that isn't on conda-forge is looked
#' for on bioconda too, so `"DESeq2"` works as well. An R package's name has to
#' match exactly, while Pixi also finds conda packages whose names contain the
#' one searched for.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/search/>.
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
  # As in pixi_add(), a package that isn't on conda-forge may be a
  # Bioconductor package, on bioconda
  if (
    is.null(channel) &&
      !isTRUE(dry_run) &&
      length(missing_from_conda_forge(parsed)) > 0 &&
      on_bioconda(parsed, 1)
  ) {
    name <- package_r_names(parsed)
    cli::cli_alert_info(
      "{.pkg {name}} isn't on conda-forge, but it's a Bioconductor package, so rpix searches bioconda."
    )
    parsed <- parse_packages(paste0("bioc::", name))
  }
  channel <- channel %||% stats::na.omit(parsed$channel)

  args <- c("search", parsed$name)
  if (length(channel) > 0) {
    args <- c(args, "--channel", channel)
  }

  # Pixi shows a package whose name contains the one searched for when there's
  # none by that name, e.g. r-fauxpas for r-faux, but an R package's name is
  # exact
  if (!isTRUE(dry_run) && parsed$source != "conda") {
    found <- search_names(args, project = "optional", path = path)
    if (!parsed$name %in% found) {
      similar <- utils::head(found, 5)
      cli::cli_abort(
        c(
          "There's no package {.pkg {parsed$name}}.",
          "i" = if (length(similar) > 0) {
            "Packages with similar names: {.pkg {similar}}."
          }
        ),
        class = "rpix_error_package_not_found"
      )
    }
  }

  run_pixi(
    args,
    project = "optional",
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}
