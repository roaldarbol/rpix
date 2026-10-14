#' Activate the project's Pixi environment in the running R
#'
#' @description
#' Make R that was started directly from a Pixi environment, as IDEs such as
#' Positron and VS Code do, behave like R started with `pixi run R`. Called
#' from the project's `.Rprofile`, which [use_pixi()] sets up.
#'
#' * If Pixi didn't activate the environment, its environment variables are
#'   set, as `pixi shell-hook` reports them. Some packages need them, e.g. to
#'   find their data.
#' * Your personal library is removed from `.libPaths()`, and the project's
#'   own library added if it exists. Other libraries, such as temporary ones
#'   that devtools adds, are kept.
#' * `install.packages()` adds packages with [pixi_add()] instead, so they're
#'   recorded in `pixi.toml` and `pixi.lock`. For a CRAN package that isn't on
#'   conda-forge, `pixi_add()` offers to build it from source. Arguments Pixi
#'   can't use, such as `lib` or `repos`, and package files give an error.
#'   Turn this off with `options(rpix.install_packages = FALSE)`.
#' * If R isn't the R of a Pixi environment in this project, nothing changes;
#'   in an interactive session you get a hint instead. In RStudio, it also
#'   offers to reopen the project in a new RStudio with the environment's R,
#'   and to close this one. Turn that off with `RPIX_OFFER_SWITCH=false` in
#'   your `.Renviron`.
#' * If the project also has renv, e.g. because RStudio's New Project set it
#'   up, it says so: renv and Pixi both manage the project's packages.
#'
#' It never fails: problems are reported as messages.
#'
#' @param path The project. Defaults to the working directory, which is where
#'   R reads `.Rprofile` from.
#' @param quiet If `TRUE`, show no messages.
#' @returns A list, invisibly: `activated` is `TRUE` if environment variables
#'   were set, and `lib_paths` the new library paths, or `NULL` if they
#'   weren't changed.
#' @export
#' @examples
#' \dontrun{
#' pixi_activate()
#' }
pixi_activate <- function(path = getwd(), quiet = !interactive()) {
  result <- list(activated = FALSE, lib_paths = NULL)
  inform <- function(msg) if (!quiet) cli::cli_inform(msg)

  tryCatch(
    {
      env <- pixi_r_location(r_home())
      root <- find_project_root(path)
      if (!is.null(root) && has_renv(root)) {
        inform(renv_clash_message())
      }
      if (is.null(env) || is.null(root) || !same_path(env$root, root)) {
        in_rstudio <- identical(detect_ide(), "rstudio") && !is.null(root)
        inform(c(
          "!" = "This R isn't from the project's Pixi environment, so it doesn't use the project's packages.",
          "i" = if (in_rstudio) {
            "Move to its R with {.strong Addins > Open with the project's Pixi R}, or {.code rpix::pixi_switch()}."
          } else {
            "Start R with {.code pixi run R}, or see {.url https://roald-arboel.com/rpix/articles/ide.html}."
          }
        ))
        # Once RStudio is ready, offer to reopen the project with its R
        if (!quiet && in_rstudio && offer_switch_enabled()) {
          when_rstudio_ready(function() offer_pixi_r(root))
        }
        return(invisible(result))
      }

      personal <- Sys.getenv("R_LIBS_USER")
      original_paths <- .libPaths()
      # Before anything loads a package: the personal library has packages
      # built for another R, which can crash this one
      .libPaths(clean_lib_paths(
        .libPaths(),
        personal,
        project = "",
        root = root
      ))

      activated_by_pixi <- identical(
        Sys.getenv("PIXI_ENVIRONMENT_NAME"),
        env$name
      ) &&
        same_path(pixi_root_env(), root)

      if (!activated_by_pixi) {
        vars <- activation_variables(root, env$name)
        if (is.null(vars)) {
          inform(c(
            "!" = "Couldn't activate the project's Pixi environment.",
            "i" = "If you changed {.file pixi.toml}, run {.code pixi install}."
          ))
        } else {
          do.call(Sys.setenv, as.list(vars))
          result$activated <- TRUE
        }
      }

      .libPaths(clean_lib_paths(
        .libPaths(),
        personal = "",
        project = Sys.getenv("R_LIBS_USER"),
        root = root
      ))
      if (!identical(.libPaths(), original_paths)) {
        result$lib_paths <- .libPaths()
      }
      attach_install_packages(root)
    },
    error = function(e) {
      inform(c(
        "!" = "Couldn't activate the project's Pixi environment.",
        "x" = conditionMessage(e)
      ))
    }
  )

  invisible(result)
}

#' Which Pixi environment an R installation belongs to
#'
#' @param r_home The R installation, as from [R.home()].
#' @returns A list with the project `root` and environment `name`, or `NULL` if
#'   R isn't in a Pixi environment.
#' @noRd
pixi_r_location <- function(r_home) {
  r_home <- normalizePath(r_home, winslash = "/", mustWork = FALSE)
  pattern <- "^(.*)/\\.pixi/envs/([^/]+)/lib/R/?$"
  if (!grepl(pattern, r_home)) {
    return(NULL)
  }
  list(
    root = sub(pattern, "\\1", r_home),
    name = sub(pattern, "\\2", r_home)
  )
}

#' The environment variables `pixi shell-hook` sets for an environment
#'
#' Uses `--frozen` and the activation cache, which together keep it fast
#' enough for R's startup. The cache is experimental in Pixi, so falls back to
#' running without it.
#' @returns A named character vector, or `NULL` if Pixi couldn't activate it.
#' @noRd
activation_variables <- function(root, env) {
  args <- c("shell-hook", "--environment", env, "--frozen")
  for (extra in list("--use-environment-activation-cache", NULL)) {
    hook <- tryCatch(
      run_pixi(c(args, extra), path = root, json = TRUE),
      error = function(e) NULL
    )
    if (!is.null(hook)) {
      vars <- hook$environment_variables
      return(stats::setNames(as.character(unlist(vars)), names(vars)))
    }
  }
  NULL
}

#' Remove the personal library from library paths
#'
#' @param paths The current library paths.
#' @param personal The personal library (or several, separated like `PATH`),
#'   as R had it at startup. Libraries inside the project are kept.
#' @param project The project's own library. Added at the front if it exists
#'   and is inside the project.
#' @param root The project root.
#' @noRd
clean_lib_paths <- function(paths, personal, project, root) {
  norm <- function(x) normalizePath(x, winslash = "/", mustWork = FALSE)
  personal <- strsplit(personal, .Platform$path.sep, fixed = TRUE)[[1]]
  personal <- norm(personal[nzchar(personal)])
  personal <- personal[!startsWith(personal, paste0(norm(root), "/"))]

  paths <- paths[!norm(paths) %in% personal]
  project <- norm(project)
  in_project <- nzchar(project) && startsWith(project, paste0(norm(root), "/"))
  if (in_project && dir.exists(project) && !project %in% norm(paths)) {
    paths <- c(project, paths)
  }
  paths
}

# R.home(), wrapped so tests can pretend to be a different R
r_home <- function() {
  R.home()
}

same_path <- function(x, y) {
  nzchar(x) &&
    nzchar(y) &&
    identical(
      normalizePath(x, winslash = "/", mustWork = FALSE),
      normalizePath(y, winslash = "/", mustWork = FALSE)
    )
}

# Whether rpix may offer to reopen the project in RStudio with its Pixi R.
# An environment variable, as the project's .Rprofile replaces the personal
# one, so options set there don't apply.
offer_switch_enabled <- function() {
  !identical(tolower(Sys.getenv("RPIX_OFFER_SWITCH")), "false")
}

# Offer to reopen the project in a new RStudio with its Pixi R, and close this
# one
offer_pixi_r <- function(root) {
  if (!ask_yes_no("Reopen this project in a new RStudio, with its Pixi R?")) {
    cli::cli_alert_info(
      "Later, use {.strong Addins > Open with the project's Pixi R}. To stop this question, set {.envvar RPIX_OFFER_SWITCH=false} in {.file ~/.Renviron}."
    )
    return(invisible(FALSE))
  }
  environments <- pixi_environments(root)$name
  environment <- if (length(environments) == 1) environments
  if (is.null(pixi_switch(environment, ide = "rstudio", path = root))) {
    return(invisible(FALSE))
  }
  quit_session <- rstudio_api("executeCommand")
  if (!is.null(quit_session)) {
    quit_session("quitSession")
  }
  invisible(TRUE)
}

# Run a function once RStudio's session is ready, when its console can ask
when_rstudio_ready <- function(fun) {
  setHook(
    "rstudio.sessionInit",
    function(newSession) fun(),
    action = "append"
  )
}

# Whether the project also has renv
has_renv <- function(root) {
  file.exists(file.path(root, "renv", "activate.R"))
}

renv_clash_message <- function() {
  c(
    "!" = "This project also has renv, which clashes with Pixi: both manage the project's packages.",
    "i" = "Remove renv: delete the {.file renv} folder and {.file renv.lock}, and the line in {.file .Rprofile} that runs {.file renv/activate.R}.",
    "i" = "If RStudio's New Project added it, untick {.strong Use renv with this project} there once; RStudio applies it to all new projects, templates too."
  )
}
