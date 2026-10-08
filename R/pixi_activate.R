#' Activate the project's Pixi environment in the running R
#'
#' @description
#' Make R that was started directly from a Pixi environment, as IDEs such as
#' Positron and VS Code do, behave like R started with `pixi run R`. Called
#' from the project's `.Rprofile`, which [setup_pixi()] sets up.
#'
#' * If Pixi didn't activate the environment, its environment variables are
#'   set, as `pixi shell-hook` reports them. Some packages need them, e.g. to
#'   find their data.
#' * Your personal library is removed from `.libPaths()`, and the project's
#'   own library added if it exists. Other libraries, such as temporary ones
#'   that devtools adds, are kept.
#' * If R isn't the R of a Pixi environment in this project, nothing changes;
#'   in an interactive session you get a hint instead.
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
      if (is.null(env) || is.null(root) || !same_path(env$root, root)) {
        inform(c(
          "!" = "This R isn't from the project's Pixi environment, so it doesn't use the project's packages.",
          "i" = "Start R with {.code pixi run R}, or see {.url https://roald-arboel.com/rpix/articles/ide.html}."
        ))
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
        same_path(Sys.getenv("PIXI_PROJECT_ROOT"), root)

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
