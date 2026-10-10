test_that("build_ignore() adds patterns to a package's .Rbuildignore", {
  dir <- withr::local_tempdir()
  writeLines("Package: demo", file.path(dir, "DESCRIPTION"))

  expect_snapshot(added <- build_ignore(dir, c(".pixi", "pixi.toml")))
  expect_equal(added, c("^\\.pixi$", "^pixi\\.toml$"))
  # Only once
  expect_silent(build_ignore(dir, c(".pixi", "pixi.toml")))
  expect_equal(readLines(file.path(dir, ".Rbuildignore")), added)
})

test_that("build_ignore() leaves projects that aren't packages alone", {
  dir <- withr::local_tempdir()
  expect_length(build_ignore(dir, ".pixi"), 0)
  writeLines("Title: not a package", file.path(dir, "DESCRIPTION"))
  expect_length(build_ignore(dir, ".pixi"), 0)
  expect_false(file.exists(file.path(dir, ".Rbuildignore")))
})

test_that("missing_build_ignores() knows patterns written another way", {
  dir <- withr::local_tempdir()
  writeLines("Package: demo", file.path(dir, "DESCRIPTION"))
  writeLines(
    c("# Pixi", "", "^\\.PIXI", "pixi\\.(toml|lock)", "[invalid"),
    file.path(dir, ".Rbuildignore")
  )
  expect_length(
    missing_build_ignores(dir, c(".pixi", "pixi.toml", "pixi.lock")),
    0
  )
  expect_equal(missing_build_ignores(dir, ".vscode"), ".vscode")
})

test_that("pixi_files() names the project's manifest", {
  dir <- withr::local_tempdir()
  expect_equal(pixi_files(dir), c(".pixi", "pixi.toml", "pixi.lock"))
  writeLines("[tool.pixi.workspace]", file.path(dir, "pyproject.toml"))
  expect_equal(pixi_files(dir), c(".pixi", "pyproject.toml", "pixi.lock"))
})
