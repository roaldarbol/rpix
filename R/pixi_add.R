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
#'   bioconda channel, which is added to the project if needed). Without the
#'   prefix, a package that isn't on conda-forge is looked for on bioconda
#'   too, so `"DESeq2"` works as well.
#' * `"conda::gdal"`: a conda package that isn't an R package, used as is.
#'   Names containing `-` or `_`, such as `"c-compiler"`, are also used as is.
#' * `"cran::dplyr"`: same as `"dplyr"`.
#' * `"github::user/repo"` (experimental): an R package on GitHub, which Pixi
#'   builds from source with its R build backend, `pixi-build-r`. Add `@ref` for a branch,
#'   tag or commit, as in `"github::cran/praise@1.0.0"`; `pixi.lock` records
#'   the exact commit either way. rpix writes it into `pixi.toml`, turns on
#'   Pixi's `pixi-build` preview, and pins the build to the project's R. Its
#'   dependencies come from conda-forge. See
#'   <https://pixi.prefix.dev/latest/build/backends/pixi-build-r/>. This may
#'   change, e.g. to use `pixi add` once it can set a build backend; see
#'   <https://github.com/roaldarbol/rpix/issues/96>.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/add/>.
#'
#' @param packages Package names. A version constraint can follow the name, as
#'   in `"dplyr>=1.1"`.
#' @param versions Optional. Version constraints, either one for all packages
#'   or one per package (use `NA` for no constraint). A version without an
#'   operator, such as `"1.1"`, means `1.1.*`. For a package from GitHub, it's
#'   a branch, tag or commit instead, as with `@ref`.
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
  caller <- environment()
  if (!is.null(versions)) {
    if (!length(versions) %in% c(1, length(packages))) {
      cli::cli_abort(
        "{.arg versions} must have length 1 or the same length as {.arg packages}."
      )
    }
    versions <- rep_len(versions, length(packages))
  }
  on_github <- is_github(packages)
  github <- with_github_refs(packages[on_github], versions[on_github])
  packages <- packages[!on_github]
  versions <- versions[!on_github]
  if (all(is.na(versions))) {
    versions <- NULL
  }
  if (length(github) > 0 && !is.null(channel)) {
    cli::cli_abort(
      "{.arg channel} doesn't apply to packages from GitHub."
    )
  }
  if (length(packages) == 0) {
    return(invisible(add_github_packages(
      github,
      feature = feature,
      platform = platform,
      path = path,
      dry_run = dry_run
    )))
  }
  parsed <- parse_packages(packages)

  if (!is.null(versions)) {
    if (any(nzchar(parsed$constraint))) {
      cli::cli_abort(
        "Give version constraints either in {.arg packages} or in {.arg versions}, not both."
      )
    }
    parsed$constraint <- normalise_versions(versions)
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
        missing <- if (is.null(channel) || identical(channel, "bioconda")) {
          missing_from_conda_forge(parsed)
        }
        if (length(missing) > 0) {
          # Bioconductor packages are on bioconda, as bioconductor-<name>
          bioc <- missing[on_bioconda(parsed, missing)]
          if (length(bioc) > 0) {
            names <- package_r_names(parsed)[bioc]
            cli::cli_alert_info(
              "{.pkg {names}} {?isn't/aren't} on conda-forge, but {?it's a/they're} Bioconductor package{?s}, so rpix adds {?it/them} from bioconda."
            )
            specs <- package_references(parsed)
            specs[bioc] <- paste0("bioc::", names, parsed$constraint[bioc])
            return(structure(
              list(packages = c(specs, github)),
              class = "rpix_retry"
            ))
          }
          retry <- offer_cran_source(parsed, missing, call = caller)
          return(structure(
            list(packages = c(retry, github)),
            class = "rpix_retry"
          ))
        }
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

  if (inherits(result, "rpix_retry")) {
    return(pixi_add(
      result$packages,
      feature = feature,
      platform = platform,
      path = path
    ))
  }
  if (length(github) > 0) {
    add_github_packages(
      github,
      feature = feature,
      platform = platform,
      path = path,
      dry_run = dry_run
    )
  }
  if (isTRUE(dry_run)) {
    return(invisible(c(commands, result)))
  }
  invisible(result)
}

# The --feature and --platform arguments of pixi add and pixi remove
# When Pixi can't add a package because it isn't built for the project's R,
# the package and the newest R it's built for. NULL for other errors.
not_built_for_r <- function(stderr) {
  text <- plain_pixi_output(stderr)
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

# Which of the rows are Bioconductor packages on bioconda
on_bioconda <- function(parsed, rows) {
  names <- paste0("bioconductor-", tolower(package_r_names(parsed)[rows]))
  vapply(names, on_channel, logical(1), "bioconda", USE.NAMES = FALSE)
}

# The CRAN packages that aren't on conda-forge, by row
missing_from_conda_forge <- function(parsed) {
  cran <- which(parsed$source == "cran")
  cran[!vapply(parsed$name[cran], on_channel, logical(1), "conda-forge")]
}

# Offer to build CRAN packages that aren't on conda-forge from CRAN's GitHub
# mirror, which has a tag for every version. Returns the packages to add
# instead, or fails.
offer_cran_source <- function(parsed, missing, call = parent.frame()) {
  specs <- package_references(parsed)
  names <- package_r_names(parsed)[missing]
  constraints <- parsed$constraint[missing]
  exact <- grepl("^==", constraints)
  # A version tag uses R's spelling, 1.2-3 rather than conda's 1.2_3
  refs <- ifelse(
    exact,
    paste0("@", gsub("_", "-", sub("^==", "", constraints), fixed = TRUE)),
    ""
  )
  github <- paste0("github::cran/", names, refs)

  dropped <- nzchar(constraints) & !exact
  if (is_interactive()) {
    n <- length(names)
    urls <- paste0("https://github.com/cran/", names)
    cli::cli_alert_warning("{.pkg {names}} {?isn't/aren't} on conda-forge.")
    cli::cli_alert_info(
      "Pixi can build {cli::qty(n)}{?it/them} from CRAN's source, at {.url {urls}}, with {cli::qty(n)}{?its/their} dependencies from conda-forge."
    )
    if (any(dropped)) {
      cli::cli_alert_info(
        "A version range doesn't apply to a build from source, so {.pkg {names[dropped]}} would be the latest version. Use {.code ==} for a particular one."
      )
    }
    question <- cli::format_inline(
      "Would you like to build {cli::qty(n)}{?it/them} from source?"
    )
    if (isTRUE(ask_yes_no(question))) {
      return(c(specs[-missing], github))
    }
  }
  # In an interactive session, it's already been said they aren't there
  header <- if (is_interactive()) {
    "Didn't add {.pkg {names}}."
  } else {
    "{.pkg {names}} {?isn't/aren't} on conda-forge."
  }
  cli::cli_abort(
    c(
      header,
      "i" = "Pixi can build {cli::qty(length(names))}{?it/them} from CRAN's source: {.code pixi_add({deparse(github)})}."
    ),
    class = "rpix_error_package_not_found",
    call = call
  )
}

# The packages as references pixi_add() takes, e.g. "cran::dplyr>=1.1"
package_references <- function(parsed) {
  names <- package_r_names(parsed)
  names[parsed$source == "conda"] <- parsed$name[parsed$source == "conda"]
  paste0(parsed$source, "::", names, parsed$constraint)
}

package_r_names <- function(parsed) {
  base <- sub("^[A-Za-z]+::", "", parsed$input)
  sub("[[:space:]=<>!~].*$", "", base)
}
