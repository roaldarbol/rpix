test_that("exclude_newer_value() takes dates, timestamps and durations", {
  expect_equal(exclude_newer_value(as.Date("2025-06-01")), "2025-06-01")
  expect_equal(exclude_newer_value("2025-06-01"), "2025-06-01")
  expect_equal(
    exclude_newer_value("2025-06-01T12:00:00Z"),
    "2025-06-01T12:00:00Z"
  )
  expect_equal(exclude_newer_value("7d"), "7d")
  expect_equal(exclude_newer_value("1h30m"), "1h30m")
  expect_null(exclude_newer_value(NULL))
  expect_snapshot(exclude_newer_value("last summer"), error = TRUE)
  expect_error(exclude_newer_value("2025-13-45"), "must be a date")
  expect_error(exclude_newer_value(c("7d", "1d")), "must be a date")
})

test_that("set_exclude_newer() adds, replaces and removes the setting", {
  lines <- c("[workspace]", 'name = "x"', "", "[dependencies]")
  lines <- set_exclude_newer(lines, "2025-06-01")
  expect_equal(lines[3], 'exclude-newer = "2025-06-01"')
  expect_equal(manifest_exclude_newer(lines), "2025-06-01")

  lines <- set_exclude_newer(lines, "7d")
  expect_equal(sum(grepl("exclude-newer", lines)), 1)
  expect_equal(manifest_exclude_newer(lines), "7d")

  lines <- set_exclude_newer(lines, NULL)
  expect_null(manifest_exclude_newer(lines))
  expect_identical(set_exclude_newer(lines, NULL), lines)

  # In [project], or with no table yet
  expect_equal(
    manifest_exclude_newer(set_exclude_newer("[project]", "7d")),
    "7d"
  )
  expect_equal(
    set_exclude_newer("[tasks]", "7d")[1:2],
    c("[workspace]", 'exclude-newer = "7d"')
  )
})

test_that("is_absolute_date() tells dates from durations", {
  expect_true(is_absolute_date("2025-06-01"))
  expect_true(is_absolute_date("2025-06-01T12:00:00Z"))
  expect_false(is_absolute_date("7d"))
  expect_false(is_absolute_date(NULL))
})

local_date_project <- function(fail = FALSE, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(
    c("[workspace]", 'name = "x"', "", "[dependencies]", 'r-base = "4.5.*"'),
    file.path(dir, "pixi.toml")
  )
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      if (fail) {
        stop("no solution")
      }
      invisible(list(status = 0))
    },
    .env = env
  )
  calls$dir <- dir
  calls
}

test_that("pixi_set_date() sets the date and updates pixi.lock", {
  calls <- local_date_project()
  expect_snapshot(previous <- pixi_set_date("2025-06-01", path = calls$dir))
  expect_null(previous)
  expect_equal(calls$args, list("update"))
  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_true('exclude-newer = "2025-06-01"' %in% lines)

  # NULL removes it, and leaves the packages as they are
  expect_snapshot(previous <- pixi_set_date(NULL, path = calls$dir))
  expect_equal(previous, "2025-06-01")
  expect_length(calls$args, 1)
  expect_false(any(grepl(
    "exclude-newer",
    readLines(file.path(calls$dir, "pixi.toml"))
  )))
})

test_that("pixi_set_date() puts pixi.toml back if Pixi can't solve it", {
  calls <- local_date_project(fail = TRUE)
  before <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_snapshot(pixi_set_date("2020-01-01", path = calls$dir), error = TRUE)
  expect_equal(readLines(file.path(calls$dir, "pixi.toml")), before)
})

test_that("pixi_set_date() needs a pixi.toml", {
  dir <- withr::local_tempdir()
  writeLines("[tool.pixi.workspace]", file.path(dir, "pyproject.toml"))
  expect_error(pixi_set_date("7d", path = dir), "pixi.toml")
})

test_that("pixi_set_date(NULL) offers to update the packages", {
  calls <- local_date_project()
  writeLines(
    c("[workspace]", 'exclude-newer = "2025-06-01"'),
    file.path(calls$dir, "pixi.toml")
  )
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_yes_no = function(question) TRUE,
    pixi_update = function(path) calls$updated <- path
  )
  suppressMessages(pixi_set_date(NULL, path = calls$dir))
  expect_true(same_path(calls$updated, calls$dir))
})
