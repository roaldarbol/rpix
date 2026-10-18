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

# Add imported packages, R, and test packages with a test environment. With
# `newest_r`, R that's too new for the packages, as a lock file's can be,
# becomes the newest R they're built for.
add_imported <- function(
  packages,
  test_packages = character(),
  r_constraint,
  root,
  dry_run,
  newest_r = FALSE
) {
  # R goes in with the packages, so Pixi picks an R they're all built for. A
  # project that has R already keeps its version.
  adds_r <- !"r-base" %in% project_dependencies(root)
  if (adds_r) {
    packages <- c(paste0("r-base", r_constraint), packages)
  }
  if (length(packages) > 0) {
    packages <- tryCatch(
      {
        pixi_add(packages, path = root, dry_run = dry_run)
        packages
      },
      rpix_error_r_version = function(e) {
        # conda-forge has a new R before its packages are built for it
        unbuilt <- not_built_for_r(e$parent$stderr)
        r <- regmatches(r_constraint, regexpr("[0-9]+\\.[0-9]+", r_constraint))
        if (
          !newest_r ||
            !adds_r ||
            length(r) == 0 ||
            package_version(r) <= package_version(unbuilt$r_version)
        ) {
          stop(e)
        }
        cli::cli_alert_warning(
          "conda-forge doesn't have the packages for R {r}, the lock file's R, so rpix adds the newest R that has them."
        )
        packages[1] <- "r-base"
        pixi_add(packages, path = root, dry_run = dry_run)
        packages
      }
    )
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
#'   conda-forge, and Bioconductor packages on bioconda. CRAN packages that
#'   aren't on conda-forge can be built from CRAN's source instead
#'   (experimental): `pixi_import_renv()` offers to, or if it can't ask, lists
#'   them with the command that does. Other packages that aren't on
#'   conda-forge or bioconda are left out, and listed.
#' * Packages from GitHub (experimental) are built from source at the commit
#'   `renv.lock` records, as `pixi_add("github::user/repo@commit")` does. With
#'   `versions = "none"`, they're built from the newest commit of the branch it
#'   records. Packages in a subfolder of a repository, and packages from
#'   elsewhere, are left out, and listed.
#' * By default only the packages that no other package in the lock file
#'   needs are added, so `pixi.toml` lists what the project uses, rather than
#'   everything those packages need too. Packages from GitHub are added either
#'   way, as conda-forge doesn't have them.
#' * The lock file's version of R becomes a constraint on R, if the project
#'   doesn't have R yet. If conda-forge doesn't have the packages for that R,
#'   e.g. a new R it hasn't built packages for yet, it says so and uses the
#'   newest R that has them.
#'
#' It says which packages Pixi builds from source, as building them is
#' experimental; see [pixi_add()].
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
#' @returns A list, invisibly, with the package specs added (`packages`), the
#'   packages built from source (`from_source`), and the packages left out
#'   because rpix can't add them from where they came
#'   (`not_from_repository`) or they weren't found (`missing`).
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
  source <- vapply(entries, lock_source, character(1))
  if (!all) {
    # conda-forge brings in what other packages need, but only its own
    needed <- unlist(lapply(entries, lock_requirements))
    keep <- !names(entries) %in% needed | source != "repository"
    entries <- entries[keep]
    source <- source[keep]
  }
  github <- entries[source == "github"]
  subfolder <- names(entries)[source == "subfolder"]
  other <- names(entries)[source == "other"]
  entries <- entries[source == "repository"]

  found <- find_r_packages(names(entries))
  missing <- names(found)[is.na(found)]
  repositories <- lock_repositories(lock)
  cran <- missing[vapply(
    entries[missing],
    from_cran,
    logical(1),
    repositories = repositories
  )]
  missing <- setdiff(missing, cran)
  entries <- entries[!is.na(found[names(entries)])]
  specs <- vapply(
    names(entries),
    function(package) {
      lock_spec(found[[package]], entries[[package]]$Version, versions)
    },
    character(1)
  )

  # CRAN packages that aren't on conda-forge, built from CRAN's source if
  # asked. A build from source takes an exact version, but not a range.
  built <- character()
  declined <- character()
  if (length(cran) > 0) {
    constraints <- vapply(
      cran,
      function(package) {
        version <- lock$Packages[[package]]$Version
        if (versions == "exact" && !is.null(version)) {
          paste0("==", version)
        } else {
          ""
        }
      },
      character(1)
    )
    parsed <- parse_packages(paste0("cran::", cran, constraints))
    built <- offer_cran_source(
      parsed,
      seq_along(cran),
      abort = FALSE,
      path = root
    )
    if (is.null(built)) {
      declined <- cran
      cran <- character()
    }
  }
  github_specs <- vapply(github, lock_github, character(1), versions = versions)

  r_version <- lock$R$Version
  r_constraint <- if (is.null(r_version) || versions == "none") {
    ""
  } else {
    minor <- sub("^([0-9]+\\.[0-9]+).*$", "\\1", r_version)
    if (versions == "exact") paste0("=", minor) else paste0(">=", minor)
  }
  added <- add_imported(
    unname(c(specs, built, github_specs)),
    r_constraint = r_constraint,
    root = root,
    dry_run = dry_run,
    newest_r = TRUE
  )

  from_source <- c(cran, names(github))
  if (length(from_source) > 0) {
    if (isTRUE(dry_run)) {
      cli::cli_alert_info(
        "Would build {.pkg {from_source}} from source, which is experimental."
      )
    } else {
      cli::cli_alert_info(
        "Built {.pkg {from_source}} from source, which is experimental."
      )
    }
  }
  if (length(subfolder) > 0) {
    cli::cli_alert_warning(
      "In a subfolder of a GitHub repository, which rpix can't add yet, so not added: {.pkg {subfolder}}."
    )
  }
  if (length(other) > 0) {
    cli::cli_alert_warning(
      "Not from CRAN, Bioconductor or GitHub, so not added: {.pkg {other}}."
    )
  }
  # The CRAN packages it didn't build were listed when it offered to
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
    from_source = from_source,
    not_from_repository = c(subfolder, other),
    missing = c(missing, declined)
  ))
}

# The packages a package in renv.lock needs. renv 1.1 and later record its
# Depends, Imports and LinkingTo, with versions, and older renv Requirements.
lock_requirements <- function(entry) {
  fields <- c(entry$Requirements, entry$Depends, entry$Imports, entry$LinkingTo)
  sub("[[:space:]]*\\(.*$", "", unlist(fields))
}

# Where a package in renv.lock is from: "repository" (CRAN-like or
# Bioconductor), "github", "subfolder" (on GitHub, but in a subfolder of the
# repository, which `github::` can't say), or "other"
lock_source <- function(entry) {
  source <- entry$Source %||% ""
  if (source %in% c("Repository", "Bioconductor")) {
    return("repository")
  }
  github <- identical(source, "GitHub") ||
    identical(tolower(entry$RemoteType %||% ""), "github")
  # GitHub Enterprise has its own host
  host <- entry$RemoteHost %||% "api.github.com"
  if (
    !github ||
      !host %in% c("api.github.com", "github.com") ||
      is.null(entry$RemoteUsername) ||
      is.null(entry$RemoteRepo)
  ) {
    return("other")
  }
  if (nzchar(entry$RemoteSubdir %||% "")) {
    return("subfolder")
  }
  "github"
}

# A GitHub package in renv.lock as pixi_add() takes it: at the commit renv
# recorded, or with `versions = "none"`, the branch (or tag)
lock_github <- function(entry, versions) {
  ref <- if (versions == "none") {
    entry$RemoteRef
  } else {
    entry$RemoteSha %||% entry$RemoteRef
  }
  if (identical(ref, "HEAD")) {
    ref <- NULL
  }
  paste0(
    "github::",
    entry$RemoteUsername,
    "/",
    entry$RemoteRepo,
    if (!is.null(ref)) paste0("@", ref)
  )
}

# The lock file's repositories, as URLs by name
lock_repositories <- function(lock) {
  repositories <- lock$R$Repositories
  stats::setNames(
    vapply(repositories, function(r) r$URL %||% "", character(1)),
    vapply(repositories, function(r) r$Name %||% "", character(1))
  )
}

# Whether a package in renv.lock is from CRAN, or a mirror of it, whose
# source is on CRAN's GitHub mirror
from_cran <- function(entry, repositories) {
  if (!identical(entry$Source, "Repository")) {
    return(FALSE)
  }
  repository <- entry$Repository %||% "CRAN"
  url <- repositories[repository] %|NA|% repository
  toupper(repository) %in%
    c("CRAN", "RSPM", "PPM", "P3M") ||
    grepl("r-project\\.org|//cran\\.|/cran(/|$)", url, ignore.case = TRUE)
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

# Whether a package, possibly with a version, such as "r-cli==3.6.1", is on a
# channel
on_channel <- function(name, channel) {
  channels <- unique(c("conda-forge", channel))
  tryCatch(
    sub("[[:space:]=<>!~].*$", "", name) %in%
      search_names(
        c("search", as.vector(rbind("--channel", channels)), name),
        project = "none"
      ),
    rpix_error_pixi = function(e) FALSE
  )
}

# The names of the packages `pixi search` finds. Without an exact match, Pixi
# finds the names that contain the one searched for, e.g. r-fauxpas for
# r-faux, so check the name is among them.
search_names <- function(args, ...) {
  found <- tryCatch(
    run_pixi(args, json = TRUE, ...),
    rpix_error_pixi = function(e) {
      if (!grepl("No packages found", e$stderr, fixed = TRUE)) {
        stop(e)
      }
      list()
    }
  )
  unique(unlist(lapply(found, function(records) records$name)))
}

# The packages in the default feature
project_dependencies <- function(root) {
  envs <- pixi_info(root)$environments_info
  unlist(envs$dependencies[envs$name == "default"])
}
