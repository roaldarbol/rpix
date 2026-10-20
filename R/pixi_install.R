#' Install and update the project's packages
#'
#' @description
#' * `pixi_install()` installs an environment as `pixi.lock` describes it,
#'   e.g. after cloning a project. `pixi run` does this by itself, too. If
#'   `pixi.lock` is out of date with `pixi.toml`, Pixi updates it first,
#'   unless `locked` or `frozen` says otherwise.
#' * `pixi_update()` updates packages to the newest versions `pixi.toml`
#'   allows, in `pixi.lock`, and installs them.
#' * `pixi_upgrade()` updates packages beyond that, and raises the versions in
#'   `pixi.toml` to match. It leaves R as it is, unless `r = TRUE`.
#' * `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
#'   installing anything.
#'
#' In an interactive session, `pixi_update()` and `pixi_upgrade()` first show
#' what would change, and ask before going ahead. Then they install the
#' environment this R runs in, or else the default one (or `environment`). If
#' that's this R's own environment, restart R afterwards, as the packages it
#' has loaded still use the old files: in RStudio, they offer to. On Windows,
#' a running R keeps Pixi from replacing its packages' files, so there they
#' only update `pixi.lock`, and say how to install it after closing R.
#'
#' Upgrading R (`r = TRUE`) means every R package needs a build for the new R.
#' conda-forge has fewer packages for a new version of R at first, and
#' packages built from source are pinned to the R they were added for, so R
#' only moves as far as all the project's packages allow.
#'
#' Package names are translated like in [pixi_add()]. If Pixi skips an install
#' script that a package needs, such as the ones Bioconductor's data packages
#' download their data with, these functions offer to allow them in the
#' project, as [pixi_add()] does.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/install/>,
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/update/>,
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/upgrade/> and
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/lock/>.
#'
#' @param environment Optional. The environment. Defaults to `default`.
#' @param all If `TRUE`, install all the project's environments.
#' @param locked If `TRUE`, fail if `pixi.lock` is out of date with
#'   `pixi.toml`, rather than updating it, e.g. to check that a collaborator
#'   or CI gets exactly what's committed.
#' @param frozen If `TRUE`, install exactly what `pixi.lock` says, without
#'   checking it against `pixi.toml`.
#' @param packages Optional. Only update these packages. Defaults to all.
#' @param feature Optional. Only upgrade the packages of this feature.
#' @param r If `TRUE`, upgrade R too (`r-base`), as far as the project's
#'   packages allow. Naming `"r-base"` in `packages` does the same.
#' @inheritParams pixi_environments
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' pixi_install(path = project, dry_run = TRUE)
#' pixi_update("dplyr", path = project, dry_run = TRUE)
#' pixi_upgrade(path = project, dry_run = TRUE)
pixi_install <- function(
  environment = NULL,
  all = FALSE,
  locked = FALSE,
  frozen = FALSE,
  path = NULL,
  dry_run = FALSE
) {
  if (isTRUE(locked) && isTRUE(frozen)) {
    cli::cli_abort(
      c(
        "Use {.arg locked} or {.arg frozen}, not both.",
        "i" = "{.arg locked} fails if {.file pixi.lock} is out of date; {.arg frozen} doesn't check."
      )
    )
  }
  args <- c(
    "install",
    if (!is.null(environment)) c("--environment", environment),
    if (all) "--all",
    if (isTRUE(locked)) "--locked",
    if (isTRUE(frozen)) "--frozen"
  )
  result <- run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
  if (!isTRUE(dry_run)) {
    check_post_link(result, path = path, environment = environment)
  }
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_update <- function(
  packages = NULL,
  environment = NULL,
  path = NULL,
  dry_run = FALSE
) {
  args <- c(
    "update",
    package_names(packages),
    if (!is.null(environment)) c("--environment", environment)
  )
  if (isTRUE(dry_run)) {
    return(run_pixi(args, path = path, echo = TRUE, dry_run = TRUE))
  }
  if (!confirm_changes(args, path)) {
    return(invisible(NULL))
  }
  result <- run_pixi(args, path = path, echo = TRUE)
  check_post_link(result, path = path, environment = environment)
  # Pixi only updates pixi.lock
  install_updated_environment(environment, path)
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_upgrade <- function(
  packages = NULL,
  feature = NULL,
  r = FALSE,
  path = NULL,
  dry_run = FALSE
) {
  names <- package_names(packages)
  r <- isTRUE(r) || "r-base" %in% names
  args <- c(
    "upgrade",
    names,
    if (!is.null(feature)) c("--feature", feature),
    # Otherwise it upgrades R with everything else
    if (is.null(names) && !r) c("--exclude", "r-base")
  )
  if (isTRUE(dry_run)) {
    return(run_pixi(args, path = path, echo = TRUE, dry_run = TRUE))
  }
  if (is.null(names) && !r) {
    cli::cli_alert_info(
      "Leaving R as it is. To upgrade it too, use {.code rpix::pixi_upgrade(r = TRUE)}."
    )
  }
  if (!confirm_changes(args, path, r = r)) {
    return(invisible(NULL))
  }
  # rpix installs, so it can leave out an environment that this R runs in
  result <- run_pixi(c(args, "--no-install"), path = path, echo = TRUE)
  check_post_link(result, path = path)
  install_updated_environment(NULL, path)
  invisible(result)
}

#' @rdname pixi_install
#' @export
pixi_lock <- function(path = NULL, dry_run = FALSE) {
  run_pixi("lock", path = path, echo = TRUE, dry_run = dry_run)
}

# Conda names of packages, or nothing for none
package_names <- function(packages) {
  if (length(packages) == 0) {
    return(NULL)
  }
  parse_packages(packages)$name
}

# After pixi add and pixi remove, Pixi only installs when the project has one
# environment (https://github.com/roaldarbol/rpix/issues/202). Otherwise,
# install the environment this R runs in, or else the default one, if the
# change applies to it, so what was added can be loaded straight away.
install_changed_environment <- function(feature = NULL, path = NULL) {
  if (tolower(Sys.getenv("PIXI_NO_INSTALL")) %in% c("1", "true")) {
    return(NULL)
  }
  # The change is made by now, so not knowing the environments doesn't fail it
  environments <- tryCatch(pixi_environments(path), error = function(e) NULL)
  if (is.null(environments) || nrow(environments) <= 1) {
    return(NULL)
  }
  running <- running_environment(path)
  environment <- if (!is.null(running) && running %in% environments$name) {
    running
  } else {
    "default"
  }
  features <- environments$features[[match(environment, environments$name)]]
  if (!(feature %||% "default") %in% features) {
    return(NULL)
  }
  cli::cli_alert_info(
    "Installing the {.val {environment}} environment, as Pixi doesn't by itself in a project with several environments."
  )
  run_pixi(
    c("install", "--environment", environment),
    path = path,
    echo = TRUE
  )
}

# Install an environment, saying so the first time, when it takes a while.
# Pixi only shows progress bars in a terminal, so show what it prints.
install_environment <- function(environment, root) {
  args <- c("install", "--environment", environment)
  if (dir.exists(file.path(root, ".pixi", "envs", environment, "conda-meta"))) {
    return(run_pixi(args, path = root))
  }
  cli::cli_alert_info(
    "Installing the {.val {environment}} environment (first time only){cli::symbol$ellipsis}"
  )
  run_pixi(args, path = root, echo = TRUE, announce = FALSE)
}

# The project's environment that this R runs in, or NULL if it runs in none of
# them
running_environment <- function(path = NULL) {
  running <- pixi_r_location(r_home())
  root <- find_project_root(path %||% getwd())
  if (is.null(running) || is.null(root) || !same_path(running$root, root)) {
    return(NULL)
  }
  running$name
}

# After pixi update or pixi upgrade, install the environment, or the one this
# R runs in, or else the default one, so the new versions can be loaded. This
# R's own environment needs a restart afterwards, as the packages it has
# loaded still use the old files, and on Windows can't be installed at all
# while it runs, as R holds its packages' DLLs open.
install_updated_environment <- function(environment = NULL, path = NULL) {
  if (tolower(Sys.getenv("PIXI_NO_INSTALL")) %in% c("1", "true")) {
    return(NULL)
  }
  running <- running_environment(path)
  environment <- environment %||% running %||% "default"
  here <- identical(environment, running)
  if (here && is_windows()) {
    cli::cli_alert_warning(
      "{.file pixi.lock} has the new versions, but the {.val {environment}} environment doesn't yet: on Windows, Pixi can't replace the files of packages that this R has loaded."
    )
    cli::cli_alert_info(
      "Close R, then install it with {.code pixi install} in a terminal in the project, or with {.code rpix::pixi_install()} from R outside the project's environment, such as your usual R."
    )
    return(NULL)
  }
  result <- run_pixi(
    c("install", "--environment", environment),
    path = path,
    echo = TRUE
  )
  check_post_link(result, path = path, environment = environment)
  if (here) {
    offer_restart()
  }
  invisible(result)
}

# After installing into the environment this R runs in
offer_restart <- function() {
  restart <- rstudio_api("restartSession")
  if (!is.null(restart) && offer("Restart R now, to use the new versions?")) {
    restart()
    return(invisible(TRUE))
  }
  cli::cli_alert_info(
    "Restart R to use the new versions: the packages this R has loaded still use the old files."
  )
  invisible(FALSE)
}

# In an interactive session, show what pixi update or pixi upgrade would
# change, and ask before going ahead. TRUE to go ahead: always outside an
# interactive session, and if Pixi can't say (it then fails, or shows the
# changes, as it goes ahead).
confirm_changes <- function(args, path = NULL, r = FALSE) {
  if (!is_interactive()) {
    return(TRUE)
  }
  preview <- tryCatch(
    run_pixi(c(args, "--dry-run", "--json"), path = path),
    error = function(e) NULL
  )
  changes <- tryCatch(
    jsonlite::fromJSON(preview$stdout, simplifyVector = FALSE)$environment,
    error = function(e) NULL
  )
  if (is.null(preview) || !is.list(changes)) {
    return(TRUE)
  }
  if (length(changes) == 0) {
    cli::cli_alert_success("Nothing to update.")
    return(FALSE)
  }
  r_changes <- character()
  for (environment in names(changes)) {
    platforms <- changes[[environment]]
    platform <- if (conda_platform() %in% names(platforms)) {
      conda_platform()
    } else {
      names(platforms)[1]
    }
    rows <- change_rows(platforms[[platform]])
    shown <- rows[rows$explicit, ]
    cli::cli_text(
      "In the {.val {environment}} environment ({platform}):"
    )
    bullets <- ifelse(
      shown$before == shown$after,
      paste0(shown$label, ": ", shown$after, " (a new build)"),
      paste0(
        shown$label,
        ": ",
        shown$before,
        " ",
        cli::symbol$arrow_right,
        " ",
        shown$after
      )
    )
    others <- nrow(rows) - nrow(shown)
    if (others > 0) {
      bullets <- c(
        bullets,
        cli::format_inline(
          "and {others} package{?s} that these depend on"
        )
      )
    }
    cli::cli_bullets(stats::setNames(bullets, rep("*", length(bullets))))
    r_changes <- c(r_changes, shown$after[shown$name == "r-base"])
  }
  if (r) {
    if (length(r_changes) > 0) {
      cli::cli_alert_warning(
        "This upgrades R, so every R package changes to a build for the new R."
      )
    } else {
      cli::cli_alert_info(
        "R stays as it is: some of the project's packages have no build for a newer R yet, or are built from source for this R."
      )
    }
  }
  offer("Go ahead?")
}

# The changes Pixi reports for one platform of an environment, as a data
# frame: conda name, how rpix shows it, versions before and after, and whether
# it's one of the project's own packages, rather than one they depend on
change_rows <- function(changes) {
  version <- function(entry) {
    if (is.null(entry)) {
      return("none")
    }
    if (!is.null(entry$version)) {
      return(entry$version)
    }
    file <- sub("\\.(conda|tar\\.bz2)$", "", basename(entry$conda %||% ""))
    parts <- strsplit(file, "-", fixed = TRUE)[[1]]
    if (length(parts) >= 3) parts[length(parts) - 1] else "?"
  }
  name <- vapply(changes, function(x) x$name, character(1))
  data.frame(
    name = name,
    label = display_name(name),
    before = vapply(changes, function(x) version(x$before), character(1)),
    after = vapply(changes, function(x) version(x$after), character(1)),
    explicit = vapply(changes, function(x) isTRUE(x$explicit), logical(1)),
    stringsAsFactors = FALSE
  )
}

# Conda names as rpix shows them: R packages by their R names
display_name <- function(names) {
  ifelse(
    names == "r-base",
    "R",
    sub("^(r|bioconductor)-", "", names)
  )
}

# The conda platform of this computer, e.g. "osx-arm64"
conda_platform <- function() {
  arm <- R.version$arch %in% c("aarch64", "arm64")
  if (is_windows()) {
    "win-64"
  } else if (Sys.info()[["sysname"]] == "Darwin") {
    if (arm) "osx-arm64" else "osx-64"
  } else {
    if (arm) "linux-aarch64" else "linux-64"
  }
}
