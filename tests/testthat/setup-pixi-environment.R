# The tests may run in a Pixi environment other than "default", e.g. the
# check matrix's. Tests that run Pixi in a temporary project unset
# PIXI_PROJECT_ROOT, and Pixi only ignores the inherited environment name when
# it can tell the projects apart by their roots, so it would look for that
# environment in the temporary project too.
withr::local_envvar(
  PIXI_ENVIRONMENT_NAME = NA,
  .local_envir = testthat::teardown_env()
)
