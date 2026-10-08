# Extracted from test-use_pixi.R:75

# prequel ----------------------------------------------------------------------
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
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, .local_envir = env)
  calls$home <- home
  calls
}
legacy_fixture <- function() {
  test_path("fixtures", "legacy-rprofile.txt")
}

# test -------------------------------------------------------------------------
calls <- local_mock_setup()
