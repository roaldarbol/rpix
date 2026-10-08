# Extracted from test-pixi_sitrep.R:105

# prequel ----------------------------------------------------------------------
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

# test -------------------------------------------------------------------------
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
