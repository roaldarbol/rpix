tasks_df <- function() {
  new_rpix_df(
    data.frame(
      name = c("test", "render", "check", "inline"),
      command = c(
        "Rscript -e 'devtools::test()'",
        "quarto render {{ file }}",
        "R CMD check",
        NA
      ),
      description = c(
        "Run the tests",
        NA,
        "Check the package, with a description long enough to wrap onto a second line of the console",
        NA
      ),
      feature = c("default", "default", "r44", NA),
      environments = I(list(
        c("default", "r44"),
        c("default", "r44"),
        "r44",
        "r44"
      )),
      depends_on = I(list(character(), "test", character(), "test")),
      args = I(list(character(), "file", character(), character())),
      stringsAsFactors = FALSE
    ),
    "rpix_tasks"
  )
}

test_that("tasks print by feature, with what they need", {
  expect_snapshot({
    tasks_df()
    tasks_df()[1:2, ]
    tasks_df()[0, ]
    tasks_df()[, c("name", "command", "description", "feature")]
  })
})

test_that("environments print one per line", {
  envs <- new_rpix_df(
    data.frame(
      name = c("default", "r44"),
      features = I(list("default", c("r44", "test"))),
      platforms = I(list(c("osx-arm64", "linux-64"), "linux-64")),
      solve_group = c(NA, "main"),
      stringsAsFactors = FALSE
    ),
    "rpix_environments"
  )
  expect_snapshot(envs)
})

packages_df <- function(n) {
  names <- sprintf("r-pkg%02d", seq_len(n))
  new_rpix_df(
    data.frame(
      name = names,
      version = rep("1.0", n),
      r_package = sub("r-", "", names),
      explicit = seq_len(n) %% 2 == 1,
      channel = rep("conda-forge", n),
      kind = rep("conda", n),
      build = rep("h0", n),
      stringsAsFactors = FALSE
    ),
    "rpix_packages",
    environment = "r44"
  )
}

test_that("packages print as a table, cut short when there are many", {
  expect_snapshot({
    packages_df(3)
    packages_df(31)
    print(packages_df(31), n = Inf)
    packages_df(0)
  })
})

test_that("explicit packages are bold with colours", {
  local_reproducible_output(crayon = TRUE)
  expect_snapshot(packages_df(2))
})

test_that("printing falls back to data frames without the columns it needs", {
  expect_snapshot({
    tasks_df()[, c("name", "command")]
    packages_df(2)[, c("name", "version")]
  })
  envs <- new_rpix_df(data.frame(name = "default"), "rpix_environments")
  expect_output(print(envs), "default")
})

test_that("info prints Pixi, the project and its environments", {
  info <- structure(
    list(
      version = "0.81.0",
      platform = "osx-arm64",
      cache_dir = "/cache",
      project_info = list(name = "demo", manifest_path = "/demo/pixi.toml"),
      environments_info = data.frame(
        name = c("default", "r44"),
        features = I(list("default", "r44")),
        solve_group = c(NA, "main"),
        dependencies = I(list(c("r-base", "r-cli"), "r-base")),
        pypi_dependencies = I(list(NULL, NULL)),
        platforms = I(list(
          data.frame(name = c("osx-arm64", "linux-64")),
          data.frame(name = "linux-64")
        )),
        tasks = I(list(c("test", "check"), character())),
        channels = I(list("conda-forge", "conda-forge")),
        prefix = c("/demo/.pixi/envs/default", "/demo/.pixi/envs/r44")
      )
    ),
    class = "rpix_info"
  )
  expect_snapshot(info)

  info$project_info <- NULL
  info$environments_info <- list()
  expect_snapshot(info)
})

test_that("the functions return classed results", {
  local_mocked_bindings(
    run_pixi = function(args, ...) list(version = "0.81.0")
  )
  expect_s3_class(pixi_info(), "rpix_info")
})
