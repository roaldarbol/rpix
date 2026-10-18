local_project_dir <- function(env = parent.frame()) {
  root <- local_pixi_project(env = env)
  withr::local_dir(root, .local_envir = env)
  withr::local_envvar(
    PIXI_WORKSPACE_ROOT = NA,
    PIXI_PROJECT_ROOT = NA,
    .local_envir = env
  )
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

test_that("pixi_remove() removes a Bioconductor package by its name", {
  local_project_dir()
  writeLines(
    c(
      "[dependencies]",
      'r-cli = "*"',
      'bioconductor-limma = "*"',
      "",
      "[feature.test.dependencies]",
      '"bioconductor-deseq2" = "*"',
      'bioconductor-cli = "*"'
    ),
    "pixi.toml"
  )
  expect_equal(
    dry(pixi_remove(c("limma", "DESeq2", "cli", "dplyr"), dry_run = TRUE)),
    "pixi remove bioconductor-limma bioconductor-deseq2 r-cli r-dplyr --manifest-path pixi.toml"
  )
})

test_that("pixi_remove() leaves the names as they are without a manifest", {
  expect_equal(
    with_bioconductor_names(parse_packages("limma"), withr::local_tempdir()),
    "r-limma"
  )
})

test_that("pixi_search() translates names", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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

test_that("pixi_search() looks for a Bioconductor package on bioconda", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())
  calls <- local_recorded_pixi()
  local_mocked_bindings(
    on_channel = function(name, channel) {
      name %in% c("r-cli", "bioconductor-limma")
    },
    # Pixi finds the package by its exact name
    search_names = function(args, ...) args[2]
  )
  expect_snapshot(pixi_search("limma"))
  expect_equal(
    calls$args[[1]],
    c("search", "bioconductor-limma", "--channel", "bioconda")
  )

  # On conda-forge, or on neither
  pixi_search("cli")
  pixi_search("nope")
  # A channel given is searched as is
  pixi_search("limma", channel = "conda-forge")
  expect_equal(
    calls$args[-1],
    list(
      c("search", "r-cli"),
      c("search", "r-nope"),
      c("search", "r-limma", "--channel", "conda-forge")
    )
  )
})

test_that("pixi_search() only shows an R package by its exact name", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())
  found <- list(noarch = data.frame(name = c("r-fauxpas", "r-fauxpas")))
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, json = FALSE, ...) {
      calls$args <- c(calls$args, list(args))
      if (json) found else invisible(list(status = 0))
    },
    # Not a Bioconductor package either
    on_channel = function(name, channel) FALSE
  )
  expect_snapshot(pixi_search("faux"), error = TRUE)
  expect_equal(calls$args, list(c("search", "r-faux")))

  found <- list()
  expect_snapshot(pixi_search("faux"), error = TRUE)

  found <- list(noarch = data.frame(name = c("r-fauxpas", "r-faux")))
  calls$args <- list()
  pixi_search("faux")
  expect_equal(calls$args, rep(list(c("search", "r-faux")), 2))

  # Conda names are left to Pixi
  calls$args <- list()
  pixi_search("conda::faux")
  expect_equal(calls$args, list(c("search", "faux")))
})

test_that("pixi_search() passes on Pixi's other errors", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())
  local_mocked_bindings(
    run_pixi = function(...) {
      stop(structure(
        list(message = "offline", call = NULL, stderr = "network error"),
        class = c("rpix_error_pixi", "error", "condition")
      ))
    }
  )
  expect_error(pixi_search("faux"), "offline", class = "rpix_error_pixi")
})

test_that("pixi_search() doesn't show a package that contains the name", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())
  expect_error(
    pixi_search("faux"),
    "r-fauxpas",
    class = "rpix_error_package_not_found"
  )
  output <- capture.output(pixi_search("cli"), type = "output")
  expect_true(any(grepl("r-cli", output)))
})

test_that("project_channels() reads the project's channels", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
      # pixi search --json finds every package
      if (args[1] == "search") {
        return(list(noarch = data.frame(name = args[length(args)])))
      }
      invisible(list(status = 0))
    },
    # A project with one environment, which Pixi installs by itself
    install_changed_environment = function(...) NULL,
    .env = env
  )
  calls
}

pixi_error <- function(stderr) {
  pixi_failure(stderr)
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
  local_mock_pixi(
    error = pixi_failure("No candidates were found for r-gdal *.")
  )
  # Not one rpix knows where to find
  local_mocked_bindings(on_channel = function(...) TRUE)
  expect_output(
    expect_error(pixi_add("gdal"), class = "rpix_error_package_not_found"),
    "No candidates"
  )
})

test_that("pixi_add() passes on other pixi errors, with Pixi's output", {
  local_mock_pixi(error = pixi_failure("Some other failure"))
  expect_output(
    err <- expect_error(pixi_add("dplyr"), class = "rpix_error_pixi"),
    "Some other failure"
  )
  expect_false(inherits(err, "rpix_error_package_not_found"))
  expect_match(conditionMessage(err), "output above")
})

test_that("pixi_add() shows Pixi's output once it has added the packages", {
  calls <- list()
  local_mocked_bindings(
    run_pixi = function(args, echo = FALSE, announce = echo, ...) {
      calls <<- c(calls, list(list(echo = echo, announce = announce)))
      invisible(list(status = 0, output = "Added r-dplyr\n"))
    },
    project_channels = function(...) "conda-forge",
    install_changed_environment = function(...) NULL
  )
  expect_output(pixi_add("dplyr"), "Added r-dplyr")
  expect_equal(calls[[1]], list(echo = FALSE, announce = TRUE))

  # Or as it runs
  withr::local_options(rpix.verbose = TRUE)
  expect_silent(pixi_add("dplyr"))
  expect_equal(calls[[2]], list(echo = TRUE, announce = TRUE))
})

test_that("pixi_add(), pixi_remove() and pixi_search() target the project in `path`", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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

read_fixture <- function(name) {
  paste(
    readLines(test_path("fixtures", name), encoding = "UTF-8"),
    collapse = "\n"
  )
}

test_that("pixi_add() explains packages that aren't built for the project's R", {
  local_mock_pixi(error = pixi_error(read_fixture("pixi-r-version-error.txt")))
  # Pixi's output, which comes first, is in the fixture
  expect_snapshot(
    invisible(capture.output(pixi_add(c("languageserver", "praise")))),
    error = TRUE
  )
  expect_output(
    expect_error(pixi_add("praise"), class = "rpix_error_r_version")
  )
  # A package Pixi names that wasn't asked for, e.g. a dependency
  expect_output(
    expect_error(
      pixi_add("languageserver"),
      "r-praise isn't built",
      class = "rpix_error_r_version"
    )
  )
})

test_that("pixi_add() suggests R in place of the project's, as valid R", {
  # Pixi's error for r-withr>=3.0.3 in a project with R 4.6
  error <- pixi_error(read_fixture("pixi-r-version-constraint.txt"))
  local_mock_pixi(error = error)
  # A project with the isolation already, so pixi_add() doesn't add it with R
  root <- local_pixi_project(
    content = c("[dependencies]", paste0(isolation_package, ' = "*"'))
  )
  withr::local_dir(root)
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  packages <- c(
    "r-base>=4.6",
    "withr>=3.0.3",
    "cli>=3.6.6",
    "bioc::limma",
    "conda::gdal",
    "RColorBrewer>=1.1_3",
    "viridisLite>=0.4.3",
    "github::me/mypkg@main"
  )
  expect_output(
    err <- expect_error(pixi_add(packages), class = "rpix_error_r_version")
  )
  expect_snapshot(invisible(capture.output(pixi_add(packages))), error = TRUE)
  command <- regmatches(
    conditionMessage(err),
    regexpr("pixi_add\\(c\\(.*\\)\\)", conditionMessage(err))
  )
  expect_equal(
    eval(parse(text = sub("^pixi_add", "c", command))[[1]][[2]]),
    c(
      "r-base=4.5",
      "withr>=3.0.3",
      "cli>=3.6.6",
      "bioc::limma",
      "conda::gdal",
      "RColorBrewer>=1.1_3",
      "viridisLite>=0.4.3",
      "github::me/mypkg@main"
    )
  )
})

test_that("pixi_add() explains that an old version isn't built for a newer R", {
  # Pixi's error for r-ggplot2==3.4.4 in a project with R 4.5
  local_mock_pixi(error = pixi_error(read_fixture("pixi-r-version-pinned.txt")))
  expect_snapshot(
    invisible(capture.output(pixi_add(c("dplyr", "ggplot2==3.4.4")))),
    error = TRUE
  )
  # A version series isn't a tag to build from source
  expect_snapshot(
    invisible(capture.output(pixi_add("ggplot2", versions = "3.4.4"))),
    error = TRUE
  )
})

test_that("pixi_add() only offers a build from source for CRAN packages", {
  pinned <- gsub(
    "r-ggplot2",
    "bioconductor-limma",
    read_fixture("pixi-r-version-pinned.txt"),
    fixed = TRUE
  )
  local_mock_pixi(
    channels = c("conda-forge", "bioconda"),
    error = pixi_error(pinned)
  )
  expect_snapshot(
    invisible(capture.output(pixi_add("bioc::limma==3.4.4"))),
    error = TRUE
  )
})

test_that("not_built_for_r() reads Pixi's error", {
  expect_equal(
    not_built_for_r(read_fixture("pixi-r-version-error.txt")),
    list(package = "r-praise", r_version = "4.5")
  )
  expect_equal(
    not_built_for_r(read_fixture("pixi-r-version-constraint.txt")),
    list(package = "r-withr", r_version = "4.5")
  )
  expect_equal(
    not_built_for_r(read_fixture("pixi-r-version-pinned.txt")),
    list(package = "r-ggplot2", r_version = "4.3")
  )
  expect_null(not_built_for_r("No candidates were found for r-gdal *."))
})

# CRAN packages that aren't on conda-forge -------------------------------------

local_not_on_conda_forge <- function(
  missing,
  answer = NULL,
  bioc = character(),
  on_cran = c("cowsay", "dplyr", "fortunes", "praise"),
  env = parent.frame()
) {
  calls <- new.env()
  calls$add <- list()
  calls$asked <- character()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      if (args[1] == "add") {
        calls$add <- c(calls$add, list(args))
      }
      if (
        args[1] == "add" &&
          any(
            c(missing, paste0("r-", missing)) %in%
              sub("^.*::", "", sub("[=<>].*$", "", args))
          )
      ) {
        stop(pixi_failure("No candidates were found for r-something *."))
      }
      invisible(list(status = 0))
    },
    on_channel = function(name, channel) {
      if (startsWith(name, "bioconductor-")) {
        sub("^bioconductor-", "", name) %in% tolower(bioc)
      } else {
        !sub("^r-", "", name) %in% missing
      }
    },
    project_channels = function(...) "conda-forge",
    is_interactive = function() !is.null(answer),
    ask_yes_no = function(question) {
      calls$asked <- c(calls$asked, question)
      answer
    },
    add_github_packages = function(packages, ...) calls$github <- packages,
    cran_packages = function() on_cran,
    .env = env
  )
  calls
}

test_that("pixi_add() offers to build CRAN packages that aren't on conda-forge", {
  calls <- local_not_on_conda_forge("fortunes", answer = TRUE)

  expect_snapshot(pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1")))
  expect_equal(calls$github, c("github::cran/fortunes@1.5-4"))
  expect_equal(calls$asked, "Would you like to build it from source?")
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

test_that("pixi_add() doesn't offer it for packages that aren't on CRAN", {
  calls <- local_not_on_conda_forge(c("dplyrr", "zzqqxx"), answer = TRUE)
  expect_snapshot(pixi_add("dplyrr"), error = TRUE)
  expect_snapshot(pixi_add(c("dplyrr", "zzqqxx", "praise")), error = TRUE)
  expect_length(calls$asked, 0)

  # When CRAN can't be reached, it offers it anyway
  local_not_on_conda_forge("dplyrr", on_cran = NULL)
  expect_error(pixi_add("dplyrr"), "github::cran/dplyrr", fixed = TRUE)
})

test_that("cran_packages() lists CRAN's packages, from the CRAN repository", {
  skip_on_cran()
  skip_if_offline("cloud.r-project.org")
  withr::local_options(repos = c(CRAN = "@CRAN@"))
  expect_true(all(c("dplyr", "praise") %in% cran_packages()))
  withr::local_options(repos = c(CRAN = "http://127.0.0.1:9"))
  expect_null(cran_packages())
})

test_that("close_names() finds the closest names, ignoring case", {
  names <- c("dplyr", "dbplyr", "plyr", "Rcpp", "praise")
  expect_equal(close_names("dplyrr", names), "dplyr")
  expect_equal(close_names("rcpp", names), "Rcpp")
  expect_equal(close_names("zzqqxx", names), character())
})

test_that("pixi_add() explains, rather than offers, a build from source in a project with a date", {
  calls <- local_not_on_conda_forge("fortunes", answer = TRUE)
  root <- local_pixi_project(
    content = c("[workspace]", 'exclude-newer = "2025-06-01"')
  )

  expect_snapshot(
    pixi_add(c("praise", "fortunes"), path = root),
    error = TRUE
  )
  expect_length(calls$asked, 0)
  expect_null(calls$github)
})

test_that("pixi_add() doesn't offer it for packages that aren't from CRAN", {
  local_not_on_conda_forge("gdal-nope")
  expect_output(
    expect_error(
      pixi_add("conda::gdal-nope"),
      "couldn't be found",
      class = "rpix_error_package_not_found"
    ),
    "No candidates were found"
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

test_that("is_interactive() asks R", {
  expect_equal(is_interactive(), interactive())
})

test_that("ask_yes_no() asks, then offers Yes and No", {
  choice <- 1
  local_mocked_bindings(
    menu = function(choices) {
      expect_equal(choices, c("Yes", "No"))
      choice
    },
    .package = "utils"
  )
  expect_snapshot(answer <- ask_yes_no("Would you like to?"))
  expect_true(answer)

  # No, or Esc
  for (choice in c(2, 0)) {
    expect_false(suppressMessages(ask_yes_no("Would you like to?")))
  }
})

test_that("ask_choice() asks, then offers the choices", {
  choice <- 2
  local_mocked_bindings(
    menu = function(choices) {
      expect_equal(choices, c("a", "b"))
      choice
    },
    .package = "utils"
  )
  expect_equal(suppressMessages(ask_choice("Which?", c("a", "b"))), 2)
  choice <- 0
  expect_equal(suppressMessages(ask_choice("Which?", c("a", "b"))), NA_integer_)
})

test_that("pixi_add() finds Bioconductor packages on bioconda", {
  calls <- local_not_on_conda_forge(c("deseq2", "DESeq2"), bioc = "DESeq2")

  expect_snapshot(pixi_add(c("praise", "DESeq2>=1.40")))
  # It tries conda-forge first, then adds DESeq2 from bioconda
  expect_equal(
    utils::tail(calls$add, 1)[[1]][1:3],
    c("add", "r-praise", "bioconda::bioconductor-deseq2>=1.40")
  )
})

test_that("pixi_add() looks on bioconda with channel = \"bioconda\" too", {
  calls <- local_not_on_conda_forge(c("deseq2", "DESeq2"), bioc = "DESeq2")
  suppressMessages(pixi_add("DESeq2", channel = "bioconda"))
  expect_equal(
    utils::tail(calls$add, 1)[[1]][1:2],
    c("add", "bioconda::bioconductor-deseq2")
  )
})

test_that("on_bioconda() looks for bioconductor-<name> on bioconda", {
  local_mocked_bindings(
    on_channel = function(name, channel) {
      expect_equal(channel, "bioconda")
      name == "bioconductor-deseq2"
    }
  )
  parsed <- parse_packages(c("DESeq2", "fortunes"))
  expect_equal(on_bioconda(parsed, 1:2), c(TRUE, FALSE))
})

test_that("pixi_add() adds the isolation from the personal library with R", {
  root <- local_project_dir()

  expect_message(
    command <- pixi_add(c("r-base=4.4", "dplyr"), dry_run = TRUE),
    "conda-ecosystem-user-package-isolation"
  )
  expect_match(
    command,
    "r-base=4.4 r-dplyr conda-ecosystem-user-package-isolation",
    fixed = TRUE
  )

  # Not in another feature (pixi_add_environment() sees to those), when the
  # packages include it, without R, or when the default feature has it
  expect_no_match(
    dry(pixi_add("r-base=4.4", feature = "r44", dry_run = TRUE)),
    "isolation"
  )
  expect_equal(
    dry(pixi_add(
      c("r-base", "conda::conda-ecosystem-user-package-isolation"),
      dry_run = TRUE
    )),
    "pixi add r-base conda-ecosystem-user-package-isolation --manifest-path pixi.toml"
  )
  expect_no_match(dry(pixi_add("dplyr", dry_run = TRUE)), "isolation")
  writeLines(
    c("[dependencies]", 'conda-ecosystem-user-package-isolation = "*"'),
    file.path(root, "pixi.toml")
  )
  expect_no_match(dry(pixi_add("r-base", dry_run = TRUE)), "isolation")
})
