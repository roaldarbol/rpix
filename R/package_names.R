#' Translate package references to conda package specs
#'
#' @description
#' R users refer to packages by their R names. This turns those references
#' into conda names, using a pak-like syntax for where a package comes from:
#'
#' | Reference | Conda package | Channel |
#' |---|---|---|
#' | `"dplyr"`, `"cran::dplyr"` | `r-dplyr` | |
#' | `"Rcpp"` | `r-rcpp` (conda names are lowercase) | |
#' | `"bioc::DESeq2"` | `bioconductor-deseq2` | `bioconda` |
#' | `"conda::gdal"` | `gdal` | |
#' | `"r-dplyr"`, `"c-compiler"` | unchanged (R names can't contain `-` or `_`) | |
#'
#' A version constraint can follow the name, e.g. `"dplyr>=1.1"`.
#'
#' @param packages Character vector of package references.
#' @param call The calling environment, used in error messages.
#' @returns A data frame with one row per package and the columns `input`,
#'   `source` (`"cran"`, `"bioc"` or `"conda"`), `name` (the conda package
#'   name), `constraint` (`""` if none) and `channel` (`NA` if none).
#' @noRd
parse_packages <- function(packages, call = parent.frame()) {
  if (!is.character(packages) || length(packages) == 0 || anyNA(packages)) {
    cli::cli_abort(
      "{.arg packages} must be a character vector of package names.",
      call = call
    )
  }

  rows <- lapply(trimws(packages), parse_package, call = call)
  do.call(rbind, rows)
}

parse_package <- function(input, call) {
  source <- NA_character_
  ref <- input

  prefix <- regmatches(ref, regexpr("^[A-Za-z]+::", ref))
  if (length(prefix) == 1) {
    source <- tolower(sub("::$", "", prefix))
    ref <- substring(ref, nchar(prefix) + 1)
    if (!source %in% c("cran", "bioc", "conda")) {
      cli::cli_abort(
        c(
          "Unknown source {.val {source}} in {.val {input}}.",
          "i" = "Use {.code cran::}, {.code bioc::}, {.code conda::} or {.code github::}, or the {.arg channel} argument for other conda channels."
        ),
        call = call
      )
    }
  }

  # Split off a version constraint, e.g. "dplyr>=1.1" or "dplyr 1.1.*"
  name <- sub("[[:space:]=<>!~].*$", "", ref)
  constraint <- trimws(substring(ref, nchar(name) + 1))

  if (is.na(source)) {
    # R package names only contain letters, numbers and dots, so anything with
    # `-` or `_` must already be a conda name
    source <- if (grepl("[-_]", name)) "conda" else "cran"
  }

  if (source %in% c("cran", "bioc") && !is_r_package_name(name)) {
    cli::cli_abort(
      c(
        "{.val {name}} isn't a valid R package name.",
        "i" = "For a conda package that isn't an R package, use {.code conda::{name}}."
      ),
      call = call
    )
  }

  conda_name <- switch(
    source,
    cran = paste0("r-", tolower(name)),
    bioc = paste0("bioconductor-", tolower(name)),
    conda = name
  )

  data.frame(
    input = input,
    source = source,
    name = conda_name,
    constraint = constraint,
    channel = if (source == "bioc") "bioconda" else NA_character_,
    stringsAsFactors = FALSE
  )
}

is_r_package_name <- function(x) {
  grepl("^[A-Za-z][A-Za-z0-9.]*[A-Za-z0-9]$", x)
}

#' Normalise version constraints
#'
#' Adds `=` to versions without an operator (`"1.1"` becomes `"=1.1"`, which
#' conda reads as `1.1.*`). `NA` and `""` mean no constraint.
#' @noRd
normalise_versions <- function(versions) {
  versions[is.na(versions)] <- ""
  versions <- trimws(versions)
  has_version <- nzchar(versions)
  versions[has_version] <- sub(
    "^(?![=<>~!])",
    "=",
    versions[has_version],
    perl = TRUE
  )
  versions
}

#' Build conda MatchSpecs from parsed packages
#'
#' Channel-specific packages are written as `channel::name`, which Pixi
#' requires for packages from a channel other than the default ones.
#' @noRd
package_specs <- function(parsed) {
  specs <- paste0(parsed$name, parsed$constraint)
  has_channel <- !is.na(parsed$channel)
  specs[has_channel] <- paste0(
    parsed$channel[has_channel],
    "::",
    specs[has_channel]
  )
  specs
}
