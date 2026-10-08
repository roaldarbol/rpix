# Mock pixi: record each call, and create pixi.toml on `pixi init`
local_mock_setup <- function(env = parent.frame()) {
  calls <- new.env()
  calls$args <- list()
  calls$paths <- list()
  home <- withr::local_tempdir(.local_envir = env)
  local_mocked_bindings(
    pixi_binary = function(...) "/fake/pixi",
    # Keep the real ~/.Rprofile out of it
    home_dir = function() home,
    run_pixi = function(args, path = NULL, ...) {
      calls$args <- c(calls$args, list(args))
      calls$paths <- c(calls$paths, list(path))
      if (args[1] == "init") {
        writeLines("[workspace]", file.path(args[2], "pixi.toml"))
      }
      invisible(list(status = 0))
    },
    .env = env
  )
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, .local_envir = env)
  calls$home <- home
  calls
}

legacy_fixture <- function() {
  test_path("fixtures", "legacy-rprofile.txt")
}

test_that("use_pixi() creates a project and adds R and rpix", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  withr::local_dir(dir)

  manifest <- suppressMessages(use_pixi())

  expect_equal(manifest, file.path(dir, "pixi.toml"))
  expect_length(calls$args, 3)
  expect_equal(calls$args[[1]], c("init", dir))
  expect_equal(calls$args[[2]][1:2], c("add", "r-base"))
  expect_true(all(c("r-cli", "r-jsonlite", "r-processx") %in% calls$args[[2]]))
  expect_true("conda-ecosystem-user-package-isolation" %in% calls$args[[2]])
  expect_equal(calls$args[[3]][1:3], c("run", "Rscript", "-e"))
  # utils' own, not rpix's, which adds packages with Pixi
  expect_match(
    calls$args[[3]][4],
    "utils::install.packages('rpix'",
    fixed = TRUE
  )
  expect_match(calls$args[[3]][4], "lib = .Library", fixed = TRUE)
  # Commands target the project, not the environment R happens to run in
  expect_true(all(vapply(calls$paths[-1], identical, logical(1), dir)))
})

test_that("use_pixi() uses an existing project and can skip rpix", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  dir.create(file.path(dir, "sub"))
  withr::local_dir(file.path(dir, "sub"))

  suppressMessages(use_pixi(r_version = "4.5", install_rpix = FALSE))

  expect_equal(
    calls$args,
    list(c("add", "r-base=4.5", "conda-ecosystem-user-package-isolation"))
  )
  expect_equal(calls$paths[[1]], dir)
})

test_that("use_pixi() errors without a project if it may not create one", {
  calls <- local_mock_setup()
  withr::local_dir(withr::local_tempdir())

  expect_error(use_pixi(init_if_missing = FALSE), "no Pixi project")
  expect_length(calls$args, 0)
})

test_that("use_pixi() removes the old .Rprofile block and warns about a global one", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  file.copy(legacy_fixture(), file.path(dir, ".Rprofile"))
  file.copy(legacy_fixture(), file.path(calls$home, ".Rprofile"))
  withr::local_dir(dir)

  expect_warning(
    suppressMessages(use_pixi(install_rpix = FALSE)),
    "still has the Pixi library setup"
  )
  expect_false(any(grepl("Pixi R library setup", readLines(".Rprofile"))))
})

# remove_legacy_rprofile() -----------------------------------------------------

test_that("removes only the old block, keeping the rest of the file", {
  file <- withr::local_tempfile()
  file.copy(legacy_fixture(), file)

  expect_true(suppressMessages(remove_legacy_rprofile(file)))
  expect_equal(
    readLines(file),
    c(
      "# Something the user wrote",
      "options(digits = 4)",
      "",
      "",
      "# Something the user added later",
      "options(width = 100)"
    )
  )
  # Running it again changes nothing
  expect_false(remove_legacy_rprofile(file))
})

test_that("does nothing without a file or without the block", {
  expect_false(remove_legacy_rprofile(file.path(
    withr::local_tempdir(),
    ".Rprofile"
  )))

  file <- withr::local_tempfile()
  writeLines("options(digits = 4)", file)
  expect_false(remove_legacy_rprofile(file))
  expect_equal(readLines(file), "options(digits = 4)")
})

test_that("leaves a block it can't find the end of", {
  file <- withr::local_tempfile()
  writeLines(c("# Pixi R library setup", "local({", "  x <- 1"), file)

  expect_warning(remove_legacy_rprofile(file), "Remove it by hand")
  expect_length(readLines(file), 3)
})

# rpix_dependencies() ----------------------------------------------------------

test_that("rpix's dependencies are translated to conda names", {
  expect_equal(
    rpix_dependencies("cli (>= 3.0.0),\n    jsonlite, processx"),
    c("r-cli", "r-jsonlite", "r-processx")
  )
  expect_true(all(c("r-cli", "r-processx") %in% rpix_dependencies()))
})

test_that("use_pixi() sets up the IDEs it's asked to", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  withr::local_dir(dir)
  ides <- character()
  local_mocked_bindings(
    use_pixi_positron = function(path) ides <<- c(ides, "positron"),
    use_pixi_vscode = function(path) ides <<- c(ides, "vscode")
  )

  suppressMessages(use_pixi(
    ide = c("vscode", "positron"),
    install_rpix = FALSE
  ))
  expect_equal(ides, c("vscode", "positron"))
  # Added with R, so Pixi picks an R that languageserver is built for
  expect_equal(
    calls$args[[1]],
    c(
      "add",
      "r-base",
      "conda-ecosystem-user-package-isolation",
      "r-languageserver"
    )
  )
  expect_error(use_pixi(ide = "emacs"), "should be one of")
})

test_that("setup_pixi() is deprecated in favour of use_pixi()", {
  local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  withr::local_dir(dir)
  lifecycle::expect_deprecated(suppressMessages(setup_pixi(
    install_rpix = FALSE
  )))
})

test_that("use_pixi() sets up the folder in `path`", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  withr::local_dir(withr::local_tempdir())

  manifest <- suppressMessages(use_pixi(path = dir, install_rpix = FALSE))
  expect_equal(manifest, file.path(dir, "pixi.toml"))
  expect_equal(calls$args[[1]], c("init", dir))
})
