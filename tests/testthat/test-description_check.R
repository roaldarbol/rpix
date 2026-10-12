local_package_project <- function(
  description = c(
    "Package: demo",
    "Depends: R (>= 4.1), methods",
    "Imports: cli (>= 999.0), rlang, limma",
    "LinkingTo: Rcpp",
    "Suggests: testthat (>= 3.0.0), knitr"
  ),
  manifest = c(
    "[workspace]",
    'name = "demo"',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'r-cli = ">=3.0"',
    "",
    "[target.linux-64.dependencies]",
    '"r-rcpp" = "*"',
    "",
    "[feature.test.dependencies]",
    'r-testthat = "*"',
    "bioconductor-limma = { version = \"*\", channel = \"bioconda\" }"
  ),
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(description, file.path(dir, "DESCRIPTION"))
  writeLines(manifest, file.path(dir, "pixi.toml"))
  dir
}

test_that("description_check() finds what pixi.toml lacks", {
  dir <- local_package_project()
  check <- description_check(dir)
  # limma is only in the test feature, and rlang nowhere
  expect_equal(check$missing, c("rlang", "limma"))
  expect_equal(check$missing_suggests, "knitr")
  expect_equal(nrow(check$too_old), 0)
})

test_that("description_check() compares versions in the project's R", {
  dir <- local_package_project()
  old <- description_check(dir, in_project = TRUE)$too_old
  expect_equal(old$package, "cli")
  expect_equal(old$needs, "999.0")
  expect_equal(old$installed, as.character(utils::packageVersion("cli")))
})

test_that("description_check() is only for packages", {
  dir <- local_package_project(description = "Title: not a package")
  expect_null(description_check(dir))
})

test_that("declared_r_packages() reads R packages from pixi.toml's tables", {
  lines <- c(
    "[dependencies]",
    'r-cli = "*"',
    'python = "*"',
    "[feature.test.dependencies]",
    '"r-data.table" = "*"',
    "[feature.test.target.win-64.dependencies]",
    "bioconductor-Limma = '*'",
    "[tasks]",
    'r-fake = "echo"'
  )
  expect_equal(declared_r_packages(lines), "cli")
  expect_equal(
    declared_r_packages(lines, default = FALSE),
    c("cli", "data.table", "limma")
  )
})

test_that("too_old() handles conda's version spelling", {
  hard <- data.frame(
    field = "Imports",
    package = c("cli", "rlang", "nowhere"),
    constraint = c(">=999.0_1", "", ">=1.0")
  )
  old <- too_old(hard)
  expect_equal(old$needs, "999.0-1")
  expect_equal(nrow(too_old(hard[2, ])), 0)
})
