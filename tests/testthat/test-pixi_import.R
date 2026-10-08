local_description <- function(lines, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(
    c("Package: demo", "Version: 0.0.1", lines),
    file.path(dir, "DESCRIPTION")
  )
  dir
}

demo_description <- c(
  "Depends: R (>= 4.1), methods",
  "Imports:",
  "    cli (>= 3.6.0),",
  "    jsonlite,",
  "    Matrix (>= 1.6-5),",
  "    notonconda",
  "LinkingTo: cli",
  "Suggests:",
  "    testthat (>= 3.0.0),",
  "    jsonlite,",
  "    DESeq2"
)

test_that("description_dependencies() reads fields, packages and versions", {
  dir <- local_description(demo_description)
  deps <- description_dependencies(file.path(dir, "DESCRIPTION"))

  expect_equal(deps$field[1:3], c("Depends", "Depends", "Imports"))
  expect_equal(
    deps$package,
    c(
      "R",
      "methods",
      "cli",
      "jsonlite",
      "Matrix",
      "notonconda",
      "cli",
      "testthat",
      "jsonlite",
      "DESeq2"
    )
  )
  # conda writes 1.6-5 as 1.6_5
  expect_equal(
    deps$constraint,
    c(">=4.1", "", ">=3.6.0", "", ">=1.6_5", "", "", ">=3.0.0", "", "")
  )
  expect_equal(
    package_dependencies(file.path(dir, "DESCRIPTION")),
    c("cli", "jsonlite", "Matrix", "notonconda", "testthat", "DESeq2")
  )
})

test_that("description_dependencies() copes with no dependencies", {
  dir <- local_description(character())
  deps <- description_dependencies(file.path(dir, "DESCRIPTION"))
  expect_equal(nrow(deps), 0)
  expect_named(deps, c("field", "package", "constraint"))
})

test_that("description_dependencies() needs a DESCRIPTION", {
  expect_error(
    description_dependencies(file.path(withr::local_tempdir(), "DESCRIPTION")),
    "no package here"
  )
})

# Record pixi_import_description()'s calls, with packages found as given
local_import <- function(
  dir,
  found = c(
    cli = "cran::cli",
    jsonlite = "cran::jsonlite",
    Matrix = "cran::Matrix",
    notonconda = NA,
    testthat = "cran::testthat",
    DESeq2 = "bioc::DESeq2"
  ),
  dependencies = character(),
  env = parent.frame()
) {
  calls <- new.env()
  calls$add <- list()
  calls$environments <- list()
  local_mocked_bindings(
    require_project = function(path) dir,
    find_r_packages = function(packages) found[unique(packages)],
    project_dependencies = function(root) dependencies,
    pixi_add = function(packages, feature = NULL, path, dry_run) {
      calls$add <- c(
        calls$add,
        list(list(packages = packages, feature = feature))
      )
    },
    pixi_add_environment = function(
      name,
      features,
      solve_group,
      overwrite,
      path,
      dry_run
    ) {
      calls$environments <- c(
        calls$environments,
        list(c(name, features, solve_group))
      )
    },
    .env = env
  )
  calls
}

test_that("pixi_import_description() adds the dependencies, with R", {
  dir <- local_description(demo_description)
  calls <- local_import(dir)

  expect_snapshot(result <- pixi_import_description())
  expect_equal(
    calls$add[[1]],
    list(
      packages = c(
        "r-base>=4.1",
        "cran::cli>=3.6.0",
        "cran::jsonlite",
        "cran::Matrix>=1.6_5"
      ),
      feature = NULL
    )
  )
  expect_equal(
    calls$add[[2]],
    list(
      packages = c("cran::testthat>=3.0.0", "bioc::DESeq2"),
      feature = "test"
    )
  )
  expect_equal(calls$environments, list(c("test", "test", "default")))
  expect_equal(result$missing, "notonconda")
})

test_that("pixi_import_description() keeps the project's R, and can skip Suggests", {
  dir <- local_description(demo_description)
  calls <- local_import(dir, dependencies = c("r-base", "r-cli"))

  suppressMessages(pixi_import_description(test = FALSE))
  expect_length(calls$add, 1)
  expect_equal(calls$add[[1]]$packages[1], "cran::cli>=3.6.0")
  expect_length(calls$environments, 0)
})

test_that("pixi_import_description() adds R without a version, and nothing else", {
  dir <- local_description(character())
  calls <- local_import(dir)

  result <- pixi_import_description()
  expect_equal(calls$add, list(list(packages = "r-base", feature = NULL)))
  expect_equal(result$missing, character())

  # Nothing to add at all
  calls <- local_import(dir, dependencies = "r-base")
  pixi_import_description()
  expect_length(calls$add, 0)
})

test_that("find_r_packages() looks on conda-forge, then bioconda", {
  local_mocked_bindings(
    on_channel = function(name, channel) {
      name %in% c("r-cli", "bioconductor-deseq2")
    }
  )
  expect_equal(
    suppressMessages(find_r_packages(c("cli", "DESeq2", "nope", "cli"))),
    c(cli = "cran::cli", DESeq2 = "bioc::DESeq2", nope = NA)
  )
  expect_length(find_r_packages(character()), 0)
})

test_that("on_channel() asks pixi search", {
  calls <- local_recorded_pixi()
  expect_true(on_channel("bioconductor-deseq2", "bioconda"))
  expect_equal(
    calls$args[[1]],
    c(
      "search",
      "--channel",
      "conda-forge",
      "--channel",
      "bioconda",
      "bioconductor-deseq2"
    )
  )

  local_mocked_bindings(
    run_pixi = function(...) {
      stop(structure(
        list(message = "not found", call = NULL),
        class = c("rpix_error_pixi", "error", "condition")
      ))
    }
  )
  expect_false(on_channel("r-nope", "conda-forge"))
})

test_that("on_channel() finds packages with Pixi", {
  skip_if_no_pixi()
  expect_true(on_channel("r-cli", "conda-forge"))
  expect_false(on_channel("r-surely-not-a-package-xyz", "conda-forge"))
})

test_that("project_dependencies() reads the default environment's packages", {
  local_mocked_bindings(
    pixi_info = function(root) {
      list(
        environments_info = data.frame(
          name = c("test", "default"),
          dependencies = I(list(c("r-testthat"), c("r-base", "r-cli")))
        )
      )
    }
  )
  expect_equal(project_dependencies("/p"), c("r-base", "r-cli"))
})
