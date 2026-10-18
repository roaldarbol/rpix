# A project with a cached activation, and environments whose R was installed
# where `installed_in` says
local_moved_project <- function(
  cached_root = NULL,
  installed_in = character(),
  env = parent.frame()
) {
  root <- local_pixi_project(env = env)
  if (!is.null(cached_root)) {
    cache <- file.path(root, ".pixi", "activation-env-v0")
    dir.create(cache, recursive = TRUE)
    jsonlite::write_json(
      list(
        hash = "9501c602ad1cb1e6",
        environment_variables = list(
          PIXI_WORKSPACE_ROOT = cached_root,
          CONDA_PREFIX = file.path(cached_root, ".pixi", "envs", "default")
        )
      ),
      file.path(cache, "activation_default.json"),
      auto_unbox = TRUE
    )
  }
  for (name in names(installed_in)) {
    bin <- file.path(root, ".pixi", "envs", name, "bin")
    dir.create(bin, recursive = TRUE)
    home <- file.path(installed_in[[name]], ".pixi", "envs", name, "lib", "R")
    writeLines(
      c(
        "#!/bin/bash",
        "# Shell wrapper for R executable.",
        "",
        paste0("R_HOME_DIR=\"", home, "\"")
      ),
      file.path(bin, "R")
    )
  }
  root
}

cache_file <- function(root) {
  file.path(root, ".pixi", "activation-env-v0", "activation_default.json")
}

# remove_stale_activation_cache() ---------------------------------------------

test_that("keeps the activation cache of the project's own location", {
  root <- local_moved_project()
  expect_false(remove_stale_activation_cache(root))

  jsonlite::write_json(
    list(environment_variables = list(PIXI_WORKSPACE_ROOT = root)),
    {
      dir.create(dirname(cache_file(root)), recursive = TRUE)
      cache_file(root)
    },
    auto_unbox = TRUE
  )
  expect_false(remove_stale_activation_cache(root))
  expect_true(file.exists(cache_file(root)))
})

test_that("removes the activation cache of another location, and says so", {
  root <- local_moved_project(cached_root = "/old/place/project")
  expect_snapshot(remove_stale_activation_cache(root))
  expect_false(file.exists(cache_file(root)))

  root <- local_moved_project(cached_root = "/old/place/project")
  expect_silent(expect_true(remove_stale_activation_cache(root, quiet = TRUE)))
})

test_that("reads the location older Pixi versions cached", {
  root <- local_moved_project()
  dir.create(dirname(cache_file(root)), recursive = TRUE)
  jsonlite::write_json(
    list(environment_variables = list(PIXI_PROJECT_ROOT = "/old/project")),
    cache_file(root),
    auto_unbox = TRUE
  )
  expect_true(remove_stale_activation_cache(root, quiet = TRUE))
})

test_that("leaves cache files it can't read to Pixi", {
  root <- local_moved_project()
  dir.create(dirname(cache_file(root)), recursive = TRUE)
  writeLines("not json", cache_file(root))
  expect_false(remove_stale_activation_cache(root))
  expect_true(file.exists(cache_file(root)))
})

# moved_environments() ---------------------------------------------------------

test_that("finds environments installed in another location", {
  root <- local_moved_project()
  expect_length(moved_environments(root), 0)

  root <- local_moved_project(
    installed_in = c(default = "/old/project", test = "/old/project")
  )
  # The project's own
  writeLines(
    paste0("R_HOME_DIR=", file.path(root, ".pixi/envs/own/lib/R")),
    {
      dir.create(
        file.path(root, ".pixi", "envs", "own", "bin"),
        recursive = TRUE
      )
      file.path(root, ".pixi", "envs", "own", "bin", "R")
    }
  )
  # Without R, or with an R script rpix doesn't know
  dir.create(file.path(root, ".pixi", "envs", "python"))
  dir.create(file.path(root, ".pixi", "envs", "odd", "bin"), recursive = TRUE)
  writeLines("exec R", file.path(root, ".pixi", "envs", "odd", "bin", "R"))

  # On Windows, with the drive
  old <- normalizePath("/old/project", winslash = "/", mustWork = FALSE)
  expect_equal(moved_environments(root), c(default = old, test = old))
})

test_that("says to reinstall moved environments", {
  expect_snapshot({
    cli::cli_bullets(moved_environments_bullets(c(default = "/old/project")))
    cli::cli_bullets(moved_environments_bullets(
      c(default = "/old/project", test = "/old/project")
    ))
  })
})

# moved_project() -------------------------------------------------------------

test_that("fixes and explains what moving the project broke", {
  expect_null(moved_project(local_moved_project()))

  root <- local_moved_project(cached_root = "/old/project")
  expect_equal(moved_project(root), stale_cache_bullet)
  expect_false(file.exists(cache_file(root)))

  root <- local_moved_project(
    cached_root = "/old/project",
    installed_in = c(default = "/old/project")
  )
  bullets <- moved_project(root)
  expect_equal(names(bullets), c("!", "!", "i"))
  expect_match(bullets[[2]], "/old/project", fixed = TRUE)
})
