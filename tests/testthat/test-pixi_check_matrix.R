# A finished run, as finish_run() returns it
fake_result <- function(environment, ok, ...) {
  c(
    list(r_version = "4.4.3", ok = ok),
    list(...),
    list(seconds = 1.5, output = paste("output of", environment))
  )
}

test_that("pixi_check_matrix() runs in each environment, one at a time", {
  local_mocked_bindings(
    require_project = function(path) "/project",
    pixi_environments = function(path) data.frame(name = c("r44", "r45")),
    start_run = function(environment, what, task, root) {
      list(environment = environment, what = what, root = root)
    },
    finish_run = function(job) {
      if (job$environment == "r44") {
        fake_result(
          "r44",
          TRUE,
          passed = 3L,
          failed = 0L,
          skipped = 1L,
          warnings = 0L
        )
      } else {
        list(ok = FALSE, seconds = 2, output = "R crashed")
      }
    }
  )

  expect_snapshot(matrix <- pixi_check_matrix())
  expect_equal(matrix$environment, c("r44", "r45"))
  expect_equal(matrix$r_version, c("4.4.3", NA))
  expect_equal(matrix$ok, c(TRUE, FALSE))
  expect_equal(matrix$passed, c(3L, NA))
  expect_equal(matrix$output, c("output of r44", "R crashed"))
  expect_equal(attr(matrix, "what"), "test")
  expect_snapshot(matrix)
})

test_that("pixi_check_matrix() can run everywhere at once, after installing", {
  calls <- local_recorded_pixi()
  started <- character()
  local_mocked_bindings(
    require_project = function(path) "/project",
    start_run = function(environment, what, task, root) {
      started <<- c(started, environment)
      list(environment = environment)
    },
    finish_run = function(job) {
      fake_result(job$environment, TRUE, errors = 0L, warnings = 0L, notes = 1L)
    }
  )

  expect_snapshot(
    matrix <- pixi_check_matrix(
      c("r44", "r45"),
      what = "check",
      parallel = TRUE
    )
  )
  expect_equal(
    calls$args,
    list(
      c("install", "--environment", "r44"),
      c("install", "--environment", "r45")
    )
  )
  expect_equal(started, c("r44", "r45"))
  expect_equal(matrix$notes, c(1L, 1L))
  expect_snapshot(matrix)
})

test_that("pixi_check_matrix() can run a task", {
  local_mocked_bindings(
    require_project = function(path) "/project",
    start_run = function(environment, what, task, root) {
      list(environment = environment, what = what, task = task)
    },
    finish_run = function(job) {
      expect_equal(job$what, "task")
      expect_equal(job$task, "lint")
      list(r_version = NA_character_, ok = TRUE, seconds = 75, output = "")
    }
  )
  expect_snapshot(matrix <- pixi_check_matrix("r44", task = "lint"))
  expect_named(
    matrix,
    c("environment", "r_version", "ok", "seconds", "output")
  )
  expect_snapshot(matrix)
})

# A job for finish_run(), with a process that's already running
local_job <- function(code, output = NULL, env = parent.frame()) {
  log <- withr::local_tempfile(.local_envir = env)
  list(
    environment = "r44",
    output = output,
    log = log,
    started = Sys.time(),
    process = processx::process$new(
      file.path(R.home("bin"), "Rscript"),
      c("-e", code),
      stdout = log,
      stderr = "2>&1"
    )
  )
}

test_that("finish_run() reads a task's exit status and output", {
  expect_snapshot(
    result <- finish_run(local_job("cat('done'); q(status = 1)")),
    transform = function(x) sub("\\(.*\\)", "(time)", x)
  )
  expect_false(result$ok)
  expect_match(result$output, "done")
  expect_true(is.na(result$r_version))

  result <- suppressMessages(finish_run(local_job("cat('done')")))
  expect_true(result$ok)
})

test_that("finish_run() reads the result, or the error, of a function", {
  output <- withr::local_tempfile()
  saveRDS(
    list(value = list(r_version = "4.4.3", ok = TRUE, passed = 2L)),
    output
  )
  result <- suppressMessages(finish_run(local_job("1", output)))
  expect_equal(result$passed, 2L)
  expect_equal(result$r_version, "4.4.3")

  saveRDS(list(error = "there is no package called 'testthat'"), output)
  result <- suppressMessages(finish_run(local_job("1", output)))
  expect_false(result$ok)
  expect_match(result$output, "no package called 'testthat'")

  # R stopped before saving a result
  result <- suppressMessages(
    finish_run(local_job("q(status = 1)", withr::local_tempfile()))
  )
  expect_false(result$ok)
})

test_that("the matrix prints as a data frame without the columns it needs", {
  matrix <- new_rpix_df(
    data.frame(environment = "r44", ok = TRUE),
    "rpix_check_matrix",
    what = "test"
  )
  expect_output(print(matrix), "r44")
})

test_that("format_seconds() uses seconds or minutes", {
  expect_equal(format_seconds(12.3), "12 s")
  expect_equal(format_seconds(90), "1.5 min")
})

test_that("use_pixi_check_matrix() adds an environment per version of R", {
  dir <- withr::local_tempdir()
  writeLines(
    c(
      "Package: demo",
      "Depends: R (>= 4.1), methods",
      "Imports: cli (>= 3.0), jsonlite",
      "Suggests:\n    testthat (>= 3.0.0),\n    knitr"
    ),
    file.path(dir, "DESCRIPTION")
  )
  added <- list()
  environments <- list()
  local_mocked_bindings(
    require_project = function(path) dir,
    pixi_add = function(packages, feature, path) {
      added[[feature]] <<- packages
    },
    pixi_add_environment = function(
      name,
      features,
      default_feature,
      overwrite,
      path
    ) {
      environments[[name]] <<- list(features, default_feature, overwrite)
    }
  )

  expect_snapshot(names <- use_pixi_check_matrix(c("4.4", "4.5")))
  expect_equal(names, c("r44", "r45"))
  expect_equal(
    added$r44,
    c(
      "r-base=4.4",
      "conda::conda-ecosystem-user-package-isolation",
      "cli",
      "jsonlite",
      "testthat",
      "knitr",
      "pkgload",
      "rcmdcheck"
    )
  )
  expect_equal(added$r45[1], "r-base=4.5")
  expect_equal(environments$r45, list("r45", FALSE, TRUE))
})

# A package project with a pixi.toml, and use_pixi_check_matrix()'s calls to
# Pixi recorded. `resolved` has the packages `pixi list` finds in each
# environment; it fails for the others. `fail` makes `pixi lock` fail: always
# if `TRUE`, or the first `fail` times.
local_minimum_project <- function(
  description = c(
    "Package: demo",
    "Depends: R (>= 4.1), methods",
    "Imports: cli (>= 3.0), rlang, limma (>= 3.50)",
    "LinkingTo: Rcpp",
    "Suggests: testthat (>= 3.0.0)"
  ),
  fail = FALSE,
  resolved = list(),
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(description, file.path(dir, "DESCRIPTION"))
  writeLines(
    c(
      "[workspace]",
      'channels = ["conda-forge"]',
      "",
      "[dependencies]",
      'r-base = "4.5.*"'
    ),
    file.path(dir, "pixi.toml")
  )
  calls <- new.env()
  calls$args <- list()
  calls$locks <- 0
  local_mocked_bindings(
    require_project = function(path) dir,
    find_r_packages = function(packages) {
      refs <- ifelse(
        packages == "limma",
        "bioc::limma",
        ifelse(packages == "nowhere", NA, paste0("cran::", packages))
      )
      stats::setNames(refs, packages)
    },
    project_channels = function(...) "conda-forge",
    pixi_add_environment = function(name, ...) {
      calls$args <- c(calls$args, list(c("environment", name)))
    },
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      if (args[1] == "list") {
        packages <- resolved[[args[3]]]
        if (is.null(packages)) {
          stop("no such environment")
        }
        return(packages)
      }
      if (args[1] == "lock") {
        calls$locks <- calls$locks + 1
        if (isTRUE(fail) || calls$locks <= fail) {
          stop("no solution")
        }
      }
      invisible(list(status = 0))
    },
    .env = env
  )
  calls$dir <- dir
  calls
}

test_that("use_pixi_check_matrix() adds a minimum-versions environment", {
  calls <- local_minimum_project()
  expect_snapshot(names <- use_pixi_check_matrix(minimum = TRUE))
  expect_equal(names, "minimum")

  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  feature <- lines[seq(match("[feature.minimum]", lines), length(lines))]
  expect_true('solve-strategy = "lowest-direct"' %in% feature)
  expect_true(all(
    c(
      'r-base = ">=4.1"',
      'conda-ecosystem-user-package-isolation = "*"',
      'r-cli = ">=3.0"',
      'r-rlang = "*"',
      'r-rcpp = "*"',
      'bioconductor-limma = { version = ">=3.50", channel = "bioconda" }',
      'r-testthat = ">=3.1.0"',
      'r-pkgload = ">=1.3.0"',
      'r-rcmdcheck = ">=1.4.0"'
    ) %in%
      feature
  ))
  # bioconda is added, the environment set up, and Pixi solves it
  expect_equal(
    calls$args[[1]][1:4],
    c("workspace", "channel", "add", "bioconda")
  )
  expect_equal(calls$args[[2]], c("environment", "minimum"))
  expect_equal(calls$args[[3]], "lock")

  # Again replaces it, rather than adding a second one
  suppressMessages(use_pixi_check_matrix(minimum = TRUE))
  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_equal(sum(lines == "[feature.minimum]"), 1)
  expect_equal(sum(lines == "[feature.minimum.dependencies]"), 1)
})

# The minimum feature's lines in pixi.toml
minimum_feature <- function(dir) {
  lines <- readLines(file.path(dir, "pixi.toml"))
  lines[seq(match("[feature.minimum.dependencies]", lines), length(lines))]
}

test_that("the minimum environment has the Suggests, at recent minimums", {
  calls <- local_minimum_project(
    c(
      "Package: demo",
      "Depends: R (>= 4.1)",
      "Imports: cli (>= 3.0)",
      paste(
        "Suggests: testthat (>= 3.2.0), pkgload, cli, knitr (>= 1.40),",
        "withr, limma, covr, nowhere, tools"
      )
    ),
    resolved = list(
      test = data.frame(
        name = c("r-withr", "bioconductor-limma", "r-knitr"),
        version = c("3.0.2", "3.62.1", "1.50")
      )
    )
  )
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE))
  feature <- minimum_feature(calls$dir)
  expect_true(all(
    c(
      # A minimum in DESCRIPTION
      'r-knitr = ">=1.40"',
      # None: the version the test environment has
      'r-withr = ">=3.0.2"',
      'bioconductor-limma = { version = ">=3.62.1", channel = "bioconda" }',
      # Nowhere in the project
      'r-covr = "*"',
      # The check tools: the higher minimum
      'r-testthat = ">=3.2.0"',
      'r-pkgload = ">=1.3.0"',
      # A hard dependency's minimum wins
      'r-cli = ">=3.0"'
    ) %in%
      feature
  ))
  expect_equal(sum(startsWith(feature, "r-cli ")), 1)
  expect_equal(sum(startsWith(feature, "r-testthat ")), 1)
  expect_false(any(grepl("nowhere|r-tools", feature)))
  expect_equal(
    calls$args[[1]],
    c("list", "--environment", "test", "--no-install")
  )
})

test_that("the Suggests' versions come from the default environment, or none", {
  description <- c(
    "Package: demo",
    "Depends: R (>= 4.1)",
    "Suggests: withr"
  )
  calls <- local_minimum_project(
    description,
    resolved = list(default = data.frame(name = "r-withr", version = "3.0.1"))
  )
  suppressMessages(use_pixi_check_matrix(minimum = TRUE))
  expect_true('r-withr = ">=3.0.1"' %in% minimum_feature(calls$dir))
  expect_equal(
    vapply(calls$args[1:2], `[`, character(1), 3),
    c("test", "default")
  )

  calls <- local_minimum_project(description)
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE))
  expect_true('r-withr = "*"' %in% minimum_feature(calls$dir))
})

test_that("the Suggests get the oldest versions if the project's don't solve", {
  description <- c(
    "Package: demo",
    "Depends: R (>= 4.1)",
    "Suggests: withr, knitr (>= 1.40)"
  )
  resolved <- list(test = data.frame(name = "r-withr", version = "3.0.2"))
  calls <- local_minimum_project(description, fail = 1, resolved = resolved)
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE))
  feature <- minimum_feature(calls$dir)
  expect_true(all(
    c('r-withr = "*"', 'r-knitr = ">=1.40"', 'r-testthat = ">=3.1.0"') %in%
      feature
  ))
  expect_equal(sum(feature == "[feature.minimum.dependencies]"), 1)
  expect_equal(calls$locks, 2)

  # If that fails too, pixi.toml is put back
  calls <- local_minimum_project(description, fail = TRUE, resolved = resolved)
  before <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE), error = TRUE)
  expect_equal(readLines(file.path(calls$dir, "pixi.toml")), before)
  expect_equal(calls$locks, 2)
})

test_that("higher_minimum() keeps the higher minimum", {
  expect_equal(higher_minimum(">=3.1.0", ">=3.2.0"), ">=3.2.0")
  expect_equal(higher_minimum(">=3.1.0", ">=3.0.0"), ">=3.1.0")
  expect_equal(higher_minimum(">=1.4.0", ">=1.4.0_1"), ">=1.4.0_1")
  expect_equal(higher_minimum(">=1.3.0", ""), ">=1.3.0")
  expect_equal(higher_minimum(">=1.3.0", "==2.0"), ">=1.3.0")
})

test_that("the minimum environment takes R from r_versions or the project", {
  calls <- local_minimum_project(c("Package: demo", "Imports: cli"))
  suppressMessages(use_pixi_check_matrix(minimum = TRUE))
  expect_true(
    'r-base = "4.5.*"' %in% readLines(file.path(calls$dir, "pixi.toml"))
  )

  local_mocked_bindings(pixi_add = function(...) NULL)
  suppressMessages(use_pixi_check_matrix(c("4.5", "4.3"), minimum = TRUE))
  expect_true(
    'r-base = ">=4.3"' %in% readLines(file.path(calls$dir, "pixi.toml"))
  )
})

test_that("the minimum environment leaves out packages it can't find", {
  calls <- local_minimum_project(c(
    "Package: demo",
    "Depends: R (>= 4.1)",
    "Imports: nowhere (>= 1.0)"
  ))
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE))
  expect_false(any(grepl(
    "nowhere",
    readLines(file.path(calls$dir, "pixi.toml"))
  )))
})

test_that("use_pixi_check_matrix() puts pixi.toml back if Pixi can't solve it", {
  calls <- local_minimum_project(fail = TRUE)
  before <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_snapshot(use_pixi_check_matrix(minimum = TRUE), error = TRUE)
  expect_equal(readLines(file.path(calls$dir, "pixi.toml")), before)
})

test_that("use_pixi_check_matrix() needs R versions or minimum, and a pixi.toml", {
  calls <- local_minimum_project()
  expect_error(use_pixi_check_matrix(), "r_versions")
  file.remove(file.path(calls$dir, "pixi.toml"))
  writeLines("[tool.pixi.workspace]", file.path(calls$dir, "pyproject.toml"))
  expect_error(use_pixi_check_matrix(minimum = TRUE), "pixi.toml")
})

test_that("remove_table() removes a table and its lines", {
  lines <- c("[workspace]", "x = 1", "", "[feature.a]", "y = 2", "", "[tasks]")
  expect_equal(
    remove_table(lines, "feature.a"),
    c("[workspace]", "x = 1", "", "[tasks]")
  )
  expect_identical(remove_table(lines, "feature.b"), lines)
})

test_that("use_pixi_check_matrix() needs a package", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(require_project = function(path) dir)
  expect_error(use_pixi_check_matrix("4.4"), "no package here")
})

# A package with a passing, a failing and a skipped test
local_demo_package <- function(env = parent.frame()) {
  package <- withr::local_tempdir(.local_envir = env)
  dir.create(file.path(package, "R"))
  dir.create(file.path(package, "tests", "testthat"), recursive = TRUE)
  writeLines(
    c(
      "Package: demo",
      "Version: 0.0.1",
      "Title: Demo",
      "Description: A demo.",
      "License: MIT",
      "Authors@R: person('A', 'B', email = 'a@b.c', role = c('aut', 'cre'))",
      "Encoding: UTF-8",
      "Suggests: testthat (>= 3.0.0)",
      "Config/testthat/edition: 3"
    ),
    file.path(package, "DESCRIPTION")
  )
  writeLines("export(twice)", file.path(package, "NAMESPACE"))
  writeLines("twice <- function(x) x * 2", file.path(package, "R", "twice.R"))
  writeLines(
    c("library(testthat)", "library(demo)", "test_check('demo')"),
    file.path(package, "tests", "testthat.R")
  )
  writeLines(
    c(
      "test_that('doubles', expect_equal(twice(2), 4))",
      "test_that('fails', expect_equal(twice(2), 5))",
      "test_that('skips', skip('not now'))"
    ),
    file.path(package, "tests", "testthat", "test-twice.R")
  )
  package
}

test_that("run_job() runs the tests or check without rpix, or a task", {
  job <- run_job("r44", "test", NULL, "/package")
  withr::defer(unlink(job$dir, recursive = TRUE))
  expect_equal(job$args[1:4], c("run", "--environment", "r44", "Rscript"))
  input <- readRDS(file.path(job$dir, "input.rds"))
  expect_identical(environment(input$func), globalenv())
  expect_identical(body(input$func), body(run_tests))
  expect_equal(input$args, list("/package"))

  job <- run_job("r44", "check", NULL, "/package")
  withr::defer(unlink(job$dir, recursive = TRUE))
  expect_identical(
    body(readRDS(file.path(job$dir, "input.rds"))$func),
    body(run_check)
  )

  expect_equal(
    run_job("r44", "task", "lint", "/package"),
    list(args = c("run", "--environment", "r44", "lint"))
  )
})

test_that("run_tests() and run_check() summarise the results", {
  # It runs R CMD check, which is too slow for CRAN
  skip_on_cran()
  skip_if_not_installed("rcmdcheck")
  # Without the settings of an R CMD check this runs in, e.g. --as-cran's,
  # which would give the demo package more notes and warnings
  outer <- grep("^_R_CHECK_", names(Sys.getenv()), value = TRUE)
  withr::local_envvar(stats::setNames(rep(NA, length(outer)), outer))
  package <- local_demo_package()
  # The tests load the package; don't leave it behind
  withr::defer(if (isNamespaceLoaded("demo")) unloadNamespace("demo"))

  output <- capture.output(tests <- run_tests(package))
  expect_false(tests$ok)
  expect_equal(tests$r_version, as.character(getRversion()))
  expect_equal(c(tests$passed, tests$failed, tests$skipped), c(1L, 1L, 1L))

  unlink(file.path(package, "tests"), recursive = TRUE)
  output <- capture.output(check <- run_check(package))
  # twice() isn't documented, and the licence needs a file
  expect_false(check$ok)
  expect_equal(c(check$errors, check$warnings, check$notes), c(0L, 1L, 1L))
  expect_match(paste(output, collapse = "\n"), "Undocumented code objects")
})

test_that("the tests run in the environment's R", {
  skip_if_no_pixi()
  here <- pixi_r_location(r_home())
  skip_if(is.null(here), "not in a Pixi environment")

  # The environment these tests run in, which needn't be the default one
  tests <- suppressMessages(finish_run(start_run(
    here$name,
    "test",
    NULL,
    find_project_root(),
    local_demo_package()
  )))
  expect_false(tests$ok)
  expect_equal(tests$r_version, as.character(getRversion()))
  expect_match(tests$output, "fails")
})

test_that("a task runs in the environment, and passes if it succeeds", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")
  run_pixi(c("task", "add", "hello", "echo hello"), path = dir)

  result <- suppressMessages(
    finish_run(start_run("default", "task", "hello", dir))
  )
  expect_true(result$ok)
  expect_match(result$output, "hello")
})
