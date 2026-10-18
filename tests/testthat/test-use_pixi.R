# Mock pixi: record each call, and create pixi.toml on `pixi init`
local_mock_setup <- function(env = parent.frame()) {
  calls <- new.env()
  calls$args <- list()
  calls$paths <- list()
  home <- withr::local_tempdir(.local_envir = env)
  local_mocked_bindings(
    pixi_binary = function(...) "/fake/pixi",
    # Keep the real ~/.Rprofile out of it
    home_dir = function() home,
    run_pixi = function(args, path = NULL, ...) {
      calls$args <- c(calls$args, list(args))
      calls$paths <- c(calls$paths, list(path))
      if (args[1] == "init") {
        writeLines("[workspace]", file.path(args[2], "pixi.toml"))
      }
      invisible(list(status = 0))
    },
    .env = env
  )
  withr::local_envvar(
    PIXI_WORKSPACE_ROOT = NA,
    PIXI_PROJECT_ROOT = NA,
    .local_envir = env
  )
  calls$home <- home
  calls
}

activation_cache_args <- c(
  "config",
  "set",
  "--local",
  "experimental.use-environment-activation-cache",
  "true"
)

legacy_fixture <- function() {
  test_path("fixtures", "legacy-rprofile.txt")
}

test_that("use_pixi() creates a project and adds R and rpix", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  withr::local_dir(dir)

  manifest <- suppressMessages(use_pixi())

  expect_equal(manifest, file.path(dir, "pixi.toml"))
  expect_length(calls$args, 5)
  expect_equal(calls$args[[1]], c("init", dir))
  # The common platforms, besides this computer's, which `pixi init` adds
  expect_equal(
    calls$args[[2]],
    c(
      "workspace",
      "platform",
      "add",
      "linux-64",
      "osx-64",
      "osx-arm64",
      "win-64",
      "--no-install"
    )
  )
  calls$args <- calls$args[-2]
  expect_equal(calls$args[[2]][1:2], c("add", "r-base"))
  expect_true(all(c("r-cli", "r-jsonlite", "r-processx") %in% calls$args[[2]]))
  expect_true("conda-ecosystem-user-package-isolation" %in% calls$args[[2]])
  expect_equal(calls$args[[3]][1:3], c("run", "Rscript", "-e"))
  # utils' own, not rpix's, which adds packages with Pixi
  expect_match(
    calls$args[[3]][4],
    "utils::install.packages('rpix'",
    fixed = TRUE
  )
  expect_match(calls$args[[3]][4], "lib = .Library", fixed = TRUE)
  expect_equal(calls$args[[4]], activation_cache_args)
  # Commands target the project, not the environment R happens to run in
  expect_true(all(vapply(calls$paths[-1], identical, logical(1), dir)))
})

test_that("use_pixi() only adds what the project doesn't have", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  deps <- c("r-base", isolation_package, rpix_dependencies())
  writeLines(
    c("[workspace]", "", "[dependencies]", paste0(deps, ' = "*"')),
    file.path(dir, "pixi.toml")
  )

  suppressMessages(use_pixi(path = dir, install_rpix = FALSE))
  expect_false("add" %in% vapply(calls$args, `[`, character(1), 1))

  suppressMessages(use_pixi(path = dir, ide = "zed", install_rpix = FALSE))
  expect_equal(calls$args[[2]], c("add", "r-languageserver"))
})

test_that("has_dependency() reads the default feature's dependencies", {
  dir <- withr::local_tempdir()
  expect_false(has_dependency("r-base", dir))
  writeLines(
    c(
      "[dependencies]",
      'r-base = "4.5.*"',
      '"r-data.table" = "*"',
      "[feature.dev.dependencies]",
      'r-testthat = "*"'
    ),
    file.path(dir, "pixi.toml")
  )
  expect_equal(
    has_dependency(c("r-base", "r-data.table", "r-testthat", "r-cli"), dir),
    c(TRUE, TRUE, FALSE, FALSE)
  )

  unlink(file.path(dir, "pixi.toml"))
  writeLines(
    c("[tool.pixi.workspace]", "[tool.pixi.dependencies]", "r-cli = '*'"),
    file.path(dir, "pyproject.toml")
  )
  expect_true(has_dependency("r-cli", dir))
})

test_that("use_pixi() installs rpix quietly, unless it's there already", {
  dir <- withr::local_tempdir()
  steps <- list()
  local_mocked_bindings(
    run_pixi_step = function(args, step, done, path) {
      steps <<- c(steps, list(args))
    }
  )
  # Not there
  expect_true(install_rpix_into(dir))
  expect_equal(steps[[1]][1:3], c("run", "Rscript", "-e"))
  # A failed install fails Rscript
  expect_match(steps[[1]][4], "^options\\(warn = 2\\); utils::install")

  library <- file.path(dir, ".pixi", "envs", "default", "lib", "R", "library")
  dir.create(file.path(library, "rpix"), recursive = TRUE)
  description <- file.path(library, "rpix", "DESCRIPTION")
  # Older than this rpix
  writeLines("Version: 0.0.1", description)
  expect_true(install_rpix_into(dir))
  expect_length(steps, 2)

  # This version, or newer
  writeLines(paste("Version:", utils::packageVersion("rpix")), description)
  expect_message(
    expect_false(install_rpix_into(dir)),
    "has rpix .* already"
  )
  expect_length(steps, 2)
})

test_that("use_pixi() uses an existing project and can skip rpix", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  withr::local_dir(dir)

  suppressMessages(use_pixi(r_version = "4.5", install_rpix = FALSE))

  # r-cli comes with R, so Pixi picks an R that has packages, and goes again
  expect_equal(
    calls$args,
    list(
      c(
        "add",
        "--no-install",
        "r-base=4.5",
        "conda-ecosystem-user-package-isolation",
        "r-cli"
      ),
      c("remove", "r-cli"),
      activation_cache_args
    )
  )
  expect_equal(calls$paths[[1]], dir)
})

test_that("use_pixi() leaves a project's r-cli alone", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines(
    c("[workspace]", "", "[dependencies]", 'r-cli = ">=3.6"'),
    file.path(dir, "pixi.toml")
  )

  suppressMessages(use_pixi(path = dir, install_rpix = FALSE))
  expect_equal(
    calls$args[[1]],
    c("add", "r-base", "conda-ecosystem-user-package-isolation")
  )
  expect_false(list(c("remove", "r-cli")) %in% calls$args)
})

test_that("use_pixi() says when conda-forge has no R packages for the R asked for", {
  local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  # Pixi's error for R 4.6 with rpix's dependencies, when conda-forge had
  # r-base 4.6.1 but no R packages for it
  stderr <- paste(
    readLines(
      test_path("fixtures", "pixi-r-version-new-r.txt"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
  error <- structure(
    class = c("rpix_error_pixi", "error", "condition"),
    list(message = "pixi failed", call = NULL, stderr = stderr)
  )
  local_mocked_bindings(run_pixi = function(args, ...) stop(error))

  expect_snapshot(
    use_pixi(r_version = "4.6", path = dir),
    error = TRUE
  )
  # Not for an R it does have packages for, or for other errors
  expect_error(
    use_pixi(r_version = "4.5", path = dir),
    class = "rpix_error_pixi"
  )
  expect_error(use_pixi(path = dir), class = "rpix_error_pixi")
  error$stderr <- "Some other failure"
  expect_error(
    use_pixi(r_version = "4.6", path = dir),
    class = "rpix_error_pixi"
  )
})

test_that("use_pixi() sets up a subfolder of a project, and points at the project", {
  calls <- local_mock_setup()
  local_mocked_bindings(is_interactive = function() FALSE)
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  sub <- file.path(dir, "analysis")
  dir.create(sub)
  withr::local_dir(sub)

  messages <- capture_messages(use_pixi(install_rpix = FALSE))

  expect_equal(calls$args[[1]], c("init", sub))
  expect_true(all(vapply(calls$paths[-1], identical, logical(1), sub)))
  expect_true(file.exists(file.path(sub, ".Rprofile")))
  expect_false(file.exists(file.path(dir, ".Rprofile")))
  expect_true(any(grepl(
    paste0("use_pixi(path = \"", dir, "\")"),
    messages,
    fixed = TRUE
  )))
})

test_that("use_pixi() asks whether to set up the parent project instead", {
  calls <- local_mock_setup()
  answer <- TRUE
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_yes_no = function(question) answer
  )
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  sub <- file.path(dir, "analysis")
  dir.create(sub)

  manifest <- suppressMessages(use_pixi(path = sub, install_rpix = FALSE))
  expect_equal(manifest, file.path(dir, "pixi.toml"))
  expect_equal(calls$args[[1]][1], "add")
  expect_equal(calls$paths[[1]], dir)
  expect_false(file.exists(file.path(sub, "pixi.toml")))

  answer <- FALSE
  manifest <- suppressMessages(use_pixi(path = sub, install_rpix = FALSE))
  expect_equal(manifest, file.path(sub, "pixi.toml"))
})

test_that("use_pixi() can leave the activation cache off", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))

  suppressMessages(use_pixi(
    path = dir,
    install_rpix = FALSE,
    activation_cache = FALSE
  ))
  expect_false(list(activation_cache_args) %in% calls$args)
})

test_that("use_pixi() carries on when Pixi doesn't know the activation cache", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  local_mocked_bindings(
    run_pixi = function(args, path = NULL, ...) {
      if (args[1] == "config") {
        cli::cli_abort("Unknown key", class = "rpix_error_pixi")
      }
      invisible(list(status = 0))
    }
  )

  messages <- capture_messages(use_pixi(path = dir, install_rpix = FALSE))
  expect_true(any(grepl("Couldn't turn on Pixi's activation cache", messages)))
})

test_that("use_pixi() errors without a project if it may not create one", {
  calls <- local_mock_setup()
  withr::local_dir(withr::local_tempdir())

  expect_error(use_pixi(init_if_missing = FALSE), "no Pixi project")
  expect_length(calls$args, 0)
})

test_that("use_pixi() removes the old .Rprofile block and warns about a global one", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  file.copy(legacy_fixture(), file.path(dir, ".Rprofile"))
  file.copy(legacy_fixture(), file.path(calls$home, ".Rprofile"))
  withr::local_dir(dir)

  expect_warning(
    suppressMessages(use_pixi(install_rpix = FALSE)),
    "still has the Pixi library setup"
  )
  expect_false(any(grepl("Pixi R library setup", readLines(".Rprofile"))))
})

# remove_legacy_rprofile() -----------------------------------------------------

test_that("removes only the old block, keeping the rest of the file", {
  file <- withr::local_tempfile()
  file.copy(legacy_fixture(), file)

  expect_true(suppressMessages(remove_legacy_rprofile(file)))
  expect_equal(
    readLines(file),
    c(
      "# Something the user wrote",
      "options(digits = 4)",
      "",
      "",
      "# Something the user added later",
      "options(width = 100)"
    )
  )
  # Running it again changes nothing
  expect_false(remove_legacy_rprofile(file))
})

test_that("does nothing without a file or without the block", {
  expect_false(remove_legacy_rprofile(file.path(
    withr::local_tempdir(),
    ".Rprofile"
  )))

  file <- withr::local_tempfile()
  writeLines("options(digits = 4)", file)
  expect_false(remove_legacy_rprofile(file))
  expect_equal(readLines(file), "options(digits = 4)")
})

test_that("leaves a block it can't find the end of", {
  file <- withr::local_tempfile()
  writeLines(c("# Pixi R library setup", "local({", "  x <- 1"), file)

  expect_warning(remove_legacy_rprofile(file), "Remove it by hand")
  expect_length(readLines(file), 3)
})

# rpix_dependencies() ----------------------------------------------------------

test_that("rpix's dependencies are translated to conda names", {
  expect_equal(
    rpix_dependencies("cli (>= 3.0.0),\n    jsonlite, processx"),
    c("r-cli", "r-jsonlite", "r-processx")
  )
  expect_true(all(c("r-cli", "r-processx") %in% rpix_dependencies()))
})

test_that("use_pixi() sets up the IDEs it's asked to", {
  calls <- local_mock_setup()
  dir <- withr::local_tempdir()
  writeLines("[workspace]", file.path(dir, "pixi.toml"))
  withr::local_dir(dir)
  ides <- character()
  local_mocked_bindings(
    use_pixi_positron = function(path, default_r = NULL) {
      ides <<- c(ides, positron = default_r %||% NA)
    },
    use_pixi_vscode = function(path, console = NULL) {
      ides <<- c(ides, vscode = console %||% NA)
    }
  )

  suppressMessages(use_pixi(
    ide = c("vscode", "positron"),
    install_rpix = FALSE,
    console = "arf"
  ))
  # Each IDE gets its own settings
  expect_equal(ides, c(vscode = "arf", positron = NA))
  # Added with R, so Pixi picks an R that languageserver is built for
  expect_equal(
    calls$args[[1]],
    c(
      "add",
      "r-base",
      "conda-ecosystem-user-package-isolation",
      "r-languageserver"
    )
  )
  expect_error(use_pixi(ide = "notepad"), "should be one of")
})

test_that("use_pixi() sets up the folder in `path`", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  withr::local_dir(withr::local_tempdir())

  manifest <- suppressMessages(use_pixi(path = dir, install_rpix = FALSE))
  expect_equal(manifest, file.path(dir, "pixi.toml"))
  expect_equal(calls$args[[1]], c("init", dir))
})

test_that("use_pixi() adds the platforms it's given to a new project", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")

  suppressMessages(use_pixi(
    path = dir,
    install_rpix = FALSE,
    platforms = c("linux-64", "linux-aarch64")
  ))
  expect_equal(
    calls$args[[2]],
    c(
      "workspace",
      "platform",
      "add",
      "linux-64",
      "linux-aarch64",
      "--no-install"
    )
  )
  expect_equal(calls$paths[[2]], dir)
})

test_that("rpix's dependencies include rlang, which cli needs for errors", {
  # Without it, every rpix error in a new project became "there is no
  # package called 'rlang'"
  expect_true("r-rlang" %in% rpix_dependencies())
})

test_that("use_pixi() leaves Pixi's files out of a package's builds", {
  local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  writeLines("Package: demo", file.path(dir, "DESCRIPTION"))
  writeLines("^demo\\.Rproj$", file.path(dir, ".Rbuildignore"))

  expect_snapshot(
    use_pixi(path = dir, install_rpix = FALSE),
    transform = function(x) {
      gsub(dir, "<dir>", x, fixed = TRUE)
    }
  )
  expect_equal(
    readLines(file.path(dir, ".Rbuildignore")),
    c("^demo\\.Rproj$", "^\\.pixi$", "^pixi\\.toml$", "^pixi\\.lock$")
  )
})

test_that("use_pixi() sets the date before adding anything", {
  calls <- local_mock_setup()
  dir <- normalizePath(withr::local_tempdir(), winslash = "/")
  suppressMessages(use_pixi(
    date = "2025-06-01",
    path = dir,
    install_rpix = FALSE
  ))
  expect_true(
    'exclude-newer = "2025-06-01"' %in% readLines(file.path(dir, "pixi.toml"))
  )
  expect_error(use_pixi(date = "soon", path = dir), "must be a date")
})

test_that("use_pixi() only passes on settings of the IDEs it sets up", {
  expect_error(use_pixi(console = "arf"), "settings of the IDEs")
  expect_error(
    use_pixi(ide = "positron", console = "arf"),
    "settings of the IDEs"
  )
})
