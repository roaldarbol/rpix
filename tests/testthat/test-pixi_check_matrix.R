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

test_that("use_pixi_check_matrix() needs a package", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(require_project = function(path) dir)
  expect_error(use_pixi_check_matrix("4.4"), "no package here")
})

test_that("tests and R CMD check run in the environment's R", {
  skip_if_no_pixi()
  skip_if(is.null(pixi_r_location(r_home())), "not in a Pixi environment")
  root <- find_project_root()

  package <- withr::local_tempdir()
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

  tests <- suppressMessages(
    finish_run(start_run("default", "test", NULL, root, package))
  )
  expect_false(tests$ok)
  expect_equal(tests$r_version, as.character(getRversion()))
  expect_equal(c(tests$passed, tests$failed, tests$skipped), c(1L, 1L, 1L))
  expect_match(tests$output, "fails")

  unlink(file.path(package, "tests"), recursive = TRUE)
  # In this R, which has rcmdcheck too
  output <- capture.output(check <- run_check(package))
  # twice() isn't documented, and the licence needs a file
  expect_false(check$ok)
  expect_equal(c(check$errors, check$warnings, check$notes), c(0L, 1L, 1L))
  expect_match(paste(output, collapse = "\n"), "Undocumented code objects")
})

test_that("a task runs in the environment, and passes if it succeeds", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")
  run_pixi(c("task", "add", "hello", "echo hello"), path = dir)

  result <- suppressMessages(
    finish_run(start_run("default", "task", "hello", dir))
  )
  expect_true(result$ok)
  expect_match(result$output, "hello")
})
