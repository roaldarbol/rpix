# A project with the fixture lock file and renv's .Rprofile line, with
# pixi_import_renv()'s lookups and additions mocked
local_renv_project <- function(
  dependencies = character(),
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  file.copy(test_path("fixtures", "renv.lock"), dir)
  writeLines(
    c("source(\"renv/activate.R\")", "options(digits = 4)"),
    file.path(dir, ".Rprofile")
  )
  calls <- new.env()
  calls$add <- list()
  calls$searched <- character()
  local_mocked_bindings(
    require_project = function(path) dir,
    project_dependencies = function(root) dependencies,
    find_r_packages = function(packages) {
      found <- c(
        cli = "cran::cli",
        dplyr = "cran::dplyr",
        Matrix = "cran::Matrix",
        DESeq2 = "bioc::DESeq2",
        notonconda = NA
      )
      found[packages]
    },
    on_channel = function(name, channel) {
      calls$searched <- c(calls$searched, paste(channel, name))
      name != "r-dplyr==1.1.4"
    },
    pixi_add = function(packages, path, dry_run) {
      calls$add <- c(calls$add, list(packages))
    },
    .env = env
  )
  calls$dir <- dir
  calls
}

test_that("pixi_import_renv() adds the packages the project uses, and turns renv off", {
  calls <- local_renv_project()

  expect_snapshot(result <- pixi_import_renv())
  # cli and Matrix are only there for dplyr and DESeq2
  expect_equal(
    calls$add,
    list(c("r-base>=4.4", "cran::dplyr>=1.1.4", "bioc::DESeq2>=1.46.0"))
  )
  expect_equal(result$not_from_repository, "mypkg")
  expect_equal(result$missing, "notonconda")
  expect_equal(
    readLines(file.path(calls$dir, ".Rprofile")),
    "options(digits = 4)"
  )
})

test_that("pixi_import_renv() can add every package, at exact versions", {
  calls <- local_renv_project()

  suppressMessages(pixi_import_renv(versions = "exact", all = TRUE))
  expect_equal(
    calls$add[[1]],
    c(
      "r-base=4.4",
      "cran::cli==3.6.3",
      # Not on conda-forge at that version
      "cran::dplyr>=1.1.4",
      "cran::Matrix==1.7_1",
      "bioc::DESeq2==1.46.0"
    )
  )
  expect_true("bioconda bioconductor-deseq2==1.46.0" %in% calls$searched)
})

test_that("pixi_import_renv() can leave versions, R and renv alone", {
  calls <- local_renv_project(dependencies = "r-base")

  expect_snapshot(
    pixi_import_renv(versions = "none", deactivate = FALSE, dry_run = TRUE)
  )
  expect_equal(calls$add, list(c("cran::dplyr", "bioc::DESeq2")))
  expect_length(readLines(file.path(calls$dir, ".Rprofile")), 2)

  # A dry run says what it would do to .Rprofile
  expect_snapshot(pixi_import_renv(dry_run = TRUE))
  expect_length(readLines(file.path(calls$dir, ".Rprofile")), 2)
})

test_that("pixi_import_renv() needs a lock file", {
  calls <- local_renv_project()
  expect_error(
    pixi_import_renv(file.path(calls$dir, "nope.lock")),
    "no renv lock file"
  )
})

test_that("lock_spec() writes the version as asked", {
  local_mocked_bindings(on_channel = function(name, channel) TRUE)
  expect_equal(lock_spec("cran::cli", "3.6.3", "none"), "cran::cli")
  expect_equal(lock_spec("cran::cli", NULL, "exact"), "cran::cli")
  expect_equal(
    lock_spec("cran::Matrix", "1.7-1", "minimum"),
    "cran::Matrix>=1.7_1"
  )
  expect_equal(
    lock_spec("cran::Matrix", "1.7-1", "exact"),
    "cran::Matrix==1.7_1"
  )
})

test_that("remove_renv_activation() leaves .Rprofile files without renv alone", {
  file <- withr::local_tempfile()
  expect_false(remove_renv_activation(file))
  writeLines("options(digits = 4)", file)
  expect_false(remove_renv_activation(file))
  expect_equal(readLines(file), "options(digits = 4)")
})
