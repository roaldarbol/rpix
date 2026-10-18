# find_project_root() ---------------------------------------------------------

test_that("finds pixi.toml in the given directory and its parents", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  nested <- file.path(root, "a", "b")
  dir.create(nested, recursive = TRUE)

  expect_equal(find_project_root(root), root)
  expect_equal(find_project_root(nested), root)
  expect_equal(find_manifest(nested), file.path(root, "pixi.toml"))
})

test_that("finds pyproject.toml only when it has a [tool.pixi] table", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  expect_null(find_project_root(withr::local_tempdir()))
})

test_that("uses PIXI_WORKSPACE_ROOT, then the working directory, when no path is given", {
  root <- local_pixi_project()
  other <- local_pixi_project()
  nested <- file.path(root, "a")
  dir.create(nested)

  withr::local_envvar(PIXI_WORKSPACE_ROOT = root, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(nested)
  expect_equal(find_project_root(), root)

  # Outside any project, e.g. after setwd()
  withr::local_dir(withr::local_tempdir())
  expect_equal(find_project_root(), root)

  # Pixi before 0.82 sets only PIXI_PROJECT_ROOT
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = root)
  expect_equal(find_project_root(), root)

  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(other)
  expect_equal(find_project_root(), other)
})

test_that("uses the working directory's project when PIXI_WORKSPACE_ROOT is another", {
  # As in a copy of a project, whose activation cache points to the original
  withr::local_options(rlib_message_verbosity = "verbose")
  original <- local_pixi_project()
  copy <- local_pixi_project()
  withr::local_dir(copy)

  withr::local_envvar(PIXI_WORKSPACE_ROOT = original, PIXI_PROJECT_ROOT = NA)
  expect_message(
    expect_equal(find_manifest(), file.path(copy, "pixi.toml")),
    "PIXI_WORKSPACE_ROOT"
  )

  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = original)
  expect_message(
    expect_equal(find_project_root(), copy),
    "PIXI_PROJECT_ROOT"
  )
})

test_that("says once that PIXI_WORKSPACE_ROOT points elsewhere", {
  withr::local_options(rlib_message_verbosity = "default")
  rlang::reset_message_verbosity("rpix_other_workspace_root")
  withr::defer(rlang::reset_message_verbosity("rpix_other_workspace_root"))
  original <- local_pixi_project()
  copy <- local_pixi_project()
  withr::local_envvar(PIXI_WORKSPACE_ROOT = original, PIXI_PROJECT_ROOT = NA)
  withr::local_dir(copy)

  expect_snapshot(invisible(find_manifest()), transform = function(x) {
    gsub(copy, "<copy>", gsub(original, "<original>", x, fixed = TRUE))
  })
  expect_no_message(find_manifest())
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

test_that("offers to install Pixi in an interactive session", {
  withr::local_options(rpix.pixi_path = NULL)
  withr::local_envvar(PATH = "", PIXI_HOME = withr::local_tempdir())
  fake <- withr::local_tempfile()
  file.create(fake)
  local_mocked_bindings(
    is_interactive = function() TRUE,
    install_pixi = function() fake
  )
  expect_snapshot(pixi <- pixi_binary())
  expect_equal(pixi, normalizePath(fake, winslash = "/"))

  # Not when it was declined, nor when the caller doesn't want it
  local_mocked_bindings(
    install_pixi = function() {
      cli::cli_abort("Cancelled", class = "rpix_cancelled")
    }
  )
  expect_error(
    suppressMessages(pixi_binary()),
    class = "rpix_error_pixi_not_found"
  )
  local_mocked_bindings(install_pixi = function() stop("asked"))
  expect_error(
    pixi_binary(offer_install = FALSE),
    class = "rpix_error_pixi_not_found"
  )
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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

test_that("output can be kept back, while saying which command runs", {
  skip_if_no_pixi()
  pieces <- character()
  expect_message(
    output <- capture.output(
      result <- run_pixi(
        "--version",
        project = "none",
        announce = TRUE,
        on_output = function(x) pieces <<- c(pieces, x)
      )
    ),
    "Running"
  )
  expect_equal(output, character())
  expect_match(result$output, "pixi")
  expect_equal(paste(pieces, collapse = ""), result$output)
  expect_output(show_pixi_output(result), "pixi")
})

test_that("a failure whose output was kept back can show it after all", {
  err <- pixi_failure("No candidates were found for r-x *.\n")
  expect_match(conditionMessage(err), "No candidates")
  expect_false(err$echoed)

  expect_output(revealed <- reveal_pixi_failure(err), "No candidates")
  expect_s3_class(revealed, "rpix_error_pixi")
  expect_true(revealed$echoed)
  expect_match(conditionMessage(revealed), "output above")
  expect_no_match(conditionMessage(revealed), "No candidates")
  expect_equal(revealed$stderr, err$stderr)

  # Shown already
  expect_silent(expect_identical(reveal_pixi_failure(revealed), revealed))
})

test_that("a long step says what it does, and shows the output if it fails", {
  outcome <- "success"
  calls <- list()
  local_mocked_bindings(
    run_pixi = function(args, path = NULL, echo = FALSE, on_output = NULL) {
      calls <<- c(calls, list(list(args = args, echo = echo)))
      if (!is.null(on_output)) {
        on_output("a line of the build log\n")
      }
      if (outcome == "failure") {
        stop(pixi_failure(
          "a line of the build log\nthe build failed\n",
          "pixi install"
        ))
      }
      invisible(list(status = 0, output = "a line of the build log\n"))
    }
  )
  expect_snapshot(
    run_pixi_step("install", step = "Building it", done = "Built it"),
    transform = scrub_progress
  )

  outcome <- "failure"
  expect_snapshot(
    run_pixi_step("install", step = "Building it", done = "Built it"),
    error = TRUE,
    transform = scrub_progress
  )

  # A spinner that turns as Pixi writes, where the console can redraw it
  outcome <- "success"
  withr::local_options(cli.dynamic = TRUE)
  suppressMessages(run_pixi_step("install", step = "Building it"))
  expect_length(calls, 3)

  # Or the output as it runs
  withr::local_options(rpix.verbose = TRUE)
  expect_silent(run_pixi_step("install", step = "Building it"))
  expect_true(calls[[4]]$echo)
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
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  withr::local_dir(root)

  command <- suppressMessages(
    run_pixi(c("run", "Rscript", "-e", "1"), dry_run = TRUE)
  )
  expect_equal(command, "pixi run --manifest-path pixi.toml Rscript -e 1")
})

test_that("removes a stale activation cache before Pixi activates", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
  root <- local_pixi_project()
  checked <- new.env()
  checked$roots <- character()
  local_mocked_bindings(
    pixi_binary = function(...) "pixi",
    remove_stale_activation_cache = function(root) {
      checked$roots <- c(checked$roots, root)
    }
  )
  local_mocked_bindings(
    run = function(...) list(status = 0, stdout = "", stderr = ""),
    .package = "processx"
  )

  run_pixi(c("run", "R"), path = root)
  run_pixi(c("shell-hook", "--environment", "default"), path = root)
  run_pixi(c("add", "r-cli"), path = root)
  expect_message(run_pixi(c("run", "R"), path = root, dry_run = TRUE))
  expect_equal(checked$roots, c(root, root))
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

test_that("access_denied() finds the host that refused access", {
  stderr <- paste(
    readLines(test_path("fixtures", "pixi-access-error.txt")),
    collapse = "\n"
  )
  expect_equal(
    access_denied(stderr),
    list(status = "401", host = "127.0.0.1:8765")
  )
  expect_equal(
    access_denied(
      "HTTP status client error (403 Forbidden) for url (https://repo.prefix.dev/x/osx-64/repodata.json)"
    ),
    list(status = "403", host = "repo.prefix.dev")
  )
  expect_null(access_denied(
    "HTTP status client error (404 Not Found) for url (https://x.dev/y)"
  ))
  expect_null(access_denied("No candidates were found for r-x *."))
})

test_that("errors from a channel that refused access suggest logging in", {
  stderr <- paste(
    readLines(test_path("fixtures", "pixi-access-error.txt")),
    collapse = "\n"
  )
  result <- list(status = 1, stdout = "", stderr = stderr)
  expect_snapshot(
    abort_pixi_failure("pixi add r-x", result, echoed = TRUE, call = NULL),
    error = TRUE
  )
  expect_error(
    abort_pixi_failure("pixi add r-x", result, echoed = TRUE, call = NULL),
    class = "rpix_error_access"
  )
})
