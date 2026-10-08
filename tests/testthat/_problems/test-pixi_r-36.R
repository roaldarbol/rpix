# Extracted from test-pixi_r.R:36

# prequel ----------------------------------------------------------------------
local_pixi_r_here <- function(env = parent.frame()) {
  calls <- new.env()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- args
      calls$dots <- list(...)
      processx::run(
        file.path(R.home("bin"), "Rscript"),
        utils::tail(args, 4)
      )
    },
    .env = env
  )
  calls
}

# test -------------------------------------------------------------------------
local_pixi_r_here()
