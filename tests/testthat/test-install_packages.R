test_that("rpix's install.packages() goes in front of utils' one", {
  withr::defer(if ("rpix:install" %in% search()) detach("rpix:install"))

  expect_true(attach_install_packages("/p", now = TRUE))
  expect_true("rpix:install" %in% search())
  expect_lt(match("rpix:install", search()), match("package:utils", search()))
  # Attaching again replaces it
  attach_install_packages("/p", now = TRUE)
  expect_equal(sum(search() == "rpix:install"), 1)

  local_mocked_bindings(install_with_pixi = function(pkgs, ..., root) {
    list(pkgs, root)
  })
  expect_equal(
    get("install.packages", pos = "rpix:install")("dplyr"),
    list("dplyr", "/p")
  )
})

test_that("during startup, it waits for utils to be attached", {
  hook <- packageEvent("utils", "attach")
  old <- getHook(hook)
  withr::defer(setHook(hook, old, "replace"))
  withr::defer(if ("rpix:install" %in% search()) detach("rpix:install"))

  expect_false(attach_install_packages("/p", now = FALSE))
  expect_false("rpix:install" %in% search())
  hooks <- getHook(hook)
  expect_length(hooks, length(old) + 1)
  hooks[[length(hooks)]]("utils", "/lib")
  expect_true("rpix:install" %in% search())
})

local_install <- function(
  found,
  dependencies = list(default = "r-base"),
  environment = "default",
  env = parent.frame()
) {
  calls <- new.env()
  local_mocked_bindings(
    environment_dependencies = function(root) dependencies,
    r_home = function() file.path("/p/.pixi/envs", environment, "lib/R"),
    find_r_packages = function(packages) found[packages],
    pixi_add = function(packages, path) {
      calls$added <- packages
      calls$path <- path
    },
    utils_install_packages = function(...) calls$utils <- list(...),
    .env = env
  )
  calls
}

test_that("install.packages() adds packages with Pixi", {
  calls <- local_install(c(dplyr = "cran::dplyr", DESeq2 = "bioc::DESeq2"))

  expect_snapshot(install_with_pixi(c("dplyr", "DESeq2"), root = "/p"))
  expect_equal(calls$added, c("cran::dplyr", "bioc::DESeq2"))
  expect_equal(calls$path, "/p")

  # Arguments Pixi has its own way of doing are fine
  install_with_pixi("dplyr", dependencies = TRUE, quiet = TRUE, root = "/p")
  expect_equal(calls$added, "cran::dplyr")
})

test_that("install.packages() leaves packages not on conda-forge to pixi_add()", {
  calls <- local_install(c(dplyr = "cran::dplyr", notonconda = NA))

  # pixi_add() offers to build them from CRAN's source
  suppressMessages(install_with_pixi(c("dplyr", "notonconda"), root = "/p"))
  expect_equal(calls$added, c("cran::dplyr", "cran::notonconda"))
})

test_that("install.packages() says how to update packages in pixi.toml", {
  calls <- local_install(
    c(dplyr = "cran::dplyr", tidyr = "cran::tidyr", quarto = "cran::quarto"),
    dependencies = list(
      default = c("r-base", "r-dplyr", "bioconductor-deseq2", "quarto"),
      r44 = c("r-base", "r-tidyr")
    )
  )

  expect_snapshot({
    install_with_pixi("dplyr", root = "/p")
    install_with_pixi(c("dplyr", "DESeq2", "tidyr"), root = "/p")
  })
  # Only the ones that aren't there yet are added
  expect_equal(calls$added, "cran::tidyr")

  # quarto the conda package isn't the R package
  calls$added <- NULL
  suppressMessages(install_with_pixi("quarto", root = "/p"))
  expect_equal(calls$added, "cran::quarto")
})

test_that("install.packages() looks in pixi.toml for the environment R runs in", {
  calls <- local_install(
    c(dplyr = "cran::dplyr", tidyr = "cran::tidyr"),
    dependencies = list(default = "r-dplyr", r44 = "r-tidyr"),
    environment = "r44"
  )

  suppressMessages(install_with_pixi(c("dplyr", "tidyr"), root = "/p"))
  expect_equal(calls$added, "cran::dplyr")
})

test_that("install.packages() adds packages when it can't read pixi.toml", {
  calls <- local_install(c(dplyr = "cran::dplyr"))
  local_mocked_bindings(environment_dependencies = function(root) {
    stop("no Pixi")
  })

  suppressMessages(install_with_pixi("dplyr", root = "/p"))
  expect_equal(calls$added, "cran::dplyr")
})

test_that("install.packages() explains what Pixi can't do", {
  local_install(c(dplyr = "cran::dplyr"))

  expect_snapshot(error = TRUE, {
    install_with_pixi(
      "dplyr",
      lib = "/lib",
      repos = "https://cran.r-project.org",
      root = "/p"
    )
  })
})

test_that("install.packages() takes packages from conda-forge, not `repos`", {
  calls <- local_install(c(later = "cran::later", rstudioapi = "rstudioapi"))

  # As VS Code's R extension installs sess's dependencies
  expect_snapshot(install_with_pixi(
    c("later", "rstudioapi"),
    repos = "https://cran.r-project.org/",
    root = "/p"
  ))
  expect_equal(calls$added, c("cran::later", "rstudioapi"))
})

test_that("install.packages() leaves package files to utils", {
  calls <- local_install(c(dplyr = "cran::dplyr"))

  # As VS Code's R extension installs sess
  expect_snapshot(install_with_pixi(
    "/ext/sess",
    repos = NULL,
    type = "source",
    root = "/p"
  ))
  expect_equal(calls$utils, list("/ext/sess", repos = NULL, type = "source"))
  expect_null(calls$added)

  # A folder in the working directory, or an archive, for which utils infers
  # `repos = NULL`
  suppressMessages(install_with_pixi("sess", repos = NULL, root = "/p"))
  expect_equal(calls$utils, list("sess", repos = NULL))
  suppressMessages(install_with_pixi(c("a.tar.gz", "b.zip"), root = "/p"))
  expect_equal(calls$utils, list(c("a.tar.gz", "b.zip")))
  expect_null(calls$added)
})

test_that("install.packages() can be left to utils", {
  calls <- local_install(c(dplyr = "cran::dplyr"))
  withr::local_options(rpix.install_packages = FALSE)

  install_with_pixi("dplyr", lib = "/lib", root = "/p")
  expect_equal(calls$utils, list("dplyr", lib = "/lib"))
  expect_null(calls$added)
})

test_that("utils_install_packages() calls utils' install.packages()", {
  expect_no_error(utils_install_packages(character(), repos = NULL))
})
