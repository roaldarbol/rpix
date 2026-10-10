# find_project_root() ---------------------------------------------------------

test_that("finds pixi.toml in the given directory and its parents", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  nested <- file.path(root, "a", "b")
  dir.create(nested, recursive = TRUE)

  expect_equal(find_project_root(root), root)
  expect_equal(find_project_root(nested), root)
  expect_equal(find_manifest(nested), file.path(root, "pixi.toml"))
})

test_that("finds pyproject.toml only when it has a [tool.pixi] table", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  with_pixi <- local_pixi_project(
    "pyproject.toml",
    c("[project]", "name = 'x'", "[tool.pixi.workspace]")
  )
  without_pixi <- local_pixi_project(
    "pyproject.toml",
    c("[project]", "name = 'x'", "[tool.ruff]")
  )

  expect_equal(find_manifest(with_pixi), file.path(with_pixi, "pyproject.toml"))
  expect_null(find_manifest(without_pixi))
})

test_that("prefers pixi.toml over pyproject.toml", {
  root <- local_pixi_project()
  writeLines("[tool.pixi.workspace]", file.path(root, "pyproject.toml"))
  expect_equal(find_manifest(root), file.path(root, "pixi.toml"))
})

test_that("returns NULL outside a project", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  expect_null(find_project_root(withr::local_tempdir()))
})

test_that("uses PIXI_PROJECT_ROOT, then the working directory, when no path is given", {
  root <- local_pixi_project()
  other <- local_pixi_project()

  withr::local_envvar(PIXI_PROJECT_ROOT = root)
  withr::local_dir(other)
  expect_equal(find_project_root(), root)

  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  expect_equal(find_project_root(), other)
})

# pixi_binary() ---------------------------------------------------------------

test_that("the rpix.pixi_path option takes precedence", {
  fake <- withr::local_tempfile()
  file.create(fake)
  withr::local_options(rpix.pixi_path = fake)
  expect_equal(pixi_binary(), normalizePath(fake, winslash = "/"))
})

test_that("a wrong rpix.pixi_path option is an error", {
  withr::local_options(rpix.pixi_path = "/does/not/exist/pixi")
  expect_error(pixi_binary(), class = "rpix_error_pixi_not_found")
})

test_that("falls back to $PIXI_HOME/bin when pixi isn't on the PATH", {
  pixi_home <- withr::local_tempdir()
  dir.create(file.path(pixi_home, "bin"))
  exe <- file.path(pixi_home, "bin", if (is_windows()) "pixi.exe" else "pixi")
  file.create(exe)

  withr::local_options(rpix.pixi_path = NULL)
  withr::local_envvar(PATH = "", PIXI_HOME = pixi_home)
  expect_equal(pixi_binary(), normalizePath(exe, winslash = "/"))
})

test_that("errors helpfully when pixi can't be found", {
  withr::local_options(rpix.pixi_path = NULL)
  withr::local_envvar(PATH = "", PIXI_HOME = withr::local_tempdir())
  expect_error(pixi_binary(), class = "rpix_error_pixi_not_found")
})

# format_command() ------------------------------------------------------------

test_that("quotes only arguments that need it", {
  expect_equal(format_command(c("add", "r-dplyr")), "pixi add r-dplyr")
  expect_equal(
    format_command(c("add", "r-dplyr>=1.1")),
    "pixi add \"r-dplyr>=1.1\""
  )
  expect_equal(format_command(c("add", "r-dplyr=1.1")), "pixi add r-dplyr=1.1")
  expect_equal(
    format_command(c("-m", "/my dir/pixi.toml")),
    "pixi -m \"/my dir/pixi.toml\""
  )
})

# run_pixi() with dry_run -----------------------------------------------------

test_that("dry_run returns the command without needing pixi", {
  root <- local_pixi_project()
  withr::local_options(rpix.pixi_path = "/does/not/exist/pixi")

  expect_message(
    command <- run_pixi(c("add", "r-dplyr"), path = root, dry_run = TRUE),
    "Would run"
  )
  manifest <- file.path(root, "pixi.toml")
  expect_equal(
    command,
    format_command(c("add", "r-dplyr", "--manifest-path", manifest))
  )
})

test_that("the displayed manifest path is relative to the working directory", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  dir.create(file.path(root, "sub"))

  withr::local_dir(root)
  command <- suppressMessages(run_pixi("list", dry_run = TRUE))
  expect_equal(command, "pixi list --manifest-path pixi.toml")

  withr::local_dir(file.path(root, "sub"))
  command <- suppressMessages(run_pixi("list", dry_run = TRUE))
  expect_equal(
    command,
    format_command(c("list", "--manifest-path", file.path(root, "pixi.toml")))
  )
})

test_that("json = TRUE adds --json", {
  root <- local_pixi_project()
  command <- suppressMessages(run_pixi(
    "info",
    path = root,
    json = TRUE,
    dry_run = TRUE
  ))
  expect_match(command, "^pixi info --json --manifest-path ")
})

test_that("project = 'none' never adds --manifest-path", {
  root <- local_pixi_project()
  command <- suppressMessages(run_pixi(
    "--version",
    project = "none",
    path = root,
    dry_run = TRUE
  ))
  expect_equal(command, "pixi --version")
})

test_that("project = 'optional' works outside a project", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  outside <- withr::local_tempdir()
  command <- suppressMessages(run_pixi(
    c("search", "r-dplyr"),
    project = "optional",
    path = outside,
    dry_run = TRUE
  ))
  expect_equal(command, "pixi search r-dplyr")
})

test_that("project = 'required' errors outside a project", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  outside <- withr::local_tempdir()
  expect_error(
    run_pixi(c("add", "r-dplyr"), path = outside, dry_run = TRUE),
    class = "rpix_error_no_project"
  )
})

# run_pixi() against a real pixi ----------------------------------------------

test_that("runs pixi and captures the output", {
  skip_if_no_pixi()
  result <- run_pixi("--version", project = "none")
  expect_equal(result$status, 0)
  expect_match(result$stdout, "pixi")
})

test_that("parses JSON output", {
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  info <- run_pixi("info", path = dir, json = TRUE)
  expect_type(info, "list")
})

test_that("failures become R errors with pixi's message", {
  skip_if_no_pixi()
  err <- expect_error(
    run_pixi("definitely-not-a-command", project = "none"),
    class = "rpix_error_pixi"
  )
  expect_gt(err$status, 0)
  expect_match(conditionMessage(err), "definitely-not-a-command")
})

test_that("failures with streamed output don't repeat pixi's message", {
  skip_if_no_pixi()
  err <- expect_error(
    suppressMessages(capture.output(
      run_pixi("definitely-not-a-command", project = "none", echo = TRUE)
    )),
    class = "rpix_error_pixi"
  )
  expect_match(conditionMessage(err), "output above")
})

test_that("streamed output goes to stdout, and stderr is kept apart", {
  skip_if_no_pixi()
  output <- capture.output(
    err <- tryCatch(
      suppressMessages(
        run_pixi("definitely-not-a-command", project = "none", echo = TRUE)
      ),
      rpix_error_pixi = identity
    )
  )
  expect_match(paste(output, collapse = "\n"), "definitely-not-a-command")
  expect_match(err$stderr, "definitely-not-a-command")
  expect_equal(err$stdout, "")
})

test_that("streams output with or without saying which command runs", {
  skip_if_no_pixi()
  expect_message(
    capture.output(run_pixi("--version", project = "none", echo = TRUE)),
    "Running"
  )
  expect_no_message(
    output <- capture.output(
      run_pixi("--version", project = "none", echo = TRUE, announce = FALSE)
    )
  )
  expect_match(output, "pixi", all = FALSE)
})

# Error output -----------------------------------------------------------------

test_that("error details fall back to stdout when stderr is empty", {
  bullets <- pixi_output_bullets(list(
    stderr = "",
    stdout = "\033[31mbroken\033[0m"
  ))
  expect_equal(unname(bullets), "broken")
})

test_that("error details keep the last 20 lines of long output", {
  output <- paste0("line ", 1:30, collapse = "\n")
  bullets <- pixi_output_bullets(list(stderr = output, stdout = ""))
  expect_length(bullets, 21)
  expect_equal(unname(bullets[c(1, 2, 21)]), c("...", "line 11", "line 30"))
})

test_that("error details escape braces so cli doesn't interpolate them", {
  bullets <- pixi_output_bullets(list(stderr = "expected {x}", stdout = ""))
  expect_equal(unname(bullets), "expected {{x}}")
})

test_that("the home directory is USERPROFILE on Windows", {
  local_mocked_bindings(is_windows = function() TRUE)
  withr::local_envvar(USERPROFILE = "C:/Users/someone")
  expect_equal(home_dir(), "C:/Users/someone")
})

test_that("--manifest-path comes straight after `run`, before the command", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  withr::local_dir(root)

  command <- suppressMessages(
    run_pixi(c("run", "Rscript", "-e", "1"), dry_run = TRUE)
  )
  expect_equal(command, "pixi run --manifest-path pixi.toml Rscript -e 1")
})

test_that("Pixi doesn't get the variables R sets for itself", {
  withr::local_envvar(R_LIBS_SITE = "/this/r/site-library", RPIX_TEST = "yes")
  env <- pixi_env("never")
  expect_false(any(c("R_HOME", "R_LIBS_SITE") %in% names(env)))
  expect_equal(env[["RPIX_TEST"]], "yes")
  expect_equal(env[["PIXI_COLOR"]], "never")
})

test_that("secrets are hidden in commands, output and errors", {
  expect_equal(hide_secrets("a s3cr3t b", c("s3cr3t", "")), "a <hidden> b")
  expect_equal(hide_secrets("text", NULL), "text")

  expect_snapshot(
    run_pixi(
      c("auth", "login", "x", "--token", "s3cr3t"),
      project = "none",
      dry_run = TRUE,
      secrets = "s3cr3t"
    )
  )

  skip_if_no_pixi()
  err <- expect_error(
    run_pixi(
      c("definitely-not-a-command", "s3cr3t"),
      project = "none",
      secrets = "s3cr3t"
    ),
    class = "rpix_error_pixi"
  )
  expect_no_match(conditionMessage(err), "s3cr3t")
  expect_no_match(err$stderr, "s3cr3t")
  expect_match(conditionMessage(err), "<hidden>")
})
