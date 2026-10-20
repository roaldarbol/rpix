local_python_project <- function(python = "3.13.16", env = parent.frame()) {
  root <- local_pixi_project(
    content = c("[workspace]", "", "[dependencies]", 'r-base = "4.5.*"'),
    env = env
  )
  calls <- new.env()
  calls$added <- list()
  calls$root <- root
  local_mocked_bindings(
    add_missing = function(packages, root) {
      calls$added <- c(calls$added, list(packages))
    },
    installed_python_version = function(root) package_version(python),
    project_platforms = function(path) c("linux-64", "win-64"),
    .env = env
  )
  calls
}

test_that("use_pixi_python() adds Python and points reticulate at it", {
  calls <- local_python_project()
  expect_snapshot(use_pixi_python(path = calls$root), transform = function(x) {
    gsub(calls$root, "<root>", x, fixed = TRUE)
  })
  expect_equal(calls$added, list(c("python", "r-reticulate", "micromamba")))
  expect_snapshot(cat(
    readLines(file.path(calls$root, "pixi.toml")),
    sep = "\n"
  ))
  # Again, it changes nothing
  before <- readLines(file.path(calls$root, "pixi.toml"))
  suppressMessages(use_pixi_python(path = calls$root))
  expect_equal(readLines(file.path(calls$root, "pixi.toml")), before)
})

test_that("use_pixi_python() adds libpython for Python 3.15 or later, at a version", {
  calls <- local_python_project(python = "3.15.0")
  suppressMessages(use_pixi_python("3.15", path = calls$root))
  expect_equal(
    calls$added,
    list(c("python=3.15", "r-reticulate", "micromamba"), "libpython")
  )
})

test_that("use_pixi_python() writes pyproject.toml's tables", {
  lines <- set_python_activation(
    c("[project]", 'name = "x"', "", "[tool.pixi.workspace]"),
    "/x/pyproject.toml"
  )
  expect_true("[tool.pixi.activation.env]" %in% lines)
  expect_true("[tool.pixi.target.win-64.activation.env]" %in% lines)
})

test_that("installed_python_version() reads pixi list, or NA", {
  local_mocked_bindings(
    pixi_list = function(...) {
      data.frame(name = c("r-base", "python"), version = c("4.5.3", "3.13.16"))
    }
  )
  expect_equal(installed_python_version("/x"), package_version("3.13.16"))
  local_mocked_bindings(pixi_list = function(...) stop("no Pixi"))
  expect_true(is.na(installed_python_version("/x")))
})

test_that("use_pixi_python() leaves out Windows in a project without win-64", {
  lines <- set_python_activation(
    c("[workspace]"),
    "/x/pixi.toml",
    windows = FALSE
  )
  expect_true("[activation.env]" %in% lines)
  expect_false(any(grepl("win-64", lines)))
})
