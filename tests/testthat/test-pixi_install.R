test_that("installs the changed environment when the project has several", {
  root <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  calls <- local_recorded_pixi()
  environments <- data.frame(
    name = c("default", "r44"),
    features = I(list("default", "r44"))
  )
  local_mocked_bindings(
    pixi_environments = function(path) environments,
    r_home = function() "/Library/Frameworks/R.framework/Resources"
  )
  withr::local_envvar(PIXI_NO_INSTALL = NA)

  # Not in a Pixi R: the default environment, if the change is for it
  expect_message(install_changed_environment(path = root), "doesn't by itself")
  expect_equal(calls$args[[1]], c("install", "--environment", "default"))
  expect_null(install_changed_environment("r44", path = root))
  expect_length(calls$args, 1)

  # In the project's r44 environment: that one, for its feature
  local_mocked_bindings(
    r_home = function() file.path(root, ".pixi", "envs", "r44", "lib", "R")
  )
  suppressMessages(install_changed_environment("r44", path = root))
  expect_equal(calls$args[[2]], c("install", "--environment", "r44"))
  expect_null(install_changed_environment(path = root))
  expect_length(calls$args, 2)

  # Not with one environment, Pixi's --no-install, or unknown environments
  environments <- environments[1, ]
  expect_null(install_changed_environment(path = root))
  withr::local_envvar(PIXI_NO_INSTALL = "true")
  environments <- data.frame(
    name = c("default", "r44"),
    features = I(list("default", "r44"))
  )
  expect_null(install_changed_environment(path = root))
  withr::local_envvar(PIXI_NO_INSTALL = NA)
  local_mocked_bindings(pixi_environments = function(path) stop("no pixi"))
  expect_null(install_changed_environment(path = root))
  expect_length(calls$args, 2)
})

test_that("pixi_add() and pixi_remove() install the changed environment", {
  calls <- local_recorded_pixi()
  installed <- list()
  local_mocked_bindings(
    install_changed_environment = function(feature = NULL, path = NULL) {
      installed <<- c(installed, list(feature %||% "default"))
      NULL
    },
    project_channels = function(...) "conda-forge"
  )
  pixi_add("dplyr", feature = "r44")
  pixi_remove("dplyr")
  pixi_add("dplyr", dry_run = TRUE) |> suppressMessages()
  expect_equal(installed, list("r44", "default"))
})

test_that("pixi_add() checks the install for skipped install scripts too", {
  local_recorded_pixi()
  checked <- list()
  local_mocked_bindings(
    project_channels = function(...) "conda-forge",
    install_changed_environment = function(...) list(stderr = "installed"),
    check_post_link = function(result, ...) {
      checked <<- c(checked, list(result))
    }
  )
  pixi_add("dplyr")
  expect_length(checked, 2)
  expect_equal(checked[[2]], list(stderr = "installed"))
})

test_that("install_environment() shows Pixi's output the first time", {
  root <- withr::local_tempdir()
  calls <- list()
  local_mocked_bindings(
    run_pixi = function(args, path, echo = FALSE, announce = echo) {
      calls <<- c(calls, list(list(args, path, echo, announce)))
    }
  )

  expect_snapshot(install_environment("r44", root))
  expect_equal(
    calls[[1]],
    list(c("install", "--environment", "r44"), root, TRUE, FALSE)
  )

  # Installed already: Pixi only updates it, if need be, quietly
  dir.create(
    file.path(root, ".pixi", "envs", "r44", "conda-meta"),
    recursive = TRUE
  )
  expect_silent(install_environment("r44", root))
  expect_equal(
    calls[[2]],
    list(c("install", "--environment", "r44"), root, FALSE, FALSE)
  )
})
