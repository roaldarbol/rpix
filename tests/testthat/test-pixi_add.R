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

# Mock run_pixi() so the paths that need pixi and the network can run offline
local_mock_pixi <- function(
  channels = "conda-forge",
  error = NULL,
  env = parent.frame()
) {
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    project_channels = function(...) channels,
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      if (!is.null(error) && args[1] == "add") {
        stop(error)
      }
      invisible(list(status = 0))
    },
    .env = env
  )
  calls
}

pixi_error <- function(stderr) {
  structure(
    class = c("rpix_error_pixi", "error", "condition"),
    list(message = "pixi failed", call = NULL, stderr = stderr)
  )
}

test_that("pixi_add() only adds channels that aren't in the project yet", {
  calls <- local_mock_pixi(channels = "conda-forge")
  pixi_add("bioc::limma")
  expect_equal(
    calls$args[[1]],
    c("workspace", "channel", "add", "bioconda", "--no-install")
  )
  expect_equal(calls$args[[2]], c("add", "bioconda::bioconductor-limma"))

  calls <- local_mock_pixi(channels = c("conda-forge", "bioconda"))
  result <- pixi_add("bioc::limma")
  expect_length(calls$args, 1)
  expect_equal(result, list(status = 0))
})

test_that("pixi_add() hints at prefixes when a package isn't found", {
  local_mock_pixi(error = pixi_error("No candidates were found for r-gdal *."))
  expect_error(pixi_add("gdal"), class = "rpix_error_package_not_found")
})

test_that("pixi_add() passes on other pixi errors", {
  local_mock_pixi(error = pixi_error("Some other failure"))
  err <- expect_error(pixi_add("dplyr"), class = "rpix_error_pixi")
  expect_false(inherits(err, "rpix_error_package_not_found"))
})

test_that("pixi_add(), pixi_remove() and pixi_search() target the project in `path`", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  manifest <- file.path(root, "pixi.toml")
  in_other_dir <- function(command) grepl(manifest, command, fixed = TRUE)
  withr::local_dir(withr::local_tempdir())

  expect_true(in_other_dir(dry(pixi_add("dplyr", path = root, dry_run = TRUE))))
  expect_true(in_other_dir(dry(pixi_remove(
    "dplyr",
    path = root,
    dry_run = TRUE
  ))))
  expect_true(in_other_dir(dry(pixi_search(
    "dplyr",
    path = root,
    dry_run = TRUE
  ))))
})

test_that("pixi_add() explains packages that aren't built for the project's R", {
  stderr <- paste(
    readLines(test_path("fixtures", "pixi-r-version-error.txt")),
    collapse = "\n"
  )
  local_mock_pixi(error = pixi_error(stderr))
  expect_snapshot(pixi_add(c("languageserver", "praise")), error = TRUE)
  expect_error(pixi_add("praise"), class = "rpix_error_r_version")
})

test_that("not_built_for_r() reads Pixi's error", {
  stderr <- paste(
    readLines(test_path("fixtures", "pixi-r-version-error.txt")),
    collapse = "\n"
  )
  expect_equal(
    not_built_for_r(stderr),
    list(package = "r-praise", r_version = "4.5")
  )
  expect_null(not_built_for_r("No candidates were found for r-gdal *."))
})

# CRAN packages that aren't on conda-forge -------------------------------------

local_not_on_conda_forge <- function(
  missing,
  answer = NULL,
  env = parent.frame()
) {
  calls <- new.env()
  calls$add <- list()
  calls$asked <- character()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      if (
        args[1] == "add" &&
          any(c(missing, paste0("r-", missing)) %in% sub("[=<>].*$", "", args))
      ) {
        stop(pixi_error("No candidates were found for r-something *."))
      }
      invisible(list(status = 0))
    },
    on_channel = function(name, channel) !sub("^r-", "", name) %in% missing,
    project_channels = function(...) "conda-forge",
    is_interactive = function() !is.null(answer),
    ask_yes_no = function(question) {
      calls$asked <- c(calls$asked, question)
      answer
    },
    add_github_packages = function(packages, ...) calls$github <- packages,
    .env = env
  )
  calls
}

test_that("pixi_add() offers to build CRAN packages that aren't on conda-forge", {
  calls <- local_not_on_conda_forge("fortunes", answer = TRUE)

  expect_snapshot(pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1")))
  expect_equal(calls$github, c("github::cran/fortunes@1.5-4"))
  expect_equal(
    calls$asked,
    "Build it from CRAN's source (github.com/cran) with Pixi instead?"
  )
})

test_that("pixi_add() says how to build them when it can't ask, or the answer is no", {
  local_not_on_conda_forge(c("fortunes", "cowsay"))
  expect_snapshot(
    pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1")),
    error = TRUE
  )

  calls <- local_not_on_conda_forge(c("fortunes", "cowsay"), answer = FALSE)
  expect_snapshot(
    pixi_add(c("fortunes", "cowsay>=1")),
    error = TRUE
  )
  expect_null(calls$github)
})

test_that("pixi_add() doesn't offer it for packages that aren't from CRAN", {
  local_not_on_conda_forge("gdal-nope")
  expect_error(
    pixi_add("conda::gdal-nope"),
    "couldn't be found",
    class = "rpix_error_package_not_found"
  )
})

test_that("package_references() writes packages as pixi_add() takes them", {
  parsed <- parse_packages(c(
    "dplyr>=1.1",
    "bioc::DESeq2",
    "conda::gdal",
    "r-cli"
  ))
  expect_equal(
    package_references(parsed),
    c("cran::dplyr>=1.1", "bioc::DESeq2", "conda::gdal", "conda::r-cli")
  )
})

test_that("is_interactive() and ask_yes_no() ask R", {
  expect_equal(is_interactive(), interactive())
  local_mocked_bindings(
    askYesNo = function(question) question,
    .package = "utils"
  )
  expect_equal(ask_yes_no("Really?"), "Really?")
})
