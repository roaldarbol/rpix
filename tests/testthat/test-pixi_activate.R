# pixi_r_location() ------------------------------------------------------------

test_that("finds the project and environment of a Pixi R", {
  expect_equal(
    pixi_r_location("/home/me/project/.pixi/envs/default/lib/R"),
    list(root = "/home/me/project", name = "default")
  )
  expect_equal(
    pixi_r_location("D:/a/project/.pixi/envs/test/lib/R/"),
    list(root = "D:/a/project", name = "test")
  )
  expect_null(pixi_r_location("/Library/Frameworks/R.framework/Resources"))
  expect_null(pixi_r_location("/opt/conda/envs/default/lib/R"))
})

# clean_lib_paths() ------------------------------------------------------------

test_that("removes the personal library and keeps the rest", {
  personal <- withr::local_tempdir()
  other <- withr::local_tempdir()
  root <- withr::local_tempdir()
  norm <- function(x) normalizePath(x, winslash = "/")

  paths <- clean_lib_paths(
    c(personal, other, .Library),
    personal = personal,
    project = "",
    root = root
  )
  expect_equal(paths, c(other, .Library))

  # Several personal libraries, separated like PATH
  paths <- clean_lib_paths(
    c(personal, other),
    personal = paste(personal, other, sep = .Platform$path.sep),
    project = "",
    root = root
  )
  expect_length(paths, 0)
})

test_that("keeps a personal library inside the project", {
  root <- withr::local_tempdir()
  project <- file.path(root, ".pixi", "r-libs", "default")
  dir.create(project, recursive = TRUE)
  project <- normalizePath(project, winslash = "/")

  paths <- clean_lib_paths(
    project,
    personal = project,
    project = project,
    root = root
  )
  expect_equal(paths, project)
})

test_that("doesn't add a library outside the project", {
  root <- withr::local_tempdir()
  outside <- withr::local_tempdir()
  expect_equal(clean_lib_paths(.Library, "", outside, root), .Library)
})

test_that("adds the project's library if it exists", {
  root <- withr::local_tempdir()
  project <- file.path(root, ".pixi", "r-libs", "default")

  expect_equal(clean_lib_paths(.Library, "", project, root), .Library)

  dir.create(project, recursive = TRUE)
  expect_equal(
    clean_lib_paths(.Library, "", project, root),
    c(normalizePath(project, winslash = "/"), .Library)
  )
})

# activation_variables() -------------------------------------------------------

test_that("uses the activation cache, and falls back to running without it", {
  calls <- list()
  local_mocked_bindings(run_pixi = function(args, ...) {
    calls[[length(calls) + 1]] <<- args
    if ("--use-environment-activation-cache" %in% args) {
      stop("unknown option")
    }
    list(
      environment_variables = list(FOO = "bar", PIXI_ENVIRONMENT_NAME = "dev")
    )
  })

  vars <- activation_variables("/project", "dev")
  expect_equal(vars, c(FOO = "bar", PIXI_ENVIRONMENT_NAME = "dev"))
  expect_equal(
    calls[[1]],
    c(
      "shell-hook",
      "--environment",
      "dev",
      "--frozen",
      "--use-environment-activation-cache"
    )
  )
  expect_equal(calls[[2]], c("shell-hook", "--environment", "dev", "--frozen"))
})

test_that("returns NULL if Pixi can't activate the environment", {
  local_mocked_bindings(run_pixi = function(...) stop("lock file out of date"))
  expect_null(activation_variables("/project", "default"))
})

test_that("reads the variables from a real Pixi environment", {
  skip_if_no_pixi()
  skip_on_cran()
  # shell-hook leaves out variables that already have the right value, as
  # they do when the tests run in rpix's own environment
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, PIXI_ENVIRONMENT_NAME = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")
  run_pixi("install", path = dir)

  vars <- activation_variables(dir, "default")
  expect_equal(unname(vars["PIXI_ENVIRONMENT_NAME"]), "default")
  expect_true(same_path(vars[["PIXI_PROJECT_ROOT"]], dir))
})

# pixi_activate() --------------------------------------------------------------

# A project with a pretend Pixi R, a personal library on .libPaths(), and the
# variables Pixi would set
local_activation <- function(vars = NULL, env = parent.frame()) {
  root <- normalizePath(
    withr::local_tempdir(.local_envir = env),
    winslash = "/"
  )
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  project_lib <- file.path(root, ".pixi", "r-libs", "default")
  dir.create(project_lib, recursive = TRUE)
  personal <- normalizePath(
    withr::local_tempdir(.local_envir = env),
    winslash = "/"
  )

  withr::local_libpaths(c(personal, .libPaths()), .local_envir = env)
  withr::local_envvar(
    R_LIBS_USER = personal,
    PIXI_ENVIRONMENT_NAME = NA,
    PIXI_PROJECT_ROOT = NA,
    RPIX_TEST_VAR = NA,
    .local_envir = env
  )
  vars <- vars %||% c(RPIX_TEST_VAR = "set", R_LIBS_USER = project_lib)
  local_mocked_bindings(
    r_home = function() file.path(root, ".pixi", "envs", "default", "lib", "R"),
    activation_variables = function(...) vars,
    .env = env
  )
  list(
    root = root,
    personal = personal,
    project_lib = normalizePath(project_lib, winslash = "/")
  )
}

test_that("activates R started directly from the environment", {
  p <- local_activation()

  result <- pixi_activate(p$root, quiet = TRUE)

  expect_true(result$activated)
  expect_equal(Sys.getenv("RPIX_TEST_VAR"), "set")
  expect_false(p$personal %in% .libPaths())
  expect_equal(.libPaths()[1], p$project_lib)
  expect_equal(result$lib_paths, .libPaths())
})

test_that("doesn't activate again what Pixi activated", {
  p <- local_activation()
  withr::local_envvar(
    PIXI_ENVIRONMENT_NAME = "default",
    PIXI_PROJECT_ROOT = p$root,
    R_LIBS_USER = p$project_lib
  )
  local_mocked_bindings(activation_variables = function(...) {
    stop("shouldn't be called")
  })

  result <- pixi_activate(p$root, quiet = TRUE)
  expect_false(result$activated)
})

test_that("gives a hint, and changes nothing, in an R that isn't the project's", {
  p <- local_activation()
  local_mocked_bindings(r_home = function() {
    "/Library/Frameworks/R.framework/Resources"
  })
  paths <- .libPaths()

  expect_message(result <- pixi_activate(p$root, quiet = FALSE), "pixi run R")
  expect_false(result$activated)
  expect_null(result$lib_paths)
  expect_equal(.libPaths(), paths)
  expect_silent(pixi_activate(p$root, quiet = TRUE))
})

test_that("gives a hint in a folder without a Pixi project", {
  local_mocked_bindings(r_home = function() "/project/.pixi/envs/default/lib/R")
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  expect_message(
    pixi_activate(withr::local_tempdir(), quiet = FALSE),
    "isn't from"
  )
})

test_that("says so if the environment can't be activated, and still cleans .libPaths()", {
  p <- local_activation()
  local_mocked_bindings(activation_variables = function(...) NULL)

  expect_message(result <- pixi_activate(p$root, quiet = FALSE), "pixi install")
  expect_false(result$activated)
  expect_false(p$personal %in% .libPaths())
})

test_that("never fails", {
  p <- local_activation()
  local_mocked_bindings(find_project_root = function(...) stop("boom"))

  expect_message(result <- pixi_activate(p$root, quiet = FALSE), "boom")
  expect_false(result$activated)
})

# add_rprofile_block() ---------------------------------------------------------

test_that("adds the block to a new or existing .Rprofile", {
  file <- file.path(withr::local_tempdir(), ".Rprofile")
  add_rprofile_block(file)
  expect_equal(readLines(file), rprofile_block)

  writeLines("options(digits = 4)", file)
  add_rprofile_block(file)
  expect_equal(readLines(file), c("options(digits = 4)", "", rprofile_block))
})

test_that("updates the block in place instead of adding it again", {
  file <- file.path(withr::local_tempdir(), ".Rprofile")
  writeLines(
    c("before", "# >>> rpix >>>", "old line", "# <<< rpix <<<", "after"),
    file
  )
  add_rprofile_block(file)
  add_rprofile_block(file)
  expect_equal(readLines(file), c("before", rprofile_block, "after"))
})

test_that("r_home() is R.home()", {
  expect_equal(r_home(), R.home())
})
