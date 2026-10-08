#' Report on the project's Pixi setup
#'
#' @description
#' Check that R, its packages and the IDE use the project's Pixi environment,
#' and suggest fixes for what doesn't. It reports:
#'
#' * Pixi: where it is, and its version.
#' * The project, and whether `pixi.lock` is up to date with `pixi.toml`.
#' * Whether the running R is the R of the project's environment, and whether
#'   the environment is activated.
#' * Libraries and loaded packages from outside the project, such as your
#'   personal library.
#' * Whether the project's `.Rprofile` activates the environment when an IDE
#'   starts R directly.
#' * Whether the IDE you're in is set up for the project: it runs the
#'   project's R, or is set up by [use_pixi()].
#'
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
#' @returns A list with what it found, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_sitrep()
#' }
pixi_sitrep <- function(path = NULL) {
  report <- sitrep_data(path)

  cli::cli_h2("Pixi")
  if (is.null(report[["pixi"]])) {
    cli::cli_alert_danger("Pixi isn't installed, or rpix can't find it.")
    hint("Install it from {.url https://pixi.sh}.")
  } else {
    cli::cli_alert_success(
      "{report$pixi_version} at {.path {report[['pixi']]}}"
    )
  }

  cli::cli_h2("Project")
  if (is.null(report$project)) {
    cli::cli_alert_danger("There's no Pixi project here.")
    hint("Create one with {.code use_pixi()}.")
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
  }

  cli::cli_h2("R")
  cli::cli_alert_info("R {report$r_version} at {.path {report$r_home}}")
  if (is.null(report$environment)) {
    cli::cli_alert_danger("This R isn't from a Pixi environment.")
    hint(
      "Start R with {.code pixi run R}, or set your IDE up with {.code use_pixi(ide = ...)}."
    )
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
        "Run {.code pixi_activate()}, or check the project's {.file .Rprofile}."
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

  if (!is.null(report$project)) {
    if (report$rprofile) {
      cli::cli_alert_success(
        "{.file .Rprofile} activates the environment when an IDE starts R."
      )
    } else {
      cli::cli_alert_info(
        "{.file .Rprofile} doesn't activate the environment when an IDE starts R."
      )
      hint("Run {.code use_pixi()} to add it.")
    }
  }

  cli::cli_h2("IDE")
  if (is.na(report$ide)) {
    cli::cli_alert_info("Not in RStudio, Positron or VS Code.")
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
  pixi <- tryCatch(pixi_binary(), error = function(e) NULL)
  pixi_version <- if (!is.null(pixi)) {
    trimws(run_pixi("--version", project = "none")$stdout)
  }

  project <- find_project_root(path)
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

  packages <- loadedNamespaces()
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

  list(
    pixi = pixi,
    pixi_version = pixi_version,
    project = project,
    lock_up_to_date = if (!is.null(project) && !is.null(pixi)) {
      lock_up_to_date(project)
    },
    r_home = r_home(),
    r_version = as.character(getRversion()),
    environment = environment,
    in_project = in_project,
    activated = in_project &&
      identical(Sys.getenv("PIXI_ENVIRONMENT_NAME"), environment$name),
    libraries_outside = unname(outside),
    packages_outside = unname(packages_outside),
    rprofile = !is.null(project) &&
      has_rprofile_block(file.path(project, ".Rprofile")),
    ide = ide,
    # Running the project's activated R is what setting the IDE up is for,
    # whether by the project's settings or by the user's
    ide_set_up = if (!is.na(ide) && !is.null(project)) {
      in_project || ide_set_up(ide, project)
    }
  )
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
lock_up_to_date <- function(project) {
  tryCatch(
    {
      run_pixi(c("lock", "--check", "--dry-run"), path = project)
      TRUE
    },
    rpix_error_pixi = function(e) {
      if (grepl("not up-to-date", e$stderr, fixed = TRUE)) FALSE else NA
    }
  )
}

has_rprofile_block <- function(file) {
  file.exists(file) && rprofile_block[1] %in% readLines(file, warn = FALSE)
}

detect_ide <- function() {
  if (identical(Sys.getenv("POSITRON"), "1")) {
    "positron"
  } else if (identical(Sys.getenv("RSTUDIO"), "1")) {
    "rstudio"
  } else if (identical(Sys.getenv("TERM_PROGRAM"), "vscode")) {
    "vscode"
  } else {
    NA_character_
  }
}

ide_name <- function(ide) {
  c(rstudio = "RStudio", positron = "Positron", vscode = "VS Code")[[ide]]
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
  if (ide == "vscode" && is_windows()) {
    # use_pixi_vscode() leaves R to the PATH on Windows
    return(!is.null(pixi_r_location(r_home())))
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
