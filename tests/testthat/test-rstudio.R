test_that("every addin and template binds to a function", {
  dcf <- function(...) read.dcf(system.file("rstudio", ..., package = "rpix"))
  bindings <- c(
    dcf("addins.dcf")[, "Binding"],
    # The template's parameters are records of their own
    dcf("templates", "project", "rpix.dcf")[1, "Binding"]
  )
  for (binding in bindings) {
    expect_true(
      is.function(get0(binding, asNamespace("rpix"))),
      label = binding
    )
  }
})

test_that("finds packages in names or in code", {
  expect_equal(text_packages("dplyr, tidyr"), c("dplyr", "tidyr"))
  expect_equal(text_packages(' "dplyr"\n`ggplot2` '), c("dplyr", "ggplot2"))
  expect_setequal(
    text_packages("library(dplyr)\nx <- tidyr::pivot_longer(y)"),
    c("dplyr", "tidyr")
  )
  expect_equal(text_packages("  "), character())
})

test_that("Add packages adds the selection, or asks", {
  added <- NULL
  local_mocked_bindings(
    pixi_add = function(packages, ...) added <<- packages,
    rstudio_selection = function() "dplyr, tidyr"
  )
  addin_add_packages()
  expect_equal(added, c("dplyr", "tidyr"))

  local_mocked_bindings(
    rstudio_selection = function() "",
    ask_dialog = function(title, message) "ggplot2"
  )
  addin_add_packages()
  expect_equal(added, "ggplot2")

  # Cancelled
  added <- NULL
  local_mocked_bindings(ask_dialog = function(title, message) NULL)
  expect_message(addin_add_packages(), "No packages")
  expect_null(added)
})

test_that("Add the packages this file uses adds what pixi.toml lacks", {
  root <- withr::local_tempdir()
  file <- file.path(root, "analysis.R")
  writeLines(c("library(dplyr)", "tidyr::pivot_longer(x)"), file)
  added <- NULL
  local_mocked_bindings(
    rstudio_active_file = function() file,
    require_project = function(path, ...) root,
    missing_packages = function(root, packages) setdiff(packages, "tidyr"),
    add_missing_packages = function(root, missing) added <<- missing
  )
  addin_add_file_packages()
  expect_equal(added, "dplyr")

  local_mocked_bindings(missing_packages = function(root, packages) character())
  expect_message(addin_add_file_packages(), "has all the packages")

  local_mocked_bindings(rstudio_active_file = function() NULL)
  expect_message(addin_add_file_packages(), "Save the file first")
})

test_that("Open with the project's Pixi R picks the only environment, or asks", {
  switched <- "unset"
  local_mocked_bindings(
    require_project = function(path, ...) "/project",
    pixi_environments = function(path) data.frame(name = "default"),
    pixi_switch = function(environment, ide) {
      expect_equal(ide, "rstudio")
      switched <<- environment
    }
  )
  addin_open_with_pixi_r()
  expect_equal(switched, "default")

  local_mocked_bindings(
    pixi_environments = function(path) data.frame(name = c("default", "r44"))
  )
  addin_open_with_pixi_r()
  expect_null(switched)
})

test_that("the other addins run rpix's functions", {
  ran <- character()
  local_mocked_bindings(
    pixi_sitrep = function() ran <<- c(ran, "sitrep"),
    pixi_install = function() ran <<- c(ran, "install"),
    require_project = function(path, ...) "/project",
    find_manifest = function(path) "/project/pixi.toml"
  )
  local_mocked_bindings(
    file.edit = function(file, ...) ran <<- c(ran, file),
    .package = "utils"
  )
  addin_sitrep()
  addin_install()
  addin_open_manifest()
  expect_equal(ran, c("sitrep", "install", "/project/pixi.toml"))
})

test_that("Run a task asks which, and runs it", {
  ran <- NULL
  answer <- 2L
  local_mocked_bindings(
    pixi_tasks = function() data.frame(name = c("render", "test", "test")),
    ask_choice = function(question, choices) {
      expect_equal(choices, c("render", "test"))
      answer
    },
    pixi_run = function(task) ran <<- task
  )
  addin_run_task()
  expect_equal(ran, "test")

  # Cancelled
  ran <- NULL
  answer <- NA_integer_
  addin_run_task()
  expect_null(ran)

  local_mocked_bindings(pixi_tasks = function() data.frame(name = character()))
  expect_message(addin_run_task(), "no tasks")
})

test_that("the New Project template sets the project up for RStudio", {
  path <- file.path(withr::local_tempdir(), "new")
  called <- NULL
  local_mocked_bindings(use_pixi = function(...) called <<- list(...))
  rstudio_new_project(path, r_version = "4.4")
  expect_true(dir.exists(path))
  expect_equal(called, list(r_version = "4.4", ide = "rstudio", path = path))

  # The dialog's default
  rstudio_new_project(path)
  expect_equal(called$r_version, "4.5")

  # RStudio's hidden renv setting
  expect_silent(rstudio_new_project(path))
  local_mocked_bindings(rstudio_preference = function(name) TRUE)
  expect_message(rstudio_new_project(path), "also set up renv")

  # With git
  initialised <- NULL
  local_mocked_bindings(git_init = function(path) initialised <<- path)
  rstudio_new_project(path, git = FALSE)
  expect_null(initialised)
  rstudio_new_project(path, git = TRUE)
  expect_equal(initialised, path)
})

test_that("git_init() makes a git repository, or says it can't", {
  skip_if(!nzchar(Sys.which("git")))
  path <- withr::local_tempdir()
  expect_message(expect_true(git_init(path)), "git repository")
  expect_true(dir.exists(file.path(path, ".git")))

  local_mocked_bindings(
    Sys.which = function(names) c(git = ""),
    .package = "base"
  )
  expect_message(expect_false(git_init(path)), "Git isn't installed")
})

test_that("reads RStudio's editor through its API, and asks in a dialog", {
  expect_null(rstudio_api("getSourceEditorContext"))
  expect_null(rstudio_preference("new_proj_use_renv"))
  expect_equal(rstudio_selection(), "")
  expect_null(rstudio_active_file())

  context <- list(path = "/project/a.R", selection = list(list(text = "dplyr")))
  local_mocked_bindings(rstudio_api = function(name) {
    switch(
      name,
      getSourceEditorContext = function() context,
      showPrompt = function(title, message, default) "tidyr"
    )
  })
  expect_equal(rstudio_selection(), "dplyr")
  expect_equal(rstudio_active_file(), "/project/a.R")
  expect_equal(ask_dialog("Add packages", "Packages:"), "tidyr")

  context$path <- ""
  expect_null(rstudio_active_file())

  local_mocked_bindings(rstudio_api = function(name) {
    function(name, default) if (name == "new_proj_use_renv") TRUE else default
  })
  expect_true(rstudio_preference("new_proj_use_renv"))
  expect_null(rstudio_preference("other"))
})

test_that("asks in the console outside RStudio", {
  local_mocked_bindings(is_interactive = function() FALSE)
  expect_null(ask_dialog("Add packages", "Packages:"))
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_text = function(prompt) "dplyr"
  )
  expect_equal(ask_dialog("Add packages", "Packages:"), "dplyr")
})
