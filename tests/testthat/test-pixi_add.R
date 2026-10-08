local_project_dir <- function(env = parent.frame()) {
  root <- local_pixi_project(env = env)
  withr::local_dir(root, .local_envir = env)
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, .local_envir = env)
  root
}

dry <- function(expr) suppressMessages(expr)

test_that("pixi_add() translates names", {
  local_project_dir()
  expect_equal(
    dry(pixi_add(c("dplyr", "Rcpp", "conda::gdal"), dry_run = TRUE)),
    "pixi add r-dplyr r-rcpp gdal --manifest-path pixi.toml"
  )
})

test_that("pixi_add() handles versions inline and in `versions`", {
  local_project_dir()
  expect_equal(
    dry(pixi_add("dplyr>=1.1", dry_run = TRUE)),
    "pixi add \"r-dplyr>=1.1\" --manifest-path pixi.toml"
  )
  expect_equal(
    dry(pixi_add("dplyr", versions = "1.1", dry_run = TRUE)),
    "pixi add r-dplyr=1.1 --manifest-path pixi.toml"
  )
  expect_equal(
    dry(pixi_add(
      c("dplyr", "tidyr"),
      versions = c(">=1.1", NA),
      dry_run = TRUE
    )),
    "pixi add \"r-dplyr>=1.1\" r-tidyr --manifest-path pixi.toml"
  )
  expect_error(
    pixi_add(c("a1", "b1", "c1"), versions = c("1", "2")),
    "length 1"
  )
  expect_error(pixi_add("dplyr>=1", versions = "1"), "not both")
})

test_that("pixi_add() adds the channels it needs to the project first", {
  local_project_dir()
  expect_equal(
    dry(pixi_add(c("dplyr", "bioc::DESeq2"), dry_run = TRUE)),
    c(
      "pixi workspace channel add bioconda --no-install --manifest-path pixi.toml",
      "pixi add r-dplyr bioconda::bioconductor-deseq2 --manifest-path pixi.toml"
    )
  )
  expect_equal(
    dry(pixi_add("dplyr", channel = "my-channel", dry_run = TRUE)),
    c(
      "pixi workspace channel add my-channel --no-install --manifest-path pixi.toml",
      "pixi add my-channel::r-dplyr --manifest-path pixi.toml"
    )
  )
})

test_that("pixi_remove() translates names and rejects constraints", {
  local_project_dir()
  expect_equal(
    dry(pixi_remove(c("dplyr", "bioc::DESeq2", "conda::gdal"), dry_run = TRUE)),
    "pixi remove r-dplyr bioconductor-deseq2 gdal --manifest-path pixi.toml"
  )
  expect_error(pixi_remove("dplyr>=1"), "without version constraints")
})

test_that("pixi_search() translates names", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())

  expect_equal(dry(pixi_search("Rcpp", dry_run = TRUE)), "pixi search r-rcpp")
  expect_equal(
    dry(pixi_search("bioc::DESeq2", dry_run = TRUE)),
    "pixi search bioconductor-deseq2 --channel bioconda"
  )
  expect_equal(
    dry(pixi_search("conda::gdal", channel = "my-channel", dry_run = TRUE)),
    "pixi search gdal --channel my-channel"
  )
  expect_error(pixi_search(c("a1", "b1")), "single package")
})

test_that("project_channels() reads the project's channels", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())
  run_pixi(
    c("init", ".", "--channel", "conda-forge", "--channel", "bioconda"),
    project = "none"
  )

  expect_setequal(project_channels(), c("conda-forge", "bioconda"))
})

test_that("add() is deprecated in favour of pixi_add()", {
  local_project_dir()
  lifecycle::expect_deprecated(command <- dry(add("dplyr", dry_run = TRUE)))
  expect_equal(command, dry(pixi_add("dplyr", dry_run = TRUE)))
})
