#' Add a package's dependencies from its DESCRIPTION
#'
#' @description
#' For package developers: add what the package in the project needs to the
#' project, from its `DESCRIPTION`.
#'
#' * `Depends` and `Imports` (and `LinkingTo`) go into the default feature,
#'   with their version constraints.
#' * `Suggests` go into a `test` feature, with a `test` environment of the
#'   default and `test` features. It's in the same solve group as the default
#'   environment, so it tests the same versions.
#' * `Depends: R (>= 4.1)` becomes a constraint on R, if the project doesn't
#'   have R yet.
#'
#' Each package is looked up on conda-forge, as `r-<name>`, and then on
#' bioconda, as `bioconductor-<name>`. Packages that are on neither are left
#' out, and listed.
#'
#' @param test If `TRUE`, add the `Suggests` to a `test` feature and
#'   environment. If `FALSE`, leave them out.
#' @inheritParams pixi_environments
#' @returns A list with the package specs added to the default feature
#'   (`packages`) and to the `test` feature (`test`), and the packages that
#'   weren't found (`missing`), invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_import_description()
#' }
pixi_import_description <- function(test = TRUE, path = NULL, dry_run = FALSE) {
  root <- require_project(path)
  deps <- description_dependencies(file.path(root, "DESCRIPTION"))
  r <- deps[deps$package == "R", ]
  deps <- deps[!deps$package %in% c("R", base_packages()), ]
  needed <- deps[deps$field != "Suggests", ]
  needed <- needed[!duplicated(needed$package), ]
  suggested <- deps[
    deps$field == "Suggests" & !deps$package %in% needed$package,
  ]
  if (!test) {
    suggested <- suggested[0, ]
  }

  found <- find_r_packages(c(needed$package, suggested$package))
  specs <- function(rows) {
    rows <- rows[!is.na(found[rows$package]), ]
    if (nrow(rows) == 0) {
      return(character())
    }
    paste0(found[rows$package], rows$constraint)
  }
  packages <- specs(needed)
  test_packages <- specs(suggested)

  # R goes in with the packages, so Pixi picks an R they're all built for
  if (!"r-base" %in% project_dependencies(root)) {
    r_constraint <- if (nrow(r) > 0) r$constraint[1] else ""
    packages <- c(paste0("r-base", r_constraint), packages)
  }
  if (length(packages) > 0) {
    pixi_add(packages, path = root, dry_run = dry_run)
  }
  if (length(test_packages) > 0) {
    pixi_add(test_packages, feature = "test", path = root, dry_run = dry_run)
    pixi_add_environment(
      "test",
      features = "test",
      solve_group = "default",
      overwrite = TRUE,
      path = root,
      dry_run = dry_run
    )
  }

  missing <- names(found)[is.na(found)]
  if (length(missing) > 0) {
    cli::cli_alert_warning(
      "Not on conda-forge or bioconda, so not added: {.pkg {missing}}."
    )
  }
  invisible(list(packages = packages, test = test_packages, missing = missing))
}

# A package's dependencies from its DESCRIPTION: a data frame with the field,
# the package, and its version constraint as conda writes it
description_dependencies <- function(description) {
  if (!file.exists(description)) {
    cli::cli_abort("There's no package here: {.file {description}} is missing.")
  }
  fields <- c("Depends", "Imports", "LinkingTo", "Suggests")
  values <- read.dcf(description, fields = fields)[1, ]
  rows <- lapply(fields, function(field) {
    if (is.na(values[[field]])) {
      return(NULL)
    }
    entries <- trimws(strsplit(values[[field]], ",")[[1]])
    entries <- entries[nzchar(entries)]
    package <- sub("[[:space:]]*\\(.*$", "", entries)
    version <- ifelse(
      grepl("\\(", entries),
      gsub("[[:space:]()]", "", sub("^[^(]*", "", entries)),
      ""
    )
    data.frame(
      field = rep(field, length(entries)),
      package = package,
      # conda versions use _ where R versions use -, e.g. 1.1_2 for 1.1-2
      constraint = gsub("-", "_", version, fixed = TRUE),
      stringsAsFactors = FALSE
    )
  })
  rows <- do.call(rbind, rows)
  if (is.null(rows)) {
    rows <- data.frame(
      field = character(),
      package = character(),
      constraint = character()
    )
  }
  rows
}

# The packages a package needs, without R and the packages that come with it
package_dependencies <- function(description) {
  packages <- description_dependencies(description)$package
  unique(setdiff(packages, c("R", base_packages())))
}

base_packages <- function() {
  rownames(utils::installed.packages(priority = "base"))
}

# Look R packages up on conda-forge and bioconda. Returns a reference for each,
# such as "cran::dplyr" or "bioc::DESeq2", or NA if it's on neither.
find_r_packages <- function(packages) {
  packages <- unique(packages)
  if (length(packages) == 0) {
    return(stats::setNames(character(), character()))
  }
  cli::cli_progress_step(
    "Looking up {length(packages)} package{?s} on conda-forge and bioconda."
  )
  found <- vapply(
    packages,
    function(package) {
      if (on_channel(paste0("r-", tolower(package)), "conda-forge")) {
        paste0("cran::", package)
      } else if (
        on_channel(paste0("bioconductor-", tolower(package)), "bioconda")
      ) {
        paste0("bioc::", package)
      } else {
        NA_character_
      }
    },
    character(1)
  )
  cli::cli_progress_done()
  found
}

on_channel <- function(name, channel) {
  channels <- unique(c("conda-forge", channel))
  tryCatch(
    {
      run_pixi(
        c("search", as.vector(rbind("--channel", channels)), name),
        project = "none"
      )
      TRUE
    },
    rpix_error_pixi = function(e) FALSE
  )
}

# The packages in the default feature
project_dependencies <- function(root) {
  envs <- pixi_info(root)$environments_info
  unlist(envs$dependencies[envs$name == "default"])
}
