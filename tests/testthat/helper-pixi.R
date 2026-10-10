skip_if_no_pixi <- function() {
  found <- tryCatch(pixi_binary(offer_install = FALSE), error = function(e) {
    NULL
  })
  skip_if(is.null(found), "pixi is not installed")
}

# A temporary directory with an empty pixi.toml, removed after the test
local_pixi_project <- function(
  manifest = "pixi.toml",
  content = "",
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(content, file.path(dir, manifest))
  normalizePath(dir, winslash = "/")
}

# Record the arguments pixi is called with
local_recorded_pixi <- function(
  result = invisible(list(status = 0)),
  env = parent.frame()
) {
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      result
    },
    .env = env
  )
  calls
}
