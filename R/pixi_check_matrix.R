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
#'   those packages, named after the version: `r44` for R 4.4. With
#'   `minimum = TRUE`, it also adds a `minimum` environment, with the oldest
#'   versions the package's `DESCRIPTION` allows.
#'
#' @section The `minimum` environment:
#' Checks that the minimum versions in `DESCRIPTION` really work: R at the
#' version `Depends` asks for, and each package in `Depends`, `Imports`,
#' `LinkingTo` and `Suggests` at the lowest version its constraint allows
#' (Pixi's `solve-strategy = "lowest-direct"`; their own dependencies are the
#' newest that fit).
#'
#' * A package in `Depends`, `Imports` or `LinkingTo` without a minimum gets
#'   the oldest version on conda-forge for that R, which may be much older
#'   than you meant; rpix lists them.
#' * A `Suggests` without a minimum isn't what's tested, so it gets at least
#'   the version the project has, in its `test` environment or else the
#'   default one. rpix lists those the project doesn't have, which get the
#'   oldest version, as do the others if those versions don't solve for that
#'   R.
#' * testthat, pkgload and rcmdcheck, which run the checks, get recent
#'   minimums, or a higher one from `DESCRIPTION`.
#' * Without a minimum R in `Depends`, it uses the oldest of `r_versions`, or
#'   the project's R.
#' * Only versions on conda-forge (and bioconda) count, for the project's
#'   platforms. An old build's own dependencies are as conda-forge recorded
#'   them, which for old builds is sometimes looser than its `DESCRIPTION`:
#'   then R refuses to load it, although Pixi installed it.
#'
#' @param environments Optional. The environments. Defaults to all of them.
#' @param what `"test"` to run the tests with `testthat::test_local()`, or
#'   `"check"` to run `R CMD check` with `rcmdcheck::rcmdcheck()`.
#' @param task Optional. A Pixi task to run instead, such as `"check"`. It
#'   passes if it succeeds.
#' @param parallel If `TRUE`, run in all environments at once.
#' @param r_versions Versions of R, such as `"4.4"`. Optional with
#'   `minimum = TRUE`.
#' @param minimum If `TRUE`, also add a `minimum` environment; see below.
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
#' use_pixi_check_matrix(minimum = TRUE)
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
      install_environment(environment, root)
    }
    cli::cli_alert_info(
      "Running in {length(environments)} environment{?s} at once."
    )
    runs <- lapply(environments, start_run, what, task, root)
    results <- lapply(runs, finish_run)
  } else {
    results <- lapply(environments, function(environment) {
      # Install it before the run, whose output goes to its log
      install_environment(environment, root)
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
use_pixi_check_matrix <- function(
  r_versions = NULL,
  minimum = FALSE,
  path = NULL
) {
  root <- require_project(path)
  if (length(r_versions) == 0 && !minimum) {
    cli::cli_abort("Give {.arg r_versions}, or {.code minimum = TRUE}.")
  }
  packages <- c(
    package_dependencies(file.path(root, "DESCRIPTION")),
    "testthat",
    "pkgload",
    "rcmdcheck"
  )
  names <- character()
  if (length(r_versions) > 0) {
    names <- paste0("r", gsub(".", "", r_versions, fixed = TRUE))
  }
  for (i in seq_along(r_versions)) {
    # Without the default feature, the environments need their own isolation
    # from the personal library, or R loads packages built for another R
    pixi_add(
      c(
        paste0("r-base=", r_versions[i]),
        paste0("conda::", isolation_package),
        unique(packages)
      ),
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
  if (minimum) {
    names <- c(names, add_minimum_environment(root, r_versions))
  }
  cli::cli_alert_success(
    "Added the environment{?s} {.val {names}}. Run {.code rpix::pixi_check_matrix()}."
  )
  invisible(names)
}

# The tools that run the checks, at recent minimums: they aren't what's tested
check_tools <- c(
  testthat = ">=3.1.0",
  pkgload = ">=1.3.0",
  rcmdcheck = ">=1.4.0"
)

# Add the `minimum` environment: R and the hard dependencies at the lowest
# versions DESCRIPTION allows, and the Suggests and check tools at recent ones
add_minimum_environment <- function(root, r_versions = NULL) {
  deps <- description_dependencies(file.path(root, "DESCRIPTION"))
  hard <- deps[deps$field %in% c("Depends", "Imports", "LinkingTo"), ]
  r_row <- hard[hard$package == "R" & nzchar(hard$constraint), ]
  hard <- hard[!hard$package %in% c("R", base_packages()), ]
  hard <- hard[!duplicated(hard$package), ]
  suggested <- deps[
    deps$field == "Suggests" &
      !deps$package %in% c(hard$package, base_packages()),
  ]
  suggested <- suggested[!duplicated(suggested$package), ]

  manifest <- find_manifest(root)
  if (basename(manifest) != "pixi.toml") {
    cli::cli_abort(
      "The {.val minimum} environment needs a {.file pixi.toml} manifest.",
      call = NULL
    )
  }
  lines <- readLines(manifest, warn = FALSE)
  r_base <- if (nrow(r_row) > 0) {
    r_row$constraint[1]
  } else if (length(r_versions) > 0) {
    oldest <- r_versions[order(package_version(r_versions))][1]
    paste0(">=", oldest)
  } else {
    manifest_r_base(lines) %||% "*"
  }
  if (nrow(r_row) == 0) {
    cli::cli_alert_info(
      "{.file DESCRIPTION} has no minimum R in {.field Depends}, so the {.val minimum} environment uses {.code r-base {r_base}}."
    )
  }

  tools <- check_tools[!names(check_tools) %in% hard$package]
  # A check tool in Suggests keeps the higher of the two minimums
  for (tool in intersect(names(tools), suggested$package)) {
    tools[[tool]] <- higher_minimum(
      tools[[tool]],
      suggested$constraint[suggested$package == tool]
    )
  }
  suggested <- suggested[!suggested$package %in% names(tools), ]
  packages <- c(hard$package, suggested$package, names(tools))
  constraints <- c(hard$constraint, suggested$constraint, unname(tools))
  refs <- find_r_packages(packages)[packages]
  found <- !is.na(refs)
  bioc <- found & startsWith(refs, "bioc::")
  conda <- ifelse(
    bioc,
    paste0("bioconductor-", tolower(packages)),
    paste0("r-", tolower(packages))
  )

  missing <- packages[!found]
  if (length(missing) > 0) {
    cli::cli_alert_warning(
      "{.pkg {missing}} {?isn't/aren't} on conda-forge or bioconda, so the {.val minimum} environment leaves {?it/them} out."
    )
  }
  unpinned <- hard$package[
    !nzchar(hard$constraint) & !hard$package %in% missing
  ]
  if (length(unpinned) > 0) {
    cli::cli_alert_warning(
      "{.pkg {unpinned}} {?has/have} no minimum version in {.file DESCRIPTION}, so {?it gets/they get} the oldest version on conda-forge for that R."
    )
  }

  # Suggests without a minimum: at least the version the project has
  loose <- found & packages %in% suggested$package & !nzchar(constraints)
  floored <- rep(FALSE, length(packages))
  if (any(loose)) {
    versions <- project_versions(root)[conda[loose]]
    constraints[loose] <- ifelse(is.na(versions), "", paste0(">=", versions))
    floored[loose] <- !is.na(versions)
    unresolved <- packages[loose][is.na(versions)]
    if (length(unresolved) > 0) {
      cli::cli_alert_warning(
        "{.pkg {unresolved}} {?has/have} no minimum version in {.file DESCRIPTION}, and the project doesn't have {?it/them}, so {?it gets/they get} the oldest version on conda-forge for that R."
      )
    }
  }
  constraints[!nzchar(constraints)] <- "*"

  bioc <- bioc[found]
  conda <- conda[found]
  constraints <- constraints[found]
  floored <- floored[found]
  original <- lines

  # Write the feature, and solve it
  solve <- function(constraints) {
    entries <- ifelse(
      bioc,
      paste0(
        toml_key(conda),
        ' = { version = "',
        constraints,
        '", channel = "bioconda" }'
      ),
      paste0(toml_key(conda), ' = "', constraints, '"')
    )
    lines <- remove_table(original, "feature.minimum.dependencies")
    lines <- remove_table(lines, "feature.minimum")
    lines <- set_dependency(
      lines,
      "feature.minimum",
      "solve-strategy",
      'solve-strategy = "lowest-direct"'
    )
    lines <- set_dependency(
      lines,
      "feature.minimum.dependencies",
      "r-base",
      paste0('r-base = "', r_base, '"')
    )
    lines <- set_dependency(
      lines,
      "feature.minimum.dependencies",
      isolation_package,
      paste0(isolation_package, ' = "*"')
    )
    for (i in seq_along(conda)) {
      lines <- set_dependency(
        lines,
        "feature.minimum.dependencies",
        conda[i],
        entries[i]
      )
    }
    writeLines(lines, manifest)
    tryCatch(
      {
        if (any(bioc) && !"bioconda" %in% project_channels(root)) {
          run_pixi(
            c("workspace", "channel", "add", "bioconda", "--no-install"),
            path = root,
            echo = TRUE
          )
        }
        pixi_add_environment(
          "minimum",
          features = "minimum",
          default_feature = FALSE,
          overwrite = TRUE,
          path = root
        )
        run_pixi("lock", path = root, echo = TRUE)
        NULL
      },
      error = function(e) e
    )
  }

  error <- solve(constraints)
  # The project's versions of the Suggests may not be built for that R
  if (!is.null(error) && any(floored)) {
    cli::cli_alert_warning(
      "Pixi couldn't solve the {.val minimum} environment with {.pkg {packages[found][floored]}} at the project's version{?s}, which may not be built for {.code r-base {r_base}}, so {cli::qty(sum(floored))}{?it gets/they get} the oldest version on conda-forge instead."
    )
    constraints[floored] <- "*"
    error <- solve(constraints)
  }
  if (!is.null(error)) {
    writeLines(original, manifest)
    cli::cli_abort(
      c(
        "Pixi couldn't solve the {.val minimum} environment, so {.file pixi.toml} is as it was.",
        "i" = "The lowest versions {.file DESCRIPTION} allows may not be on conda-forge for that R, or for all the project's platforms. See Pixi's output above."
      ),
      parent = error,
      call = NULL
    )
  }
  "minimum"
}

# The higher of two minimums, such as ">=3.1.0"; a constraint that isn't a
# minimum loses
higher_minimum <- function(constraint, other) {
  minimum <- function(x) {
    if (!startsWith(x, ">=")) {
      return(NA)
    }
    package_version(gsub("_", ".", substring(x, 3)), strict = FALSE)
  }
  ours <- minimum(constraint)
  theirs <- minimum(other)
  if (!is.na(theirs) && theirs > ours) other else constraint
}

# The versions the project's packages resolve to, by conda name: in the `test`
# environment, which has the Suggests, or else the default one. Read from
# pixi.lock, which Pixi updates if need be, without installing.
project_versions <- function(root) {
  for (environment in c("test", "default")) {
    packages <- tryCatch(
      run_pixi(
        c("list", "--environment", environment, "--no-install"),
        path = root,
        json = TRUE
      ),
      error = function(e) NULL
    )
    if (length(packages) > 0) {
      return(stats::setNames(packages$version, packages$name))
    }
  }
  character()
}

# Remove a TOML table, header and all
remove_table <- function(lines, table) {
  rows <- table_lines(lines, table)
  if (is.null(rows)) {
    return(lines)
  }
  lines <- lines[-rows]
  # Don't leave two blank lines behind
  blank <- !nzchar(trimws(lines))
  lines[!(blank & c(FALSE, utils::head(blank, -1)))]
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
