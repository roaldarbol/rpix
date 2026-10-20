#' Report on the project's Pixi setup
#'
#' @description
#' Check that R, its packages and the IDE use the project's Pixi environment,
#' and suggest fixes for what doesn't. It reports:
#'
#' * Pixi: where it is, and its version.
#' * The project, and whether `pixi.lock` is up to date with `pixi.toml`.
#' * Whether the project was moved or copied: Pixi's activation cache then
#'   has the old location, so it's removed, and environments installed in the
#'   old location need reinstalling.
#' * The date the project's packages are as of, if it has one (see
#'   [pixi_set_date()]).
#' * In a package, whether `pixi.toml` has what its `DESCRIPTION` needs: the
#'   `Depends`, `Imports` and `LinkingTo` packages in the default environment,
#'   the `Suggests` somewhere (e.g. a `test` environment), and installed
#'   versions at least the minimums `DESCRIPTION` asks for.
#' * In a package, whether `.Rbuildignore` leaves Pixi's files out of its
#'   builds.
#' * Environments with R that don't keep your personal R library out, e.g.
#'   ones that leave out the default feature.
#' * Private channels that refuse access, and the hosts Pixi has logins for
#'   (see [pixi_auth_login()]).
#' * Whether the running R is the R of the project's environment, and whether
#'   the environment is activated.
#' * Libraries and loaded packages from outside the project, such as your
#'   personal library. R's base packages come with every R, so aren't listed.
#' * Packages in the environment that Pixi didn't install, e.g. with
#'   `utils::install.packages()`, so `pixi.toml` doesn't record them.
#' * Whether the project's `.Rprofile` activates the environment when an IDE
#'   starts R directly.
#' * Whether the IDE you're in is set up for the project: it runs the
#'   project's R, or is set up by [use_pixi()]. If it's set up but runs
#'   another R, how to start the project's R in it.
#'
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
#' @returns A list with what it found, invisibly.
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' pixi_sitrep(path = project)
pixi_sitrep <- function(path = NULL) {
  report <- sitrep_data(path)

  cli::cli_h2("Pixi")
  if (is.null(report[["pixi"]])) {
    cli::cli_alert_danger("Pixi isn't installed, or rpix can't find it.")
    hint("Install it with {.code rpix::install_pixi()}.")
  } else {
    cli::cli_alert_success(
      "{report$pixi_version} at {.path {report[['pixi']]}}"
    )
  }

  cli::cli_h2("Project")
  if (is.null(report$project)) {
    cli::cli_alert_danger("There's no Pixi project here.")
    hint("Create one with {.code rpix::use_pixi()}.")
  } else {
    cli::cli_alert_success("{.path {report$project}}")
    if (isFALSE(report$lock_up_to_date)) {
      cli::cli_alert_warning(
        "{.file pixi.lock} isn't up to date with {.file pixi.toml}."
      )
      hint("Run {.code pixi install}.")
    } else if (isTRUE(report$lock_up_to_date)) {
      cli::cli_alert_success("{.file pixi.lock} is up to date.")
    }
    if (isTRUE(report$stale_cache)) {
      cli::cli_bullets(stale_cache_bullet)
    }
    if (length(report$moved_environments) > 0) {
      cli::cli_bullets(moved_environments_bullets(report$moved_environments))
    }
    denied <- report$access_denied
    if (!is.null(denied)) {
      cli::cli_alert_danger(
        "{.val {denied$host}} refused access ({denied$status}), so Pixi can't install packages from it."
      )
      hint(
        "Log in with {.code rpix::pixi_auth_login(\"{denied$host}\")}."
      )
    }
    if (length(report$logins) > 0) {
      cli::cli_alert_info("Pixi has logins for {.val {report$logins}}.")
    }
    date <- report$exclude_newer
    if (is_absolute_date(date)) {
      cli::cli_alert_info("Packages are as they were on {.val {date}}.")
    } else if (!is.null(date)) {
      cli::cli_alert_info(
        "Packages published in the last {.val {date}} are left out."
      )
    }
    unisolated <- report$unisolated
    if (NROW(unisolated) > 0) {
      n <- nrow(unisolated)
      cli::cli_alert_warning(
        "{cli::qty(n)}The environment{?s} {.val {unisolated$name}} {?doesn't/don't} keep your personal R library out, so {?its/their} R can load packages built for another R, and crash."
      )
      for (feature in unique(unisolated$feature)) {
        fix <- isolation_fix(feature)
        hint("Add the isolation with {.code {fix}}.")
      }
    }
    unignored <- report$build_unignored
    if (length(unignored) > 0) {
      cli::cli_alert_warning(
        "The package's builds include {.file {unignored}}."
      )
      fix <- paste0("usethis::use_build_ignore(", deparse(unignored), ")")
      hint("Leave {cli::qty(unignored)}{?it/them} out with {.code {fix}}.")
    }
  }

  check <- report$description
  if (!is.null(check)) {
    cli::cli_h2("Package")
    if (length(check$missing) > 0) {
      cli::cli_alert_warning(
        "{.file DESCRIPTION} needs {.pkg {check$missing}}, which {cli::qty(length(check$missing))}{?isn't/aren't} in the default environment in {.file pixi.toml}."
      )
    }
    if (length(check$missing_suggests) > 0) {
      cli::cli_alert_info(
        "{.file DESCRIPTION} suggests {.pkg {check$missing_suggests}}, which {cli::qty(length(check$missing_suggests))}{?isn't/aren't} in {.file pixi.toml}."
      )
    }
    if (length(check$missing) + length(check$missing_suggests) > 0) {
      hint("Add them with {.code rpix::pixi_import_description()}.")
    }
    old <- check$too_old
    if (nrow(old) > 0) {
      versions <- paste0(
        old$package,
        " ",
        old$installed,
        " (needs >= ",
        old$needs,
        ")"
      )
      cli::cli_alert_warning(
        "Older than {.file DESCRIPTION} asks for: {versions}."
      )
      hint(
        "Update them with {.code rpix::pixi_update()}, or raise their constraints in {.file pixi.toml}."
      )
    }
    if (
      length(check$missing) + length(check$missing_suggests) + nrow(old) == 0
    ) {
      cli::cli_alert_success(
        "{.file pixi.toml} has what {.file DESCRIPTION} needs."
      )
    }
  }

  cli::cli_h2("R")
  cli::cli_alert_info("R {report$r_version} at {.path {report$r_home}}")
  if (is.null(report$environment)) {
    cli::cli_alert_danger("This R isn't from a Pixi environment.")
    if (isTRUE(report$ide_set_up)) {
      hint("Start R with {.code pixi run R}, or in the IDE as below.")
    } else {
      hint(
        "Start R with {.code pixi run R}, or set your IDE up with {.code rpix::use_pixi(ide = ...)}."
      )
    }
  } else if (!report$in_project) {
    cli::cli_alert_danger(
      "This R is from another project's Pixi environment, in {.path {report$environment$root}}."
    )
  } else {
    cli::cli_alert_success(
      "This R is from the project's {.val {report$environment$name}} environment."
    )
    if (report$activated) {
      cli::cli_alert_success("The environment is activated.")
    } else {
      cli::cli_alert_warning("The environment isn't activated.")
      hint(
        "Run {.code rpix::pixi_activate()}, or check the project's {.file .Rprofile}."
      )
    }
  }

  if (length(report$libraries_outside) > 0) {
    cli::cli_alert_warning("Libraries from outside the project:")
    cli::cli_bullets(stats::setNames(
      paste0("{.path ", cli_escape(report$libraries_outside), "}"),
      rep("*", length(report$libraries_outside))
    ))
    hint(
      "Packages built for another R can crash this one. See {.url https://roald-arboel.com/rpix/articles/how-rpix-works.html}."
    )
  } else if (report$in_project) {
    cli::cli_alert_success("All libraries are in the project.")
  }
  if (length(report$packages_outside) > 0) {
    cli::cli_alert_warning(
      "Loaded from outside the project: {.pkg {report$packages_outside}}"
    )
  }
  if (length(report$packages_unrecorded) > 0) {
    cli::cli_alert_warning(
      "Installed without Pixi, so not in {.file pixi.toml}: {.pkg {report$packages_unrecorded}}"
    )
    hint(
      "Add them with {.code rpix::pixi_add()}, so the project records them."
    )
  }

  if (isTRUE(report$renv)) {
    cli::cli_alert_warning(
      "The project also has renv, which clashes with Pixi."
    )
    hint(
      "Delete the {.file renv} folder and {.file renv.lock}, and the line in {.file .Rprofile} that runs {.file renv/activate.R}."
    )
  }

  if (!is.null(report$project)) {
    if (report$rprofile) {
      cli::cli_alert_success(
        "{.file .Rprofile} activates the environment when an IDE starts R."
      )
    } else {
      cli::cli_alert_info(
        "{.file .Rprofile} doesn't activate the environment when an IDE starts R."
      )
      hint("Run {.code rpix::use_pixi()} to add it.")
    }
  }

  cli::cli_h2("IDE")
  if (is.na(report$ide)) {
    cli::cli_alert_info(
      "Not in RStudio, Positron, VS Code, Emacs, Neovim or Zed."
    )
  } else if (!is.null(report$ide_step)) {
    cli::cli_alert_warning(
      "{ide_name(report$ide)} is set up for the project, but runs another R."
    )
    hint(report$ide_step)
  } else if (isTRUE(report$ide_set_up)) {
    cli::cli_alert_success("{ide_name(report$ide)} is set up for the project.")
  } else {
    cli::cli_alert_warning(
      "{ide_name(report$ide)} isn't set up for the project."
    )
    hint("Run {.code use_pixi_{report$ide}()}.")
  }

  invisible(report)
}

hint <- function(text, .envir = parent.frame()) {
  cli::cli_bullets(c(" " = text), .envir = .envir)
}

# What pixi_sitrep() reports on, without the printing
sitrep_data <- function(path = NULL) {
  pixi <- tryCatch(pixi_binary(offer_install = FALSE), error = function(e) NULL)
  pixi_version <- if (!is.null(pixi)) {
    trimws(run_pixi("--version", project = "none")$stdout)
  }

  project <- find_project_root(path)
  stale_cache <- !is.null(project) &&
    remove_stale_activation_cache(project, quiet = TRUE)
  lock <- if (!is.null(project) && !is.null(pixi)) {
    lock_up_to_date(project)
  }
  environment <- pixi_r_location(r_home())
  in_project <- !is.null(environment) &&
    !is.null(project) &&
    same_path(environment$root, project)

  inside <- function(path) in_folder(path, project)
  libraries <- .libPaths()
  outside <- if (is.null(project)) {
    character()
  } else {
    libraries[!vapply(libraries, inside, logical(1))]
  }

  # Base packages come with R, wherever it is
  packages <- setdiff(loadedNamespaces(), base_packages())
  package_paths <- vapply(
    packages,
    function(p) find.package(p, quiet = TRUE)[1],
    character(1)
  )
  packages_outside <- if (is.null(project)) {
    character()
  } else {
    sort(packages[!vapply(package_paths, inside, logical(1))])
  }

  ide <- detect_ide()
  # Running the project's activated R is what setting the IDE up is for,
  # whether by the project's settings or by the user's
  ide_ready <- if (!is.na(ide) && !is.null(project)) {
    in_project || ide_set_up(ide, project)
  }
  unignored <- if (!is.null(project)) {
    files <- pixi_files(project)
    if (dir.exists(file.path(project, ".vscode"))) {
      files <- c(files, ".vscode")
    }
    missing_build_ignores(project, files)
  }

  list(
    pixi = pixi,
    pixi_version = pixi_version,
    project = project,
    lock_up_to_date = lock,
    stale_cache = stale_cache,
    moved_environments = if (!is.null(project)) moved_environments(project),
    access_denied = attr(lock, "denied") %||%
      if (!is.null(project) && !is.null(pixi)) channel_access(project),
    logins = if (!is.null(pixi)) logins(),
    exclude_newer = if (!is.null(project)) project_exclude_newer(project),
    unisolated = if (!is.null(project) && !is.null(pixi)) {
      unisolated_environments(project)
    },
    r_home = r_home(),
    r_version = as.character(getRversion()),
    environment = environment,
    in_project = in_project,
    activated = in_project &&
      identical(Sys.getenv("PIXI_ENVIRONMENT_NAME"), environment$name),
    libraries_outside = unname(outside),
    packages_outside = unname(packages_outside),
    packages_unrecorded = if (in_project) {
      unrecorded_packages(environment$name, project)
    } else {
      character()
    },
    build_unignored = unignored %||% character(),
    description = if (!is.null(project)) {
      description_check(project, in_project)
    },
    rprofile = !is.null(project) &&
      has_rprofile_block(file.path(project, ".Rprofile")),
    renv = !is.null(project) && has_renv(project),
    ide = ide,
    ide_set_up = ide_ready,
    ide_step = if (isTRUE(ide_ready) && !in_project) ide_step(ide, project)
  )
}

# Packages in the environment's library that Pixi didn't install, e.g. with
# utils::install.packages(). rpix itself may come from GitHub (options(rpix.ref)), and
# the project's own package from the project.
unrecorded_packages <- function(environment, root) {
  installed <- rownames(utils::installed.packages(lib.loc = .Library))
  from_pixi <- tryCatch(
    stats::na.omit(pixi_list(environment, path = root)$r_package),
    error = function(e) NULL
  )
  if (is.null(from_pixi)) {
    return(character())
  }
  known <- tolower(c(from_pixi, base_packages(), "rpix", package_name(root)))
  sort(installed[!tolower(installed) %in% known])
}

# Whether a path is a folder, or inside it
in_folder <- function(path, folder) {
  if (is.null(folder) || is.na(path)) {
    return(FALSE)
  }
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  folder <- normalizePath(folder, winslash = "/", mustWork = FALSE)
  path == folder || startsWith(path, paste0(folder, "/"))
}

# TRUE or FALSE, or NA if Pixi couldn't tell, e.g. offline
# When a channel refused access, NA, with the status and host as the
# "denied" attribute
lock_up_to_date <- function(project) {
  tryCatch(
    {
      run_pixi(c("lock", "--check", "--dry-run"), path = project)
      TRUE
    },
    rpix_error_pixi = function(e) {
      if (grepl("not up-to-date", e$stderr, fixed = TRUE)) {
        return(FALSE)
      }
      structure(NA, denied = access_denied(e$stderr))
    }
  )
}

# Whether Pixi can reach the project's channels given as URLs, which is how
# private channels are given. A search for a package that doesn't exist finds
# nothing on a channel Pixi can reach, and is refused on one it can't. Returns
# the first refusal, or NULL.
channel_access <- function(project) {
  channels <- tryCatch(project_channels(project), error = function(e) NULL)
  channels <- channels[grepl("^[a-z0-9+.-]+://", channels)]
  for (channel in channels) {
    denied <- tryCatch(
      {
        run_pixi(
          c("search", "--channel", channel, "rpix-access-check"),
          project = "none"
        )
        NULL
      },
      rpix_error_pixi = function(e) access_denied(e$stderr)
    )
    if (!is.null(denied)) {
      return(denied)
    }
  }
  NULL
}

# The hosts Pixi has credentials for
logins <- function() {
  tryCatch(pixi_auth_status()$host, error = function(e) character())
}

has_rprofile_block <- function(file) {
  file.exists(file) && rprofile_block[1] %in% readLines(file, warn = FALSE)
}

detect_ide <- function() {
  if (identical(Sys.getenv("POSITRON"), "1")) {
    "positron"
  } else if (identical(Sys.getenv("RSTUDIO"), "1")) {
    "rstudio"
  } else if (nzchar(Sys.getenv("INSIDE_EMACS"))) {
    # Before the terminals below, as an editor can run in one of them
    "emacs"
  } else if (nzchar(Sys.getenv("NVIM"))) {
    "neovim"
  } else if (identical(Sys.getenv("TERM_PROGRAM"), "vscode")) {
    "vscode"
  } else if (identical(Sys.getenv("TERM_PROGRAM"), "zed")) {
    "zed"
  } else {
    NA_character_
  }
}

ide_name <- function(ide) {
  c(
    rstudio = "RStudio",
    positron = "Positron",
    vscode = "VS Code",
    emacs = "Emacs",
    neovim = "Neovim",
    zed = "Zed"
  )[[ide]]
}

# Whether an IDE is set up the way use_pixi_<ide>() sets it up
ide_set_up <- function(ide, project) {
  if (ide == "rstudio") {
    tasks <- run_pixi(c("task", "list"), path = project, json = TRUE)
    names <- unlist(lapply(tasks$features, function(f) {
      lapply(f$tasks, function(t) t$name)
    }))
    return("rstudio" %in% names)
  }
  if (ide %in% c("vscode", "emacs", "neovim", "zed") && is_windows()) {
    # These leave R to the PATH on Windows
    return(!is.null(pixi_r_location(r_home())))
  }
  if (ide %in% c("emacs", "neovim", "zed")) {
    return(direnv_set_up(project))
  }
  file <- file.path(project, ".vscode", "settings.json")
  settings <- if (file.exists(file)) {
    tryCatch(jsonlite::read_json(file), error = function(e) list())
  } else {
    list()
  }
  if (ide == "positron") {
    isTRUE(settings[["positron.r.interpreters.pixiDiscovery"]])
  } else {
    grepl(".pixi", settings[["r.executablePath"]] %||% "", fixed = TRUE)
  }
}

# How to start the project's R in an IDE that's set up for it, but runs
# another R
ide_step <- function(ide, project) {
  if (ide == "rstudio") {
    step <- "Start RStudio with {.code pixi run rstudio} in the project"
    addin <- rstudio_addin("addin_open_with_pixi_r")
    if (is.null(addin)) {
      return(paste0(step, "."))
    }
    return(paste0(step, ", or with {.val ", addin, "} in rpix's Addins."))
  }
  if (ide == "positron") {
    return("Pick {.val R (Pixi: default)} in Positron's interpreter picker.")
  }
  if (is_windows()) {
    # These leave R to the PATH on Windows
    return(paste0(
      "Start ",
      ide_name(ide),
      " from the project's environment, with {.code pixi run ",
      editor_command(ide),
      "}."
    ))
  }
  if (ide == "vscode") {
    if (!file.exists(environment_r(project, "default"))) {
      return(
        "Run {.code rpix::pixi_install()}, then {.strong Developer: Reload Window} from the Command Palette."
      )
    }
    return(
      "Start R with {.strong R: Create R Terminal} from the Command Palette."
    )
  }
  "Run {.code direnv allow} in the project, then restart R."
}

# The name of one of rpix's RStudio addins, or NULL if this rpix doesn't have
# it
rstudio_addin <- function(
  binding,
  file = system.file("rstudio", "addins.dcf", package = "rpix")
) {
  if (!nzchar(file)) {
    return(NULL)
  }
  addins <- read.dcf(file, fields = c("Name", "Binding"))
  name <- addins[addins[, "Binding"] %in% binding, "Name"]
  if (length(name) == 0) NULL else name[[1]]
}

# The project's exclude-newer, or NULL
project_exclude_newer <- function(root) {
  manifest <- find_manifest(root)
  if (is.null(manifest)) {
    return(NULL)
  }
  manifest_exclude_newer(readLines(manifest, warn = FALSE))
}

# Environments with R but without the isolation from the personal library,
# e.g. ones that leave out the default feature, where use_pixi() adds it. A
# data frame with the environment and the feature to add it to.
unisolated_environments <- function(project) {
  envs <- tryCatch(pixi_info(project)$environments_info, error = function(e) {
    NULL
  })
  if (is.null(envs$name)) {
    return(NULL)
  }
  deps <- lapply(envs$dependencies, unlist)
  keep <- vapply(
    deps,
    function(d) "r-base" %in% d && !isolation_package %in% d,
    logical(1)
  )
  data.frame(
    name = envs$name[keep],
    feature = vapply(
      envs$features[keep],
      function(f) unlist(f)[1],
      character(1)
    )
  )
}

# The pixi_add() call that adds the isolation to a feature
isolation_fix <- function(feature) {
  paste0(
    'rpix::pixi_add("conda::',
    isolation_package,
    '"',
    if (!identical(feature, "default")) paste0(', feature = "', feature, '"'),
    ")"
  )
}
