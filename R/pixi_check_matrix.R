#' Test a package in several environments
#'
#' @description
#' For package developers: run the tests or `R CMD check` in several of the
#' project's environments, e.g. one for each version of R, and see the results
#' side by side.
#'
#' * `pixi_check_matrix()` runs them. Each environment needs the package's
#'   dependencies, and testthat and pkgload for the tests, or rcmdcheck for
#'   `R CMD check`.
#' * `use_pixi_check_matrix()` adds an environment for each version of R, with
#'   those packages, named after the version: `r44` for R 4.4.
#'
#' @param environments Optional. The environments. Defaults to all of them.
#' @param what `"test"` to run the tests with `testthat::test_local()`, or
#'   `"check"` to run `R CMD check` with `rcmdcheck::rcmdcheck()`.
#' @param task Optional. A Pixi task to run instead, such as `"check"`. It
#'   passes if it succeeds.
#' @param parallel If `TRUE`, run in all environments at once.
#' @param r_versions Versions of R, such as `"4.4"`.
#' @inheritParams pixi_environments
#' @returns
#' * `pixi_check_matrix()`: a data frame with a row per environment, and the
#'   columns `environment`, `r_version`, `ok`, the counts (`passed`, `failed`,
#'   `skipped` and `warnings` for tests; `errors`, `warnings` and `notes` for
#'   `R CMD check`), `seconds`, and `output`: what it printed.
#' * `use_pixi_check_matrix()`: the names of the environments, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi_check_matrix(c("4.3", "4.4", "4.5"))
#' pixi_check_matrix()
#' pixi_check_matrix(what = "check", parallel = TRUE)
#' }
pixi_check_matrix <- function(
  environments = NULL,
  what = c("test", "check"),
  task = NULL,
  parallel = FALSE,
  path = NULL
) {
  what <- if (is.null(task)) match.arg(what) else "task"
  root <- require_project(path)
  environments <- environments %||% pixi_environments(root)$name

  if (parallel) {
    # Install first, so the runs don't all install at once
    for (environment in environments) {
      run_pixi(c("install", "--environment", environment), path = root)
    }
    cli::cli_alert_info(
      "Running in {length(environments)} environment{?s} at once."
    )
    runs <- lapply(environments, start_run, what, task, root)
    results <- lapply(runs, finish_run)
  } else {
    results <- lapply(environments, function(environment) {
      cli::cli_alert_info("Running in {.val {environment}}.")
      finish_run(start_run(environment, what, task, root))
    })
  }

  column <- function(name, type) {
    vapply(results, function(r) r[[name]] %||% type[NA], type)
  }
  matrix <- data.frame(
    environment = environments,
    r_version = column("r_version", character(1)),
    ok = column("ok", logical(1)),
    stringsAsFactors = FALSE
  )
  for (count in check_counts[[what]]) {
    matrix[[count]] <- column(count, integer(1))
  }
  matrix$seconds <- column("seconds", numeric(1))
  matrix$output <- column("output", character(1))
  new_rpix_df(matrix, "rpix_check_matrix", what = what)
}

check_counts <- list(
  test = c("passed", "failed", "skipped", "warnings"),
  check = c("errors", "warnings", "notes"),
  task = character()
)

#' @rdname pixi_check_matrix
#' @export
use_pixi_check_matrix <- function(r_versions, path = NULL) {
  root <- require_project(path)
  packages <- c(
    package_dependencies(file.path(root, "DESCRIPTION")),
    "testthat",
    "pkgload",
    "rcmdcheck"
  )
  names <- paste0("r", gsub(".", "", r_versions, fixed = TRUE))
  for (i in seq_along(r_versions)) {
    pixi_add(
      c(paste0("r-base=", r_versions[i]), unique(packages)),
      feature = names[i],
      path = root
    )
    pixi_add_environment(
      names[i],
      features = names[i],
      default_feature = FALSE,
      overwrite = TRUE,
      path = root
    )
  }
  cli::cli_alert_success(
    "Added the environment{?s} {.val {names}}. Run {.code pixi_check_matrix()}."
  )
  invisible(names)
}

# Start a run in an environment, in the background
start_run <- function(environment, what, task, root, package = root) {
  job <- run_job(environment, what, task, package)
  job$environment <- environment
  job$log <- tempfile("rpix-run-", fileext = ".log")
  job$started <- Sys.time()
  job$process <- processx::process$new(
    pixi_binary(),
    add_manifest_arg(job$args, find_manifest(root)),
    stdout = job$log,
    stderr = "2>&1",
    env = pixi_env("never")
  )
  job
}

# What a run runs: a task, or a function in the environment's R
run_job <- function(environment, what, task, package) {
  if (what == "task") {
    return(list(args = c("run", "--environment", environment, task)))
  }
  func <- if (what == "test") run_tests else run_check
  # Run without rpix, which the environment may not have
  environment(func) <- globalenv()
  pixi_r_job(func, list(package), environment)
}

# Wait for a run to finish, and summarise it
finish_run <- function(job) {
  job$process$wait()
  on.exit(unlink(c(job$dir, job$log), recursive = TRUE), add = TRUE)
  output <- paste(readLines(job$log, warn = FALSE), collapse = "\n")
  seconds <- as.numeric(difftime(Sys.time(), job$started, units = "secs"))

  result <- if (is.null(job$output)) {
    list(r_version = NA_character_, ok = job$process$get_exit_status() == 0)
  } else if (file.exists(job$output)) {
    value <- readRDS(job$output)
    if (is.null(value$error)) {
      value$value
    } else {
      output <- paste(output, value$error, sep = "\n")
      list(r_version = NA_character_, ok = FALSE)
    }
  } else {
    # R didn't get as far as saving a result
    list(r_version = NA_character_, ok = FALSE)
  }

  if (result$ok) {
    cli::cli_alert_success(
      "{.val {job$environment}} passed ({format_seconds(seconds)})."
    )
  } else {
    cli::cli_alert_danger(
      "{.val {job$environment}} failed ({format_seconds(seconds)})."
    )
  }
  c(result, list(seconds = round(seconds, 1), output = output))
}

format_seconds <- function(seconds) {
  if (seconds < 60) {
    paste0(round(seconds), " s")
  } else {
    paste0(round(seconds / 60, 1), " min")
  }
}

# These run in the environment's R, so they only use what's there

run_tests <- function(package) {
  results <- as.data.frame(testthat::test_local(
    package,
    reporter = "summary",
    stop_on_failure = FALSE
  ))
  failed <- sum(results$failed) + sum(results$error)
  list(
    r_version = as.character(getRversion()),
    ok = failed == 0,
    passed = as.integer(sum(results$passed)),
    failed = as.integer(failed),
    skipped = as.integer(sum(results$skipped)),
    warnings = as.integer(sum(results$warning))
  )
}

run_check <- function(package) {
  check <- rcmdcheck::rcmdcheck(
    package,
    args = "--no-manual",
    error_on = "never",
    quiet = TRUE
  )
  print(check)
  list(
    r_version = as.character(getRversion()),
    ok = length(check$errors) == 0 && length(check$warnings) == 0,
    errors = length(check$errors),
    warnings = length(check$warnings),
    notes = length(check$notes)
  )
}
