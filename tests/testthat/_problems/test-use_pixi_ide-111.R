# Extracted from test-use_pixi_ide.R:111

# prequel ----------------------------------------------------------------------
local_ide_project <- function(platforms = "osx-arm64", env = parent.frame()) {
  root <- normalizePath(
    withr::local_tempdir(.local_envir = env),
    winslash = "/"
  )
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  withr::local_envvar(PIXI_PROJECT_ROOT = NA, .local_envir = env)
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
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

# test -------------------------------------------------------------------------
p <- local_ide_project()
