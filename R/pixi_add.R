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
#' @param feature Optional. The feature to add the packages to, rather than
#'   the default one. See [pixi_add_environment()].
#' @param platform Optional. Only add the packages for this platform, such as
#'   `"linux-64"`.
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
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
  feature = NULL,
  platform = NULL,
  path = NULL,
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
      setdiff(channels, project_channels(path))
    }
    if (length(missing) > 0) {
      commands <- run_pixi(
        c("workspace", "channel", "add", missing, "--no-install"),
        path = path,
        echo = TRUE,
        dry_run = dry_run
      )
    }
  }

  result <- tryCatch(
    run_pixi(
      c("add", package_specs(parsed), scope_args(feature, platform)),
      path = path,
      echo = TRUE,
      dry_run = dry_run
    ),
    rpix_error_pixi = function(e) {
      unbuilt <- not_built_for_r(e$stderr)
      if (!is.null(unbuilt)) {
        suggestion <- deparse(c(paste0("r-base=", unbuilt$r_version), packages))
        cli::cli_abort(
          c(
            "{.pkg {unbuilt$package}} isn't built for the project's version of R yet.",
            "i" = "conda-forge builds packages for a new version of R some time after it's out.",
            "i" = "Use R {unbuilt$r_version}, the newest it's built for: {.code pixi_add({suggestion})}."
          ),
          class = "rpix_error_r_version",
          parent = e
        )
      }
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

# The --feature and --platform arguments of pixi add and pixi remove
# When Pixi can't add a package because it isn't built for the project's R,
# the package and the newest R it's built for. NULL for other errors.
not_built_for_r <- function(stderr) {
  # Without colours, the tree's box-drawing characters and line breaks. Bytes
  # rather than characters, so it works in any locale.
  text <- gsub("\033\\[[0-9;]*m", "", stderr, useBytes = TRUE)
  text <- gsub("[^ -~]+", " ", text, useBytes = TRUE)
  text <- gsub("[[:space:]]+", " ", text, useBytes = TRUE)
  versions <- regmatches(
    text,
    gregexpr(
      "(?<=would require r-base >=)[0-9]+\\.[0-9]+(?=,)",
      text,
      perl = TRUE
    )
  )[[1]]
  if (length(versions) == 0) {
    return(NULL)
  }
  package <- regmatches(
    text,
    regexpr("[A-Za-z0-9._-]+(?= \\* cannot be installed)", text, perl = TRUE)
  )
  newest <- as.character(max(package_version(versions)))
  list(package = package, r_version = newest)
}

scope_args <- function(feature = NULL, platform = NULL) {
  c(
    if (!is.null(feature)) c("--feature", feature),
    if (!is.null(platform)) c("--platform", platform)
  )
}

# Channels of the project's default environment
project_channels <- function(path = NULL) {
  info <- run_pixi("info", path = path, json = TRUE)
  envs <- info$environments_info
  channels <- envs$channels[[which(envs$name == "default")]]
  # Channels can be listed as URLs, so compare on names as well
  unique(c(channels, basename(sub("/+$", "", channels))))
}
