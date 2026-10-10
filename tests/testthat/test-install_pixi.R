# install_pixi() with Pixi's installer, the download and the questions mocked
local_install_pixi <- function(
  installed = NULL,
  answer = TRUE,
  interactive = TRUE,
  windows = FALSE,
  download = TRUE,
  status = 0,
  env = parent.frame()
) {
  calls <- new.env()
  calls$asked <- character()
  calls$found <- installed
  local_mocked_bindings(
    pixi_binary = function(...) {
      if (is.null(calls$found)) {
        stop("Could not find Pixi.")
      }
      calls$found
    },
    is_interactive = function() interactive,
    ask_yes_no = function(question) {
      calls$asked <- c(calls$asked, question)
      answer
    },
    is_windows = function() windows,
    home_dir = function() "/home/me",
    download_installer = function(url, destination) {
      calls$url <- url
      if (!download) stop("offline")
    },
    run_installer = function(installer, windows, env) {
      calls$env <- env
      calls$windows <- windows
      if (status == 0) {
        calls$found <- "/home/me/.pixi/bin/pixi"
      }
      status
    },
    pixi_version = function(pixi) "pixi 0.81.0",
    .env = env
  )
  withr::local_envvar(PIXI_HOME = NA, .local_envir = env)
  calls
}

test_that("install_pixi() leaves an installed Pixi alone", {
  calls <- local_install_pixi(installed = "/usr/local/bin/pixi")
  expect_snapshot(path <- install_pixi())
  expect_equal(path, "/usr/local/bin/pixi")
  expect_null(calls$url)
})

test_that("install_pixi() asks, then runs Pixi's installer", {
  calls <- local_install_pixi()
  expect_snapshot(path <- install_pixi())
  expect_equal(path, "/home/me/.pixi/bin/pixi")
  expect_equal(
    calls$asked,
    "Install Pixi into /home/me/.pixi/bin, and add it to your shell's PATH?"
  )
  expect_equal(calls$url, "https://pixi.sh/install.sh")
  expect_equal(calls$env, "current")
})

test_that("install_pixi() passes the version and PATH choice to the installer", {
  calls <- local_install_pixi(
    installed = "/usr/local/bin/pixi",
    interactive = FALSE,
    windows = TRUE
  )
  suppressMessages(
    install_pixi(version = "0.81.0", update_path = FALSE, force = TRUE)
  )
  expect_length(calls$asked, 0)
  expect_equal(calls$url, "https://pixi.sh/install.ps1")
  expect_true(calls$windows)
  expect_equal(
    calls$env,
    c("current", PIXI_VERSION = "0.81.0", PIXI_NO_PATH_UPDATE = "1")
  )
})

test_that("install_pixi() stops if the answer is no, or something fails", {
  local_install_pixi(answer = FALSE)
  expect_error(install_pixi(), class = "rpix_cancelled")

  local_install_pixi(download = FALSE)
  expect_snapshot(install_pixi(), error = TRUE)

  local_install_pixi(status = 1)
  expect_snapshot(install_pixi(), error = TRUE)
})

test_that("installer_command() runs sh or PowerShell", {
  expect_equal(installer_command("/tmp/i.sh", FALSE), c("sh", "/tmp/i.sh"))
  expect_equal(
    installer_command("C:/tmp/i.ps1", TRUE),
    c(
      "powershell",
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      "C:/tmp/i.ps1"
    )
  )
})

test_that("run_installer() returns the installer's exit status", {
  skip_on_os("windows")
  script <- withr::local_tempfile(fileext = ".sh")
  writeLines(c("echo installing", "exit 3"), script)
  output <- capture.output(status <- run_installer(script, FALSE, "current"))
  expect_equal(status, 3)
  expect_equal(output, "installing")
})

test_that("download_installer() downloads Pixi's installer", {
  skip_on_cran()
  skip_if_offline("pixi.sh")
  file <- withr::local_tempfile(fileext = ".sh")
  download_installer("https://pixi.sh/install.sh", file)
  expect_match(readLines(file), "PIXI_HOME", all = FALSE)
})

test_that("pixi_version() asks a Pixi for its version", {
  skip_if_no_pixi()
  expect_match(pixi_version(pixi_binary()), "^pixi [0-9]")
})
