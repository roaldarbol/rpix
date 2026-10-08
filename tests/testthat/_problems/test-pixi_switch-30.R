# Extracted from test-pixi_switch.R:30

# prequel ----------------------------------------------------------------------
local_switch_project <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines("Version: 1.0", file.path(dir, "demo.Rproj"))
  calls <- local_recorded_pixi(env = env)
  local_mocked_bindings(
    require_project = function(path) dir,
    pixi_environments = function(path) data.frame(name = c("default", "r44")),
    .env = env
  )
  calls$dir <- dir
  calls
}

# test -------------------------------------------------------------------------
calls <- local_switch_project()
