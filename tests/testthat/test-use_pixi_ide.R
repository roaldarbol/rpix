# A Pixi project to set IDEs up in, with pixi calls recorded instead of run
local_ide_project <- function(platforms = "osx-arm64", env = parent.frame()) {
  root <- normalizePath(
    withr::local_tempdir(.local_envir = env),
    winslash = "/"
  )
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, .local_envir = env)
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    project_platforms = function(path) platforms,
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      invisible(list(status = 0))
    },
    .env = env
  )
  calls$root <- root
  calls
}

read_settings <- function(root) {
  jsonlite::read_json(file.path(root, ".vscode", "settings.json"))
}

# use_pixi_rstudio() -----------------------------------------------------------

test_that("adds an rstudio task for each platform, and a .Rproj file", {
  p <- local_ide_project(platforms = c("osx-arm64", "linux-64", "win-64"))
  rproj <- paste0(basename(p$root), ".Rproj")

  suppressMessages(use_pixi_rstudio(p$root))

  expect_true(file.exists(file.path(p$root, rproj)))
  expect_length(p$args, 3)
  expect_equal(
    p$args[[1]][1:6],
    c(
      "task",
      "add",
      "rstudio",
      paste("open -n -a RStudio", rproj),
      "--platform",
      "osx-arm64"
    )
  )
  expect_equal(p$args[[2]][4], paste("rstudio", rproj))
  expect_equal(
    p$args[[3]][4],
    paste('"C:/Program Files/RStudio/rstudio.exe"', rproj)
  )
  expect_true(
    "RSTUDIO_WHICH_R=$CONDA_PREFIX/lib/R/bin/x64/R.exe" %in% p$args[[3]]
  )
})

test_that("uses an existing .Rproj file, and skips unknown platforms", {
  p <- local_ide_project(platforms = c("osx-64", "emscripten-wasm32"))
  writeLines("Version: 1.0", file.path(p$root, "mine.Rproj"))

  suppressMessages(use_pixi_rstudio(p$root))

  expect_equal(list.files(p$root, pattern = "\\.Rproj$"), "mine.Rproj")
  expect_length(p$args, 1)
  expect_equal(p$args[[1]][4], "open -n -a RStudio mine.Rproj")
})

# use_pixi_positron() ----------------------------------------------------------

test_that("turns on Pixi discovery, keeping other settings", {
  p <- local_ide_project()
  dir.create(file.path(p$root, ".vscode"))
  writeLines(
    '{"editor.tabSize": 2, "files.exclude": ["a"]}',
    file.path(p$root, ".vscode", "settings.json")
  )

  suppressMessages(use_pixi_positron(p$root))

  expect_equal(
    read_settings(p$root),
    list(
      editor.tabSize = 2L,
      files.exclude = list("a"),
      positron.r.interpreters.pixiDiscovery = TRUE
    )
  )
})

test_that("tells comments from URLs", {
  expect_true(has_json_comments(c("{", "  // a comment", "}")))
  expect_true(has_json_comments('{"a": 1} /* block */'))
  expect_true(has_json_comments('{"a": 1, // trailing'))
  expect_false(has_json_comments('{"url": "https://example.com"}'))
})

test_that("refuses to change settings with comments", {
  p <- local_ide_project()
  dir.create(file.path(p$root, ".vscode"))
  file <- file.path(p$root, ".vscode", "settings.json")
  writeLines(c("{", "  // a comment", '  "editor.tabSize": 2', "}"), file)

  expect_error(use_pixi_positron(p$root), "pixiDiscovery")
  expect_length(readLines(file), 4)
})

# use_pixi_vscode() ------------------------------------------------------------

test_that("adds languageserver and points the R extension at the environment's R", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() FALSE)

  suppressMessages(use_pixi_vscode(p$root))

  expect_equal(p$args[[1]], c("add", "r-languageserver"))
  r <- "${workspaceFolder}/.pixi/envs/default/bin/R"
  expect_equal(
    read_settings(p$root),
    list(r.executablePath = r, r.consolePath = r)
  )
})

test_that("leaves R to the PATH on Windows", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() TRUE)

  expect_message(use_pixi_vscode(p$root), "pixi run code")
  expect_false(file.exists(file.path(p$root, ".vscode", "settings.json")))
})

# Helpers ----------------------------------------------------------------------

test_that("the IDE helpers need a Pixi project", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  expect_error(use_pixi_positron(withr::local_tempdir()), "no Pixi project")
})

test_that("project_platforms() reads the project's platforms", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(
    c("init", dir, "--platform", "linux-64", "--platform", "win-64"),
    project = "none"
  )
  expect_setequal(project_platforms(dir), c("linux-64", "win-64"))
})
