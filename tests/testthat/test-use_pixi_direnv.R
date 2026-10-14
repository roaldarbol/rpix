test_that("adds the lines that activate an environment", {
  lines <- set_envrc_environment(character(), "default")
  expect_equal(
    lines,
    c(
      "# Activate the project's Pixi environment (written by rpix)",
      "watch_file pixi.toml pixi.lock",
      'eval "$(pixi shell-hook --shell bash --environment default)"'
    )
  )

  # Another environment changes the line, and keeps the others
  lines <- set_envrc_environment(c("export A=1", lines), "r44")
  expect_length(lines, 4)
  expect_equal(lines[1], "export A=1")
  expect_equal(
    lines[4],
    'eval "$(pixi shell-hook --shell bash --environment r44)"'
  )

  # direnv's own layout
  expect_equal(
    set_envrc_environment(c("layout pixi"), "r44"),
    "layout pixi --environment r44"
  )
})

test_that("use_pixi_direnv() writes .envrc, and says how to allow it", {
  root <- withr::local_tempdir()
  writeLines("Package: demo", file.path(root, "DESCRIPTION"))
  local_mocked_bindings(
    require_project = function(path, ...) root,
    direnv_binary = function() "/bin/direnv",
    is_interactive = function() FALSE
  )

  expect_snapshot(use_pixi_direnv(root), transform = function(x) {
    gsub(root, "<root>", x, fixed = TRUE)
  })
  expect_true(direnv_set_up(root))
  expect_match(readLines(file.path(root, ".envrc"))[3], "--environment default")
  expect_true("^\\.envrc$" %in% readLines(file.path(root, ".Rbuildignore")))

  # Without direnv
  local_mocked_bindings(direnv_binary = function() "")
  expect_message(use_pixi_direnv(root), "pixi global install direnv")
})

test_that("use_pixi_direnv() allows .envrc if asked", {
  root <- withr::local_tempdir()
  allowed <- NULL
  local_mocked_bindings(
    require_project = function(path, ...) root,
    direnv_binary = function() "/bin/direnv",
    is_interactive = function() TRUE,
    ask_yes_no = function(question) TRUE
  )
  local_mocked_bindings(
    run = function(command, args, ...) allowed <<- c(command, args),
    .package = "processx"
  )
  suppressMessages(use_pixi_direnv(root))
  expect_equal(allowed, c("/bin/direnv", "allow", root))
})

test_that("direnv_set_up() needs a .envrc that activates an environment", {
  root <- withr::local_tempdir()
  expect_false(direnv_set_up(root))
  writeLines("export A=1", file.path(root, ".envrc"))
  expect_false(direnv_set_up(root))
  writeLines("layout pixi", file.path(root, ".envrc"))
  expect_true(direnv_set_up(root))
})

test_that("direnv_binary() looks for direnv on the PATH", {
  expect_equal(direnv_binary(), Sys.which("direnv"))
})
