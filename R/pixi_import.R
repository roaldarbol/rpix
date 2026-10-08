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
  missing <- names(found)[is.na(found)]
  added <- add_imported(
    specs(needed),
    specs(suggested),
    r_constraint = if (nrow(r) > 0) r$constraint[1] else "",
    root = root,
    dry_run = dry_run
  )
  if (length(missing) > 0) {
    cli::cli_alert_warning(
      "Not on conda-forge or bioconda, so not added: {.pkg {missing}}."
    )
  }
  invisible(c(added, list(missing = missing)))
}

# Add imported packages, R, and test packages with a test environment
add_imported <- function(
  packages,
  test_packages = character(),
  r_constraint,
  root,
  dry_run
) {
  # R goes in with the packages, so Pixi picks an R they're all built for. A
  # project that has R already keeps its version.
  if (!"r-base" %in% project_dependencies(root)) {
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
  list(packages = packages, test = test_packages)
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

#' Move a project from renv
#'
#' @description
#' Add the packages in a project's `renv.lock` to its Pixi project, and turn
#' renv off.
#'
#' * Packages from CRAN, or another CRAN-like repository, are looked up on
#'   conda-forge, and Bioconductor packages on bioconda. Packages from GitHub
#'   or elsewhere, and packages that aren't on conda-forge or bioconda, are
#'   left out, and listed.
#' * By default only the packages that no other package in the lock file
#'   needs are added, so `pixi.toml` lists what the project uses, rather than
#'   everything those packages need too.
#' * The lock file's version of R becomes a constraint on R, if the project
#'   doesn't have R yet.
#'
#' renv's `.Rprofile` line, `source("renv/activate.R")`, makes R use renv's
#' library, so `deactivate = TRUE` removes it, like `renv::deactivate()`.
#' `renv.lock` and the `renv` folder stay; delete them when you no longer need
#' them.
#'
#' @param lockfile Optional. The lock file. Defaults to the project's
#'   `renv.lock`.
#' @param versions How to use the lock file's versions:
#'   * `"minimum"`: at least that version, e.g. `>=1.1.4`.
#'   * `"exact"`: that version, e.g. `==1.1.4`, if it's on conda-forge, and
#'     at least that version if it isn't.
#'   * `"none"`: the newest versions.
#' @param all If `TRUE`, add every package in the lock file, including those
#'   that are only there because other packages need them.
#' @param deactivate If `TRUE`, remove renv's line from the project's
#'   `.Rprofile`.
#' @inheritParams pixi_environments
#' @returns A list with the package specs added (`packages`), and the packages
#'   left out because they aren't from a repository (`not_from_repository`)
#'   or weren't found (`missing`), invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_import_renv()
#' pixi_import_renv(versions = "exact")
#' }
pixi_import_renv <- function(
  lockfile = NULL,
  versions = c("minimum", "exact", "none"),
  all = FALSE,
  deactivate = TRUE,
  path = NULL,
  dry_run = FALSE
) {
  versions <- match.arg(versions)
  root <- require_project(path)
  lockfile <- lockfile %||% file.path(root, "renv.lock")
  if (!file.exists(lockfile)) {
    cli::cli_abort("There's no renv lock file at {.file {lockfile}}.")
  }
  lock <- jsonlite::read_json(lockfile)

  entries <- lock$Packages
  entries <- entries[!names(entries) %in% c("renv", base_packages())]
  if (!all) {
    needed <- unlist(lapply(entries, function(entry) entry$Requirements))
    entries <- entries[!names(entries) %in% needed]
  }

  source <- vapply(entries, function(e) e$Source %||% NA_character_, "")
  from_repository <- source %in% c("Repository", "Bioconductor")
  other <- names(entries)[!from_repository]
  entries <- entries[from_repository]

  found <- find_r_packages(names(entries))
  missing <- names(found)[is.na(found)]
  entries <- entries[!is.na(found[names(entries)])]
  specs <- vapply(
    names(entries),
    function(package) {
      lock_spec(found[[package]], entries[[package]]$Version, versions)
    },
    character(1)
  )

  r_version <- lock$R$Version
  r_constraint <- if (is.null(r_version) || versions == "none") {
    ""
  } else {
    minor <- sub("^([0-9]+\\.[0-9]+).*$", "\\1", r_version)
    if (versions == "exact") paste0("=", minor) else paste0(">=", minor)
  }
  added <- add_imported(
    unname(specs),
    r_constraint = r_constraint,
    root = root,
    dry_run = dry_run
  )

  if (length(other) > 0) {
    cli::cli_alert_warning(
      "Not from CRAN or Bioconductor, so not added: {.pkg {other}}."
    )
  }
  if (length(missing) > 0) {
    cli::cli_alert_warning(
      "Not on conda-forge or bioconda, so not added: {.pkg {missing}}."
    )
  }
  if (deactivate) {
    remove_renv_activation(file.path(root, ".Rprofile"), dry_run)
  }
  invisible(list(
    packages = added$packages,
    not_from_repository = other,
    missing = missing
  ))
}

# A package spec with the lock file's version, as `versions` says
lock_spec <- function(reference, version, versions) {
  if (versions == "none" || is.null(version)) {
    return(reference)
  }
  # conda versions use _ where R versions use -
  version <- gsub("-", "_", version, fixed = TRUE)
  if (versions == "exact") {
    parsed <- parse_packages(reference)
    channel <- parsed$channel %|NA|% "conda-forge"
    if (on_channel(paste0(parsed$name, "==", version), channel)) {
      return(paste0(reference, "==", version))
    }
  }
  paste0(reference, ">=", version)
}

remove_renv_activation <- function(file, dry_run = FALSE) {
  if (!file.exists(file)) {
    return(invisible(FALSE))
  }
  lines <- readLines(file, warn = FALSE)
  renv <- grepl("source(\"renv/activate.R\")", lines, fixed = TRUE)
  if (!any(renv)) {
    return(invisible(FALSE))
  }
  if (dry_run) {
    cli::cli_alert_info(
      "Would remove {.code source(\"renv/activate.R\")} from {.file .Rprofile}."
    )
    return(invisible(FALSE))
  }
  writeLines(lines[!renv], file)
  cli::cli_alert_success(
    "Turned renv off: removed {.code source(\"renv/activate.R\")} from {.file .Rprofile}."
  )
  cli::cli_alert_info(
    "Delete {.file renv.lock} and the {.file renv} folder when you no longer need them."
  )
  invisible(TRUE)
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
