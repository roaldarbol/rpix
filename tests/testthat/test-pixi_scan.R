test_that("code_packages() finds loaded and namespaced packages", {
  code <- c(
    "library(dplyr)",
    "require('ggplot2')",
    "library(package = tidyr)",
    "x <- readr::read_csv('a.csv')",
    "y <- utils:::head",
    "if (requireNamespace(\"cli\", quietly = TRUE)) loadNamespace('jsonlite')",
    "library(pkg, character.only = TRUE)",
    "f <- function(library) library(1)"
  )
  expect_setequal(
    code_packages(code),
    c("readr", "utils", "dplyr", "ggplot2", "tidyr", "cli", "jsonlite", "pkg")
  )
  expect_equal(code_packages("this isn't R ("), character())
  expect_equal(code_packages(character()), character())
})

test_that("r_chunks() keeps only the R chunks of a document", {
  lines <- c(
    "---",
    "title: x",
    "---",
    "```{r}",
    "library(dplyr)",
    "```",
    "Some `r 1 + 1` text.",
    "```{python}",
    "import pandas",
    "```",
    "```{r setup, include = FALSE}",
    "library(gt)",
    "```",
    "```",
    "library(notcode)",
    "```"
  )
  expect_equal(r_chunks(lines), c("library(dplyr)", "library(gt)"))
})

test_that("command_packages() finds packages in task commands", {
  expect_setequal(
    command_packages(c(
      "Rscript -e 'devtools::test()'",
      "Rscript -e 'pkgdown::clean_site(); pkgdown::build_site()'",
      "air format ."
    )),
    c("devtools", "pkgdown")
  )
})

# A project with code, and a pixi.toml as pixi_scan() sees it
local_scan_project <- function(env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  writeLines(
    c("Package: mypkg", "Version: 0.1"),
    file.path(root, "DESCRIPTION")
  )
  dir.create(file.path(root, "R"))
  writeLines(
    c("f <- function() dplyr::filter", "mypkg::f", "rpix::pixi_add"),
    file.path(root, "R", "f.R")
  )
  writeLines(
    c("```{r}", "library(ggplot2)", "library(DESeq2)", "library(stats)", "```"),
    file.path(root, "report.qmd")
  )
  dir.create(file.path(root, ".pixi", "envs"), recursive = TRUE)
  writeLines("library(shouldbeskipped)", file.path(root, ".pixi", "a.R"))

  calls <- new.env()
  calls$add <- list()
  local_mocked_bindings(
    require_project = function(path) root,
    task_commands = function(root) "Rscript -e 'testthat::test_dir(\"tests\")'",
    environment_dependencies = function(root) {
      list(
        default = c("r-base", "r-cli", "r-dplyr", "r-tibble", "python"),
        test = c("r-testthat")
      )
    },
    project_dependencies = function(root) {
      c("r-base", "r-cli", "r-dplyr", "r-tibble", "python")
    },
    find_r_packages = function(packages) {
      c(ggplot2 = "cran::ggplot2", DESeq2 = NA)[packages]
    },
    pixi_add = function(packages, path) {
      calls$add <- c(calls$add, list(packages))
    },
    .env = env
  )
  calls$root <- root
  calls
}

test_that("pixi_scan() compares the code's packages with pixi.toml", {
  local_scan_project()

  expect_snapshot(result <- pixi_scan())
  expect_equal(
    result$used$package,
    c("DESeq2", "dplyr", "ggplot2", "mypkg", "rpix", "stats", "testthat")
  )
  expect_equal(result$used$files[[3]], "report.qmd")
  expect_equal(result$used$files[[7]], "pixi.toml")
  # Its own package, rpix and base packages don't count; testthat is in
  # the test environment
  expect_equal(result$missing, c("DESeq2", "ggplot2"))
  # r-cli is there for rpix
  expect_equal(result$unused, "r-tibble")
})

test_that("pixi_scan() can add the missing packages", {
  calls <- local_scan_project()

  expect_snapshot(pixi_scan(add = TRUE))
  expect_equal(calls$add, list("cran::ggplot2"))
})

test_that("pixi_scan() says when pixi.toml has everything", {
  root <- withr::local_tempdir()
  writeLines("dplyr::filter", file.path(root, "a.R"))
  local_mocked_bindings(
    require_project = function(path) root,
    task_commands = function(root) character(),
    environment_dependencies = function(root) list(default = "r-dplyr"),
    project_dependencies = function(root) "r-dplyr"
  )
  expect_snapshot(result <- pixi_scan())
  expect_equal(result$missing, character())
  expect_equal(result$unused, character())
})

test_that("the helpers read the project", {
  expect_equal(
    r_names(c("r-Rcpp", "bioconductor-deseq2", "python")),
    c("rcpp", "deseq2", "python")
  )
  expect_equal(package_name(withr::local_tempdir()), character())

  local_mocked_bindings(
    pixi_info = function(root) {
      list(
        environments_info = data.frame(
          name = c("default", "test"),
          dependencies = I(list("r-cli", c("r-cli", "r-testthat")))
        )
      )
    },
    pixi_tasks = function(path) data.frame(command = c("air format .", NA))
  )
  expect_equal(
    environment_dependencies("/p"),
    list(default = "r-cli", test = c("r-cli", "r-testthat"))
  )
  expect_equal(task_commands("/p"), "air format .")
})
