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
    packages_unrecorded = "pak",
    rprofile = FALSE,
    ide = "rstudio",
    ide_set_up = FALSE,
    build_unignored = c(".pixi", "pixi.lock")
  ))
  expect_match(out, "pixi install")
  expect_match(out, "builds include '.pixi' and 'pixi.lock'")
  expect_match(out, 'use_build_ignore\\(c\\(".pixi", "pixi.lock"\\)\\)')
  expect_match(out, "isn't activated")
  expect_match(out, "Library/R/4.5/library")
  expect_match(out, "Loaded from outside the project: cli")
  expect_match(out, "Installed without Pixi, so not in 'pixi.toml': pak")
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
    ide = NA_character_,
    ide_set_up = NULL
  ))
  expect_match(out, "can't find it")
  expect_match(out, "no Pixi project")
  expect_match(out, "isn't from a Pixi environment")
  expect_match(out, "set your IDE up")
  expect_match(out, "Not in RStudio, Positron, VS Code, Emacs, Neovim or Zed")

  out <- sitrep_output(good_report(
    environment = list(root = "/other", name = "default"),
    in_project = FALSE
  ))
  expect_match(out, "another project")
})

test_that("gives the IDE's step when it's set up, but runs another R", {
  out <- sitrep_output(good_report(
    environment = NULL,
    in_project = FALSE,
    activated = FALSE,
    ide = "rstudio",
    ide_set_up = TRUE,
    ide_step = "Start RStudio with {.code pixi run rstudio} in the project."
  ))
  expect_match(out, "or in the IDE as below")
  expect_no_match(out, "set your IDE up")
  expect_match(out, "RStudio is set up for the project, but runs another R")
  expect_match(out, "Start RStudio with `pixi run rstudio`")
  expect_no_match(out, "RStudio is set up for the project.", fixed = TRUE)
})

test_that("reports what a package's DESCRIPTION needs", {
  out <- sitrep_output(good_report(
    description = list(
      missing = c("rlang", "limma"),
      missing_suggests = "knitr",
      too_old = data.frame(
        package = "cli",
        installed = "3.3.0",
        needs = "3.6.0"
      )
    )
  ))
  expect_match(
    out,
    "needs rlang and limma, which aren't in the default environment"
  )
  expect_match(out, "suggests knitr, which isn't in 'pixi.toml'")
  expect_match(out, "pixi_import_description\\(\\)")
  expect_match(out, "cli 3.3.0 \\(needs >= 3.6.0\\)")

  out <- sitrep_output(good_report(
    description = list(
      missing = character(),
      missing_suggests = character(),
      too_old = data.frame(
        package = character(),
        installed = character(),
        needs = character()
      )
    )
  ))
  expect_match(out, "'pixi.toml' has what 'DESCRIPTION' needs")
  expect_no_match(sitrep_output(good_report()), "Package")
})

test_that("reports the date packages are as of", {
  out <- sitrep_output(good_report(exclude_newer = "2025-06-01"))
  expect_match(out, "as they were on \"2025-06-01\"")
  out <- sitrep_output(good_report(exclude_newer = "7d"))
  expect_match(out, "last \"7d\" are left out")
})

test_that("project_exclude_newer() reads it from the project's manifest", {
  dir <- withr::local_tempdir()
  expect_null(project_exclude_newer(dir))
  writeLines(
    c("[workspace]", 'exclude-newer = "7d"'),
    file.path(dir, "pixi.toml")
  )
  expect_equal(project_exclude_newer(dir), "7d")
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
    PIXI_WORKSPACE_ROOT = NA,
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
  expect_length(report$build_unignored, 0)

  # In a package, Pixi's files and .vscode belong in .Rbuildignore
  writeLines("Package: demo", file.path(root, "DESCRIPTION"))
  dir.create(file.path(root, ".vscode"))
  expect_equal(
    sitrep_data(root)$build_unignored,
    c(".pixi", "pixi.toml", "pixi.lock", ".vscode")
  )

  # In an IDE, running the project's R counts as set up
  withr::local_envvar(POSITRON = "1")
  expect_true(sitrep_data(root)$ide_set_up)
  expect_null(sitrep_data(root)$ide_step)
  # This R's libraries and packages are outside the temporary project, but
  # base packages come with any R
  expect_true(length(report$libraries_outside) > 0)
  expect_true(length(report$packages_outside) > 0)
  expect_false(any(base_packages() %in% report$packages_outside))

  # Set up, but running another R
  local_mocked_bindings(
    r_home = function() R.home(),
    ide_set_up = function(...) TRUE
  )
  report <- sitrep_data(root)
  expect_true(report$ide_set_up)
  expect_match(report$ide_step, "R (Pixi: default)", fixed = TRUE)
})

test_that("collects nothing project-specific outside a project", {
  withr::local_envvar(PIXI_WORKSPACE_ROOT = NA, PIXI_PROJECT_ROOT = NA)
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
  withr::local_envvar(
    POSITRON = NA,
    RSTUDIO = NA,
    TERM_PROGRAM = NA,
    INSIDE_EMACS = NA,
    NVIM = NA
  )
  expect_true(is.na(detect_ide()))
  withr::local_envvar(TERM_PROGRAM = "zed")
  expect_equal(detect_ide(), "zed")
  withr::local_envvar(TERM_PROGRAM = "vscode")
  expect_equal(detect_ide(), "vscode")
  # An editor in VS Code's terminal
  withr::local_envvar(NVIM = "/tmp/nvim.sock")
  expect_equal(detect_ide(), "neovim")
  withr::local_envvar(INSIDE_EMACS = "31.1,comint")
  expect_equal(detect_ide(), "emacs")
  withr::local_envvar(RSTUDIO = "1")
  expect_equal(detect_ide(), "rstudio")
  withr::local_envvar(POSITRON = "1")
  expect_equal(detect_ide(), "positron")
})

test_that("says how to start the project's R in each IDE", {
  root <- withr::local_tempdir()
  local_mocked_bindings(is_windows = function() FALSE)

  local_mocked_bindings(rstudio_addin = function(...) NULL)
  expect_equal(
    ide_step("rstudio", root),
    "Start RStudio with {.code pixi run rstudio} in the project."
  )
  local_mocked_bindings(rstudio_addin = function(...) "Open with Pixi R")
  expect_match(
    ide_step("rstudio", root),
    "or with {.val Open with Pixi R} in rpix's Addins.",
    fixed = TRUE
  )

  expect_match(ide_step("positron", root), "R (Pixi: default)", fixed = TRUE)

  expect_match(ide_step("vscode", root), "pixi_install()", fixed = TRUE)
  expect_match(ide_step("vscode", root), "Reload Window")
  r <- environment_r(root, "default")
  dir.create(dirname(r), recursive = TRUE)
  file.create(r)
  expect_match(ide_step("vscode", root), "R: Create R Terminal")

  for (editor in c("emacs", "neovim", "zed")) {
    expect_match(ide_step(editor, root), "direnv allow")
  }

  # On Windows, these leave R to the PATH
  local_mocked_bindings(is_windows = function() TRUE)
  expect_match(ide_step("vscode", root), "pixi run code .", fixed = TRUE)
  expect_match(ide_step("zed", root), "Start Zed from the project's")
})

test_that("finds the name of an RStudio addin", {
  expect_null(rstudio_addin("addin_open_with_pixi_r", file = ""))

  file <- withr::local_tempfile(fileext = ".dcf")
  writeLines(
    c(
      "Name: Add packages...",
      "Binding: addin_add_packages",
      "",
      "Name: Open with the project's Pixi R",
      "Binding: addin_open_with_pixi_r"
    ),
    file
  )
  expect_equal(
    rstudio_addin("addin_open_with_pixi_r", file = file),
    "Open with the project's Pixi R"
  )
  expect_null(rstudio_addin("addin_other", file = file))
})

test_that("tells whether an IDE is set up for the project", {
  root <- withr::local_tempdir()
  local_mocked_bindings(is_windows = function() FALSE)
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
  expect_equal(ide_name("neovim"), "Neovim")
})

test_that("tells whether an editor is set up with direnv", {
  root <- withr::local_tempdir()
  local_mocked_bindings(is_windows = function() FALSE)
  expect_false(ide_set_up("zed", root))
  writeLines(
    set_envrc_environment(character(), "default"),
    file.path(root, ".envrc")
  )
  expect_true(ide_set_up("zed", root))
})

test_that("finds packages in the environment that Pixi didn't install", {
  installed <- rownames(utils::installed.packages(lib.loc = .Library))
  extra <- setdiff(installed, base_packages())
  skip_if(length(extra) == 0, "only base packages in this R's library")
  local_mocked_bindings(
    pixi_list = function(environment, path) {
      data.frame(r_package = c(setdiff(extra, extra[1]), NA))
    }
  )
  expect_equal(unrecorded_packages("default", "/p"), extra[1])

  local_mocked_bindings(pixi_list = function(...) stop("no Pixi"))
  expect_equal(unrecorded_packages("default", "/p"), character())
})

test_that("reports a channel that refused access, and the logins", {
  out <- sitrep_output(good_report(
    lock_up_to_date = NA,
    access_denied = list(status = "401", host = "repo.prefix.dev"),
    logins = c("prefix.dev", "anaconda.org")
  ))
  expect_match(out, "\"repo.prefix.dev\" refused access \\(401\\)")
  expect_match(out, "pixi_auth_login\\(\"repo.prefix.dev\"\\)")
  expect_match(out, "Pixi has logins for \"prefix.dev\" and \"anaconda.org\"")
})

test_that("the lock check notices a channel that refused access", {
  local_mocked_bindings(run_pixi = function(...) {
    stop(structure(
      list(
        message = "failed",
        call = NULL,
        stderr = "HTTP status client error (403 Forbidden) for url (https://repo.prefix.dev/x/noarch/repodata.json)"
      ),
      class = c("rpix_error_pixi", "error", "condition")
    ))
  })
  lock <- lock_up_to_date("/project")
  expect_true(is.na(lock))
  expect_equal(
    attr(lock, "denied"),
    list(status = "403", host = "repo.prefix.dev")
  )
})

test_that("logins() lists the hosts, or nothing if Pixi fails", {
  local_mocked_bindings(pixi_auth_status = function() {
    data.frame(host = "prefix.dev")
  })
  expect_equal(logins(), "prefix.dev")
  local_mocked_bindings(pixi_auth_status = function() stop("no Pixi"))
  expect_equal(logins(), character())
})

test_that("channel_access() finds a channel that refuses access", {
  searched <- character()
  local_mocked_bindings(
    project_channels = function(project) {
      c(
        "conda-forge",
        "https://repo.prefix.dev/open",
        "https://repo.prefix.dev/private"
      )
    },
    run_pixi = function(args, ...) {
      searched <<- c(searched, args[3])
      stderr <- if (grepl("private", args[3])) {
        "HTTP status client error (401 Unauthorized) for url (https://repo.prefix.dev/private/noarch/repodata.json)"
      } else {
        "No packages found"
      }
      stop(structure(
        list(message = "failed", call = NULL, stderr = stderr),
        class = c("rpix_error_pixi", "error", "condition")
      ))
    }
  )
  expect_equal(
    channel_access("/project"),
    list(status = "401", host = "repo.prefix.dev")
  )
  # Only the channels given as URLs
  expect_equal(
    searched,
    c("https://repo.prefix.dev/open", "https://repo.prefix.dev/private")
  )

  local_mocked_bindings(project_channels = function(project) "conda-forge")
  expect_null(channel_access("/project"))
  local_mocked_bindings(
    project_channels = function(project) "https://repo.prefix.dev/open",
    run_pixi = function(...) invisible(list(status = 0))
  )
  expect_null(channel_access("/project"))
})

test_that("reports environments that don't keep the personal library out", {
  out <- sitrep_output(good_report(
    unisolated = data.frame(
      name = c("r44", "plain"),
      feature = c("r44", "default")
    )
  ))
  expect_match(
    out,
    "\"r44\" and \"plain\" don't keep your personal R library out"
  )
  expect_match(
    out,
    'pixi_add("conda::conda-ecosystem-user-package-isolation", feature = "r44")',
    fixed = TRUE
  )
  expect_match(
    out,
    'pixi_add("conda::conda-ecosystem-user-package-isolation")',
    fixed = TRUE
  )
  expect_no_match(
    sitrep_output(good_report()),
    "personal R library out"
  )
})

test_that("unisolated_environments() finds environments with R but no isolation", {
  envs <- data.frame(name = c("default", "r44", "py", "test"))
  envs$features <- list("default", "r44", "py", c("test", "default"))
  envs$dependencies <- list(
    c("r-base", "conda-ecosystem-user-package-isolation"),
    "r-base",
    "python",
    c("r-testthat", "r-base", "conda-ecosystem-user-package-isolation")
  )
  local_mocked_bindings(pixi_info = function(path) {
    list(environments_info = envs)
  })
  expect_equal(
    unisolated_environments("/p"),
    data.frame(name = "r44", feature = "r44")
  )

  local_mocked_bindings(pixi_info = function(path) stop("no pixi"))
  expect_null(unisolated_environments("/p"))
})
