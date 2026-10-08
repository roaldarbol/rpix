skip_if_no_pixi <- function() {
  found <- tryCatch(pixi_binary(), error = function(e) NULL)
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
