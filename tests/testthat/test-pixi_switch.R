# A project with an .Rproj file, and pixi_switch()'s calls to Pixi recorded
local_switch_project <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines("Version: 1.0", file.path(dir, "demo.Rproj"))
  calls <- local_recorded_pixi(env = env)
  local_mocked_bindings(
    require_project = function(path) dir,
    pixi_environments = function(path) data.frame(name = c("default", "r44")),
    .env = env
  )
  calls$dir <- dir
  calls
}

test_that("pixi_switch() needs an environment of the project", {
  local_switch_project()
  expect_snapshot(pixi_switch("r43", ide = "rstudio"), error = TRUE)
})

test_that("pixi_switch() installs the environment, and shows how to start it", {
  calls <- local_switch_project()
  local_mocked_bindings(detect_ide = function() NA_character_)

  expect_snapshot(r <- pixi_switch("r44"))
  expect_equal(calls$args[[1]], c("install", "--environment", "r44"))
  expect_equal(r, environment_r(calls$dir, "r44"))
})

test_that("pixi_switch() starts a new RStudio with the environment's R", {
  calls <- local_switch_project()
  started <- NULL
  local_mocked_bindings(
    pixi_info = function(path) list(platform = "osx-arm64"),
    start_detached = function(args, root) started <<- list(args, root)
  )

  expect_snapshot(pixi_switch("r44", ide = "rstudio"))
  expect_equal(
    started,
    list(
      c("run", "--environment", "r44", "open -n -a RStudio demo.Rproj"),
      calls$dir
    )
  )
})

test_that("pixi_switch() tells RStudio on Windows which R to use", {
  local_switch_project()
  started <- NULL
  local_mocked_bindings(
    pixi_info = function(path) list(platform = "win-64"),
    start_detached = function(args, root) started <<- args
  )

  suppressMessages(pixi_switch("r44", ide = "rstudio"))
  expect_equal(
    started[4],
    paste(
      "RSTUDIO_WHICH_R=$CONDA_PREFIX/lib/R/bin/x64/R.exe",
      "\"C:/Program Files/RStudio/rstudio.exe\" demo.Rproj"
    )
  )
})

test_that("pixi_switch() opens Positron's interpreter picker", {
  local_switch_project()
  commands <- character()
  local_mocked_bindings(
    positron_command = function() {
      function(command) commands <<- c(commands, command)
    }
  )

  expect_snapshot(pixi_switch("r44", ide = "positron"))
  expect_equal(
    commands,
    c(
      "workbench.action.language.runtime.discoverAllRuntimes",
      "workbench.action.languageRuntime.selectRuntime"
    )
  )

  # Outside Positron's R, it only says what to pick
  local_mocked_bindings(positron_command = function() NULL)
  expect_snapshot(pixi_switch("r44", ide = "positron"))
})

test_that("positron_command() finds Ark's function, if there is one", {
  expect_null(positron_command())
  assign(
    ".ps.ui.executeCommand",
    function(command) command,
    envir = globalenv()
  )
  withr::defer(rm(".ps.ui.executeCommand", envir = globalenv()))
  expect_equal(positron_command()("a command"), "a command")
})

test_that("pixi_switch() points VS Code at the environment's R", {
  calls <- local_switch_project()
  local_mocked_bindings(is_windows = function() FALSE)

  expect_snapshot(pixi_switch("r44", ide = "vscode"))
  settings <- jsonlite::read_json(file.path(
    calls$dir,
    ".vscode",
    "settings.json"
  ))
  expect_equal(
    settings[["r.executablePath"]],
    "${workspaceFolder}/.pixi/envs/r44/bin/R"
  )
  expect_equal(settings[["r.consolePath"]], settings[["r.executablePath"]])
})

test_that("pixi_switch() tells VS Code users on Windows to restart it", {
  calls <- local_switch_project()
  local_mocked_bindings(is_windows = function() TRUE)

  expect_snapshot(pixi_switch("r44", ide = "vscode"))
  expect_false(file.exists(file.path(calls$dir, ".vscode", "settings.json")))
})

test_that("environment_r() finds the environment's R on each platform", {
  local_mocked_bindings(is_windows = function() FALSE)
  expect_equal(environment_r("/p", "r44"), "/p/.pixi/envs/r44/bin/R")
  local_mocked_bindings(is_windows = function() TRUE)
  expect_equal(
    environment_r("/p", "r44"),
    "/p/.pixi/envs/r44/lib/R/bin/x64/R.exe"
  )
})

test_that("start_detached() starts Pixi in the project", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  process <- start_detached(c("run", "echo", "hello"), dir)
  process$wait()
  expect_equal(process$get_exit_status(), 0)
})
