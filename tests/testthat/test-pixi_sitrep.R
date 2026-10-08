good_report <- function(...) {
  report <- list(
    pixi = "/home/me/.pixi/bin/pixi",
    pixi_version = "pixi 0.81.0",
    project = "/home/me/project",
    lock_up_to_date = TRUE,
    r_home = "/home/me/project/.pixi/envs/default/lib/R",
    r_version = "4.5.3",
    environment = list(root = "/home/me/project", name = "default"),
    in_project = TRUE,
    activated = TRUE,
    libraries_outside = character(),
    packages_outside = character(),
    rprofile = TRUE,
    ide = "positron",
    ide_set_up = TRUE
  )
  # Set elements one by one: modifyList() drops elements set to NULL
  changes <- list(...)
  for (name in names(changes)) {
    report[name] <- list(changes[[name]])
  }
  report
}

sitrep_output <- function(report) {
  local_mocked_bindings(
    sitrep_data = function(...) report,
    .env = parent.frame()
  )
  paste(cli::cli_fmt(result <- pixi_sitrep()), collapse = "\n")
}

test_that("reports a good setup", {
  out <- sitrep_output(good_report())
  expect_match(out, "pixi 0.81.0")
  expect_match(out, "up to date")
  expect_match(out, "from the project's \"default\" environment")
  expect_match(out, "is activated")
  expect_match(out, "All libraries are in the project")
  expect_match(out, "Positron is set up")
})

test_that("reports problems, with hints", {
  out <- sitrep_output(good_report(
    lock_up_to_date = FALSE,
    activated = FALSE,
    libraries_outside = "/home/me/Library/R/4.5/library",
    packages_outside = "cli",
    rprofile = FALSE,
    ide = "rstudio",
    ide_set_up = FALSE
  ))
  expect_match(out, "pixi install")
  expect_match(out, "isn't activated")
  expect_match(out, "Library/R/4.5/library")
  expect_match(out, "Loaded from outside the project: cli")
  expect_match(out, "use_pixi\\(\\)")
  expect_match(out, "use_pixi_rstudio\\(\\)")
})

test_that("reports a missing Pixi, project or Pixi R", {
  out <- sitrep_output(good_report(
    pixi = NULL,
    project = NULL,
    environment = NULL,
    in_project = FALSE,
    activated = FALSE,
    ide = NA_character_
  ))
  expect_match(out, "can't find it")
  expect_match(out, "no Pixi project")
  expect_match(out, "isn't from a Pixi environment")
  expect_match(out, "Not in RStudio, Positron or VS Code")

  out <- sitrep_output(good_report(
    environment = list(root = "/other", name = "default"),
    in_project = FALSE
  ))
  expect_match(out, "another project")
})

test_that("returns the report invisibly", {
  local_mocked_bindings(sitrep_data = function(...) good_report())
  expect_invisible(suppressMessages(pixi_sitrep()))
})

# sitrep_data() ---------------------------------------------------------------

test_that("collects the setup of a project's Pixi R", {
  root <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  writeLines(rprofile_block, file.path(root, ".Rprofile"))
  withr::local_envvar(
    PIXI_PROJECT_ROOT = NA,
    PIXI_ENVIRONMENT_NAME = "default",
    POSITRON = NA,
    RSTUDIO = NA,
    TERM_PROGRAM = NA
  )
  local_mocked_bindings(
    pixi_binary = function(...) "/fake/pixi",
    r_home = function() file.path(root, ".pixi", "envs", "default", "lib", "R"),
    run_pixi = function(args, ...) list(stdout = "pixi 0.81.0\n")
  )

  report <- sitrep_data(root)
  expect_equal(report$pixi_version, "pixi 0.81.0")
  expect_equal(report$project, root)
  expect_true(report$lock_up_to_date)
  expect_true(report$in_project)
  expect_true(report$activated)
  expect_true(report$rprofile)
  expect_true(is.na(report$ide))

  # In an IDE, running the project's R counts as set up
  withr::local_envvar(POSITRON = "1")
  expect_true(sitrep_data(root)$ide_set_up)
  # This R's libraries and packages are outside the temporary project
  expect_true(length(report$libraries_outside) > 0)
  expect_true("base" %in% report$packages_outside)
})

test_that("collects nothing project-specific outside a project", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  local_mocked_bindings(pixi_binary = function(...) stop("no pixi"))

  report <- sitrep_data(withr::local_tempdir())
  expect_null(report$pixi)
  expect_null(report$project)
  expect_null(report$lock_up_to_date)
  expect_length(report$libraries_outside, 0)
  expect_false(report$rprofile)
})

test_that("tells whether the lock file is up to date", {
  local_mocked_bindings(run_pixi = function(...) list(status = 0))
  expect_true(lock_up_to_date("/project"))

  error <- function(stderr) {
    function(...) {
      stop(structure(
        class = c("rpix_error_pixi", "error", "condition"),
        list(message = "failed", call = NULL, stderr = stderr)
      ))
    }
  }
  local_mocked_bindings(
    run_pixi = error("lock file not up-to-date with the workspace")
  )
  expect_false(lock_up_to_date("/project"))
  local_mocked_bindings(run_pixi = error("network unreachable"))
  expect_true(is.na(lock_up_to_date("/project")))
})

test_that("detects the IDE", {
  withr::local_envvar(POSITRON = NA, RSTUDIO = NA, TERM_PROGRAM = NA)
  expect_true(is.na(detect_ide()))
  withr::local_envvar(TERM_PROGRAM = "vscode")
  expect_equal(detect_ide(), "vscode")
  withr::local_envvar(RSTUDIO = "1")
  expect_equal(detect_ide(), "rstudio")
  withr::local_envvar(POSITRON = "1")
  expect_equal(detect_ide(), "positron")
})

test_that("tells whether an IDE is set up for the project", {
  root <- withr::local_tempdir()
  expect_false(ide_set_up("positron", root))
  expect_false(ide_set_up("vscode", root))

  dir.create(file.path(root, ".vscode"))
  jsonlite::write_json(
    list(
      positron.r.interpreters.pixiDiscovery = TRUE,
      r.executablePath = "${workspaceFolder}/.pixi/envs/default/bin/R"
    ),
    file.path(root, ".vscode", "settings.json"),
    auto_unbox = TRUE
  )
  local_mocked_bindings(is_windows = function() FALSE)
  expect_true(ide_set_up("positron", root))
  expect_true(ide_set_up("vscode", root))

  # On Windows, VS Code is set up if it runs the environment's R
  local_mocked_bindings(
    is_windows = function() TRUE,
    r_home = function() file.path(root, ".pixi", "envs", "default", "lib", "R")
  )
  expect_true(ide_set_up("vscode", root))
})

test_that("tells whether RStudio has its task", {
  tasks <- function(names) {
    function(...) {
      list(
        features = list(data.frame(
          name = "default",
          tasks = I(list(data.frame(name = names)))
        ))
      )
    }
  }
  local_mocked_bindings(run_pixi = tasks(c("test", "rstudio")))
  expect_true(ide_set_up("rstudio", "/project"))
  local_mocked_bindings(run_pixi = tasks("test"))
  expect_false(ide_set_up("rstudio", "/project"))
})

test_that("tells whether a path is in a folder", {
  root <- withr::local_tempdir()
  # Paths that exist, as libraries and packages do: on macOS, temporary
  # folders are behind a symbolic link that only existing paths resolve
  dir.create(file.path(root, "a", "b"), recursive = TRUE)
  expect_true(in_folder(root, root))
  expect_true(in_folder(file.path(root, "a", "b"), root))
  expect_false(in_folder(paste0(root, "-other"), root))
  expect_false(in_folder(NA_character_, root))
  expect_false(in_folder(root, NULL))
})

test_that("names IDEs", {
  expect_equal(ide_name("vscode"), "VS Code")
})
