# Record the arguments pixi is called with
local_recorded_pixi <- function(
  result = invisible(list(status = 0)),
  env = parent.frame()
) {
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      result
    },
    .env = env
  )
  calls
}

test_that("pixi_add() and pixi_remove() add to a feature or platform", {
  calls <- local_recorded_pixi()
  local_mocked_bindings(project_channels = function() "conda-forge")

  pixi_add("testthat", feature = "test", platform = "linux-64")
  pixi_remove("testthat", feature = "test")
  pixi_add("dplyr")

  expect_equal(
    calls$args[[1]],
    c("add", "r-testthat", "--feature", "test", "--platform", "linux-64")
  )
  expect_equal(calls$args[[2]], c("remove", "r-testthat", "--feature", "test"))
  expect_equal(calls$args[[3]], c("add", "r-dplyr"))
})

test_that("pixi_environments() lists environments with their features", {
  local_recorded_pixi(list(
    environments_info = data.frame(
      name = c("default", "r44"),
      features = I(list("default", c("r44", "default"))),
      solve_group = c(NA, "main"),
      platforms = I(list(
        data.frame(name = "osx-64"),
        data.frame(name = c("osx-64", "linux-64"))
      ))
    )
  ))

  envs <- pixi_environments()
  expect_equal(envs$name, c("default", "r44"))
  expect_equal(envs$features[[2]], c("r44", "default"))
  expect_equal(envs$platforms[[2]], c("osx-64", "linux-64"))
  expect_equal(envs$solve_group, c(NA, "main"))
})

test_that("pixi_environments() gives a character solve_group without solve groups", {
  local_recorded_pixi(list(
    environments_info = data.frame(
      name = "default",
      features = I(list("default")),
      platforms = I(list(data.frame(name = "osx-64")))
    )
  ))
  expect_identical(pixi_environments()$solve_group, NA_character_)
})

test_that("pixi_add_environment() and pixi_remove_environment() build the commands", {
  calls <- local_recorded_pixi()

  pixi_add_environment(
    "r44",
    features = c("r44", "test"),
    solve_group = "main",
    default_feature = FALSE
  )
  pixi_add_environment("plain", overwrite = TRUE)
  pixi_remove_environment("r44")

  expect_equal(
    calls$args[[1]],
    c(
      "workspace",
      "environment",
      "add",
      "r44",
      "--feature",
      "r44",
      "--feature",
      "test",
      "--solve-group",
      "main",
      "--no-default-feature"
    )
  )
  expect_equal(
    calls$args[[2]],
    c("workspace", "environment", "add", "plain", "--force")
  )
  expect_equal(calls$args[[3]], c("workspace", "environment", "remove", "r44"))
})

test_that("pixi_add_channel() and pixi_add_platform() build the commands", {
  calls <- local_recorded_pixi()
  pixi_add_channel(c("bioconda", "my-channel"))
  pixi_add_platform("win-64")
  expect_equal(
    calls$args[[1]],
    c("workspace", "channel", "add", "bioconda", "my-channel")
  )
  expect_equal(calls$args[[2]], c("workspace", "platform", "add", "win-64"))
})

test_that("install, update, upgrade and lock build the commands", {
  calls <- local_recorded_pixi()

  pixi_install()
  pixi_install(environment = "r44")
  pixi_install(all = TRUE)
  pixi_update()
  pixi_update(c("dplyr", "bioc::limma"), environment = "r44")
  pixi_upgrade()
  pixi_upgrade("dplyr", feature = "test")
  pixi_lock()

  expect_equal(
    calls$args,
    list(
      "install",
      c("install", "--environment", "r44"),
      c("install", "--all"),
      "update",
      c("update", "r-dplyr", "bioconductor-limma", "--environment", "r44"),
      "upgrade",
      c("upgrade", "r-dplyr", "--feature", "test"),
      "lock"
    )
  )
})

test_that("environments work with a real Pixi project", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  envs <- pixi_environments(dir)
  expect_equal(envs$name, "default")
  expect_equal(envs$features[[1]], "default")
  expect_type(envs$solve_group, "character")
})
