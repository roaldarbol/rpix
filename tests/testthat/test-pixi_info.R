# What `pixi list --json` gives, as jsonlite reads it
fake_list <- function() {
  data.frame(
    name = c("r-rcpp", "r-base", "bioconductor-deseq2", "gdal", "requests"),
    version = c("1.0.14", "4.5.3", "1.48.0", "3.11.0", "2.32.3"),
    build = c("r45h", "h1", "r45h", "h2", "pypi_0"),
    build_number = c(0L, 1L, 0L, 0L, 0L),
    source = c(
      rep("https://conda.anaconda.org/conda-forge", 4),
      "https://pypi.org"
    ),
    kind = c("conda", "conda", "conda", "conda", "pypi"),
    is_explicit = c(TRUE, TRUE, FALSE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )
}

test_that("pixi_list() returns the useful columns, with R package names", {
  library <- withr::local_tempdir()
  dir.create(file.path(library, "Rcpp"))
  calls <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls[[length(calls) + 1]] <<- args
      fake_list()
    },
    r_library = function(...) library
  )

  packages <- pixi_list(environment = "dev", explicit = TRUE)

  expect_equal(calls[[1]], c("list", "--environment", "dev", "--explicit"))
  expect_named(
    packages,
    c("name", "version", "r_package", "explicit", "channel", "kind", "build")
  )
  expect_equal(packages$r_package, c("Rcpp", NA, "deseq2", NA, NA))
  expect_equal(packages$explicit, c(TRUE, TRUE, FALSE, TRUE, FALSE))
  expect_equal(packages$channel, c(rep("conda-forge", 4), "pypi.org"))
})

test_that("pixi_list() handles an empty environment", {
  local_mocked_bindings(
    run_pixi = function(...) list(),
    r_library = function(...) NULL
  )
  packages <- pixi_list()
  expect_equal(nrow(packages), 0)
  expect_named(
    packages,
    c("name", "version", "r_package", "explicit", "channel", "kind", "build")
  )
})

test_that("R package names keep R's spelling when the package is installed", {
  library <- withr::local_tempdir()
  dir.create(file.path(library, "DESeq2"))
  expect_equal(
    r_package_names(
      c("bioconductor-deseq2", "r-data.table", "r-recommended", "python"),
      library
    ),
    c("DESeq2", "data.table", NA, NA)
  )
  expect_equal(r_package_names("r-rcpp", NULL), "rcpp")
})

test_that("pixi_tree() translates package names into a regular expression", {
  calls <- list()
  local_mocked_bindings(run_pixi = function(args, ...) {
    calls[[length(calls) + 1]] <<- args
    list(stdout = "r-cli 3.6.6\n└── r-base 4.5.3\n")
  })

  expect_output(
    lines <- pixi_tree(c("cli", "data.table"), invert = TRUE),
    "r-base"
  )
  expect_equal(calls[[1]], c("tree", "--invert", "^(r-cli|r-data\\.table)$"))
  expect_equal(lines, c("r-cli 3.6.6", "└── r-base 4.5.3"))

  expect_output(pixi_tree(environment = "dev"))
  expect_equal(calls[[2]], c("tree", "--environment", "dev"))
})

test_that("finds an environment's R library, or NULL", {
  local_mocked_bindings(pixi_info = function(...) {
    list(
      environments_info = data.frame(
        name = "default",
        prefix = "/p/.pixi/envs/default"
      )
    )
  })
  expect_equal(
    r_library("default", NULL),
    file.path("/p/.pixi/envs/default", "lib", "R", "library")
  )
  expect_null(r_library("dev", NULL))
})

test_that("works with a real Pixi project", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  info <- pixi_info(dir)
  expect_equal(info$environments_info$name, "default")

  packages <- pixi_list(path = dir)
  expect_equal(nrow(packages), 0)
})
