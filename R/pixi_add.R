#' Add packages
#'
#' @description
#' Add packages to the Pixi manifest and install them. Pixi only adds them if
#' they can be solved together with the rest of the project's dependencies.
#'
#' R package names are translated to conda names: `"dplyr"` becomes `r-dplyr`
#' and `"Rcpp"` becomes `r-rcpp` (conda names are lowercase). Use a prefix to
#' say where a package comes from:
#'
#' * `"bioc::DESeq2"`: a Bioconductor package (`bioconductor-deseq2` from the
#'   bioconda channel, which is added to the project if needed).
#' * `"conda::gdal"`: a conda package that isn't an R package, used as is.
#'   Names containing `-` or `_`, such as `"c-compiler"`, are also used as is.
#' * `"cran::dplyr"`: same as `"dplyr"`.
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/add/>.
#'
#' @param packages Package names. A version constraint can follow the name, as
#'   in `"dplyr>=1.1"`.
#' @param versions Optional. Version constraints, either one for all packages
#'   or one per package (use `NA` for no constraint). A version without an
#'   operator, such as `"1.1"`, means `1.1.*`.
#' @param channel Optional. A conda channel to install the packages from. It's
#'   added to the project's channels if it isn't there yet.
#' @param dry_run If `TRUE`, show the Pixi commands without running them.
#' @returns The commands (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @import cli
#' @export
#' @examples
#' \dontrun{
#' pixi_add("tibble")
#' pixi_add(c("dplyr>=1.1", "bioc::DESeq2", "conda::gdal"))
#' pixi_add("dplyr", versions = "1.1")
#' }
pixi_add <- function(
  packages,
  versions = NULL,
  channel = NULL,
  dry_run = FALSE
) {
  parsed <- parse_packages(packages)

  if (!is.null(versions)) {
    if (!length(versions) %in% c(1, nrow(parsed))) {
      cli::cli_abort(
        "{.arg versions} must have length 1 or the same length as {.arg packages}."
      )
    }
    if (any(nzchar(parsed$constraint))) {
      cli::cli_abort(
        "Give version constraints either in {.arg packages} or in {.arg versions}, not both."
      )
    }
    parsed$constraint <- normalise_versions(rep_len(versions, nrow(parsed)))
  }

  if (!is.null(channel)) {
    parsed$channel <- channel
  }

  # pixi only installs from channels listed in the project
  commands <- NULL
  channels <- unique(stats::na.omit(parsed$channel))
  if (length(channels) > 0) {
    missing <- if (isTRUE(dry_run)) {
      channels
    } else {
      setdiff(channels, project_channels())
    }
    if (length(missing) > 0) {
      commands <- run_pixi(
        c("workspace", "channel", "add", missing, "--no-install"),
        echo = TRUE,
        dry_run = dry_run
      )
    }
  }

  result <- tryCatch(
    run_pixi(c("add", package_specs(parsed)), echo = TRUE, dry_run = dry_run),
    rpix_error_pixi = function(e) {
      if (grepl("No candidates were found", e$stderr, fixed = TRUE)) {
        cli::cli_abort(
          c(
            "Some packages couldn't be found.",
            "i" = "Check the names with {.fn pixi_search}.",
            "i" = "Use {.code bioc::} for Bioconductor packages, and {.code conda::} for conda packages that aren't R packages."
          ),
          class = "rpix_error_package_not_found",
          parent = e
        )
      }
      stop(e)
    }
  )

  if (isTRUE(dry_run)) {
    return(invisible(c(commands, result)))
  }
  invisible(result)
}

# Channels of the project's default environment
project_channels <- function() {
  info <- run_pixi("info", json = TRUE)
  envs <- info$environments_info
  channels <- envs$channels[[which(envs$name == "default")]]
  # Channels can be listed as URLs, so compare on names as well
  unique(c(channels, basename(sub("/+$", "", channels))))
}
