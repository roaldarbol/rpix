# A Pixi project to set IDEs up in, with pixi calls recorded instead of run
local_ide_project <- function(platforms = "osx-arm64", env = parent.frame()) {
  root <- normalizePath(
    withr::local_tempdir(.local_envir = env),
    winslash = "/"
  )
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  withr::local_envvar(
    PIXI_WORKSPACE_ROOT = NA,
    PIXI_PROJECT_ROOT = NA,
    .local_envir = env
  )
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    is_interactive = function() FALSE,
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

test_that("adds an rstudio task for each common platform, and a .Rproj file", {
  p <- local_ide_project(
    platforms = c("linux-64", "osx-64", "osx-arm64", "win-64")
  )
  rproj <- paste0(basename(p$root), ".Rproj")

  messages <- capture_messages(use_pixi_rstudio(p$root))

  expect_true(file.exists(file.path(p$root, rproj)))
  expect_false(any(grepl("Pixi added", messages)))
  # Each platform's task is removed, then added
  expect_length(p$args, 8)
  expect_equal(
    p$args[[1]],
    c("task", "remove", "rstudio", "--platform", "linux-64")
  )
  p$args <- p$args[c(2, 4, 6, 8)]
  expect_equal(p$args[[1]][4], paste("rstudio", rproj))
  expect_equal(
    p$args[[2]][1:6],
    c(
      "task",
      "add",
      "rstudio",
      paste("open -n -a RStudio", rproj),
      "--platform",
      "osx-64"
    )
  )
  expect_equal(p$args[[3]][6], "osx-arm64")
  expect_equal(
    p$args[[4]][4],
    paste('"C:/Program Files/RStudio/rstudio.exe"', rproj)
  )
  expect_true(
    "RSTUDIO_WHICH_R=$CONDA_PREFIX/lib/R/bin/x64/R.exe" %in% p$args[[4]]
  )
})

test_that("uses an existing .Rproj file, and says which platforms Pixi adds", {
  p <- local_ide_project(platforms = "osx-64")
  writeLines("Version: 1.0", file.path(p$root, "mine.Rproj"))

  messages <- capture_messages(use_pixi_rstudio(p$root))

  expect_equal(list.files(p$root, pattern = "\\.Rproj$"), "mine.Rproj")
  expect_equal(p$args[[4]][4], "open -n -a RStudio mine.Rproj")
  expect_true(any(grepl(
    "Pixi added \"linux-64\", \"osx-arm64\", and \"win-64\"",
    messages,
    fixed = TRUE
  )))
})

# use_pixi_positron() ----------------------------------------------------------

test_that("turns on Pixi discovery, keeping other settings", {
  p <- local_ide_project()
  dir.create(file.path(p$root, ".vscode"))
  writeLines(
    '{"editor.tabSize": 2, "files.exclude": ["a"]}',
    file.path(p$root, ".vscode", "settings.json")
  )

  local_mocked_bindings(is_windows = function() FALSE)

  suppressMessages(use_pixi_positron(p$root))

  expect_equal(
    read_settings(p$root),
    list(
      editor.tabSize = 2L,
      files.exclude = list("a"),
      positron.r.interpreters.pixiDiscovery = TRUE,
      positron.r.interpreters.default = "${workspaceFolder}/.pixi/envs/default/bin/R"
    )
  )
})

test_that("makes the environment's R Positron's default, or leaves it out", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() TRUE)
  expect_snapshot(use_pixi_positron(p$root))
  expect_equal(
    read_settings(p$root)$positron.r.interpreters.default,
    "${workspaceFolder}/.pixi/envs/default/lib/R/bin/x64/R.exe"
  )

  q <- local_ide_project()
  expect_snapshot(use_pixi_positron(q$root, default_r = FALSE))
  expect_null(read_settings(q$root)$positron.r.interpreters.default)
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

test_that("sets up arf or radian as the console, with the environment's R", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() FALSE)
  env <- "${workspaceFolder}/.pixi/envs/default"

  suppressMessages(use_pixi_vscode(p$root, console = "arf"))
  expect_equal(p$args[[1]], c("add", "r-languageserver", "arf"))
  expect_equal(
    read_settings(p$root),
    list(
      r.executablePath = paste0(env, "/bin/R"),
      r.consolePath = paste0(env, "/bin/arf"),
      r.consoleArgs = list(
        "--r-home",
        paste0(env, "/lib/R"),
        "--no-save",
        "--no-restore"
      ),
      r.bracketedPaste = TRUE
    )
  )

  suppressMessages(use_pixi_vscode(p$root, console = "radian"))
  settings <- read_settings(p$root)
  expect_equal(settings$r.consolePath, paste0(env, "/bin/radian"))
  expect_equal(
    settings$r.consoleArgs,
    list(paste0("--r-binary=", env, "/bin/R"))
  )

  # Back to R, without the other consoles' settings
  suppressMessages(use_pixi_vscode(p$root, console = "R"))
  expect_named(read_settings(p$root), c("r.executablePath", "r.consolePath"))
})

test_that("asks which console to use, or keeps the one set up", {
  p <- local_ide_project()
  answer <- 2L
  local_mocked_bindings(
    is_windows = function() FALSE,
    is_interactive = function() TRUE,
    ask_choice = function(question, choices) {
      expect_equal(choices, c("R", "arf", "radian"))
      answer
    }
  )
  suppressMessages(use_pixi_vscode(p$root))
  expect_equal(p$args[[1]], c("add", "r-languageserver", "arf"))
  expect_equal(vscode_console(p$root), "arf")

  # Esc keeps it, as does not asking
  answer <- NA_integer_
  suppressMessages(use_pixi_vscode(p$root))
  expect_equal(vscode_console(p$root), "arf")
  local_mocked_bindings(is_interactive = function() FALSE)
  suppressMessages(use_pixi_vscode(p$root))
  expect_equal(vscode_console(p$root), "arf")
})

test_that("leaves the console to the PATH on Windows", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() TRUE)

  suppressMessages(use_pixi_vscode(p$root, console = "arf"))
  expect_equal(
    read_settings(p$root),
    list(r.consolePath = "arf", r.bracketedPaste = TRUE)
  )

  suppressMessages(use_pixi_vscode(p$root, console = "R"))
  expect_equal(read_settings(p$root), setNames(list(), character()))
})

test_that("vscode_console() reads the console from the settings", {
  root <- withr::local_tempdir()
  expect_equal(vscode_console(root), "R")

  dir.create(file.path(root, ".vscode"))
  file <- file.path(root, ".vscode", "settings.json")
  writeLines('{"r.consolePath": "C:/envs/default/Scripts/radian.exe"}', file)
  expect_equal(vscode_console(root), "radian")
  writeLines('{"r.consolePath": "/usr/local/bin/R"}', file)
  expect_equal(vscode_console(root), "R")
  writeLines(c("{", "  // arf", '  "r.consolePath": "arf"', "}"), file)
  expect_equal(vscode_console(root), "arf")
})

test_that("says which settings to remove from a file with comments", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() TRUE)
  dir.create(file.path(p$root, ".vscode"))
  file <- file.path(p$root, ".vscode", "settings.json")
  writeLines(c("{", "  // a comment", '  "r.consolePath": "arf"', "}"), file)

  expect_error(use_pixi_vscode(p$root, console = "R"), "Remove r.consolePath")
})

# use_pixi_emacs(), use_pixi_neovim() and use_pixi_zed() ---------------------

test_that("sets the editors up with languageserver and direnv", {
  for (editor in c("emacs", "neovim", "zed")) {
    p <- local_ide_project()
    local_mocked_bindings(
      is_windows = function() FALSE,
      direnv_binary = function() ""
    )
    setup <- get(paste0("use_pixi_", editor))
    expect_snapshot(file <- setup(p$root))
    expect_equal(p$args[[1]], c("add", "r-languageserver"))
    expect_equal(file, file.path(p$root, ".envrc"))
    expect_true(direnv_set_up(p$root))
  }
})

test_that("adds only what's missing, and sets direnv up once", {
  p <- local_ide_project()
  local_mocked_bindings(
    is_windows = function() FALSE,
    direnv_binary = function() ""
  )
  cat(
    "[dependencies]",
    'r-languageserver = ">=0.3"',
    file = file.path(p$root, "pixi.toml"),
    sep = "\n",
    append = TRUE
  )

  suppressMessages(use_pixi_vscode(p$root, console = "arf"))
  expect_equal(p$args, list(c("add", "arf")))

  # As use_pixi(ide = c("emacs", "neovim")) does
  expect_snapshot({
    use_pixi_emacs(p$root)
    use_pixi_neovim(p$root)
  })
  expect_length(p$args, 1)
})

test_that("tells Windows users to start the editor from the environment", {
  p <- local_ide_project()
  local_mocked_bindings(is_windows = function() TRUE)
  expect_message(use_pixi_neovim(p$root), "pixi run nvim")
  expect_false(file.exists(file.path(p$root, ".envrc")))
})

# Helpers ----------------------------------------------------------------------

test_that("the IDE helpers need a Pixi project", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  expect_error(use_pixi_positron(withr::local_tempdir()), "no Pixi project")
})

test_that("project_platforms() reads the project's platforms", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(
    c("init", dir, "--platform", "linux-64", "--platform", "win-64"),
    project = "none"
  )
  expect_setequal(project_platforms(dir), c("linux-64", "win-64"))
})

test_that("use_pixi_rstudio() can be run again", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  suppressMessages(capture.output(use_pixi_rstudio(dir)))
  file.rename(
    file.path(dir, paste0(basename(dir), ".Rproj")),
    file.path(dir, "renamed.Rproj")
  )
  suppressMessages(capture.output(use_pixi_rstudio(dir)))

  tasks <- pixi_tasks(path = dir)
  expect_equal(unique(tasks$name), "rstudio")
  expect_match(tasks$command, "renamed.Rproj")
})

test_that("the IDE setup leaves .vscode out of a package's builds", {
  dir <- withr::local_tempdir()
  writeLines("Package: demo", file.path(dir, "DESCRIPTION"))
  suppressMessages(update_vscode_settings(dir, list(a = 1)))
  expect_equal(readLines(file.path(dir, ".Rbuildignore")), "^\\.vscode$")
})
