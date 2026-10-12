# A project with a pixi.toml, without running Pixi
local_action_project <- function(
  platforms = c("linux-64", "osx-arm64", "win-64"),
  dependencies = c('r-base = "4.5.*"', 'r-rcmdcheck = "*"'),
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(
    c("[workspace]", 'name = "demo"', "", "[dependencies]", dependencies),
    file.path(dir, "pixi.toml")
  )
  local_mocked_bindings(
    require_project = function(path) dir,
    project_platforms = function(path) platforms,
    installed_pixi_version = function() "v0.81.0",
    .env = env
  )
  dir
}

workflow_file <- function(dir, name) {
  readLines(file.path(
    dir,
    ".github",
    "workflows",
    paste0("pixi-", name, ".yaml")
  ))
}

test_that("use_pixi_github_action() writes a check workflow from the template", {
  dir <- local_action_project()
  expect_snapshot(file <- use_pixi_github_action("check", c("r44", "minimum")))
  expect_equal(basename(file), "pixi-check.yaml")
  lines <- workflow_file(dir, "check")
  expect_true(
    "        os: [ubuntu-latest, macos-latest, windows-latest]" %in% lines
  )
  expect_true("        environment: [r44, minimum]" %in% lines)
  expect_true("          pixi-version: v0.81.0" %in% lines)
  expect_true("      - uses: prefix-dev/setup-pixi@v0.10.2" %in% lines)
  expect_true("      - uses: r-lib/actions/check-r-package@v2" %in% lines)
  # No placeholders left, and GitHub's own expressions untouched
  expect_false(any(grepl(
    "{{",
    gsub("${{", "", lines, fixed = TRUE),
    fixed = TRUE
  )))
  expect_true(any(grepl("${{ matrix.environment }}", lines, fixed = TRUE)))
})

test_that("use_pixi_github_action() runs only where the project has platforms", {
  dir <- local_action_project(platforms = c("linux-64", "osx-64"))
  expect_snapshot(use_pixi_github_action("check"))
  expect_true("        os: [ubuntu-latest]" %in% workflow_file(dir, "check"))

  local_action_project(platforms = "osx-64")
  expect_snapshot(use_pixi_github_action("check"), error = TRUE)
})

test_that("use_pixi_github_action() says what the environment lacks", {
  dir <- local_action_project(dependencies = 'r-base = "4.5.*"')
  expect_snapshot(use_pixi_github_action("pkgdown"))
  lines <- workflow_file(dir, "pkgdown")
  expect_true("          environments: default" %in% lines)

  dir <- local_action_project(
    dependencies = c('r-covr = "*"', '"r-xml2" = "*"')
  )
  expect_no_message(
    use_pixi_github_action("test-coverage"),
    message = "needs"
  )
})

test_that("use_pixi_github_action() runs a task", {
  dir <- local_action_project()
  suppressMessages(use_pixi_github_action("task", "default", task = "render"))
  lines <- workflow_file(dir, "render")
  expect_true("name: pixi-render" %in% lines)
  expect_true(
    "      - run: pixi run --environment ${{ matrix.environment }} render" %in%
      lines
  )
  expect_error(use_pixi_github_action("task"), "task")
})

test_that("use_pixi_github_action() doesn't replace a workflow unless asked", {
  dir <- local_action_project()
  suppressMessages(use_pixi_github_action("check"))
  expect_snapshot(use_pixi_github_action("check"), error = TRUE)
  expect_no_error(suppressMessages(use_pixi_github_action(
    "check",
    overwrite = TRUE
  )))
})

test_that("use_pixi_github_action() leaves .github out of a package's builds", {
  dir <- local_action_project()
  writeLines("Package: demo", file.path(dir, "DESCRIPTION"))
  suppressMessages(use_pixi_github_action("check"))
  expect_true("^\\.github$" %in% readLines(file.path(dir, ".Rbuildignore")))
})

test_that("manifest_has_package() finds R and conda packages", {
  dir <- local_action_project(
    dependencies = c(
      'r-rcmdcheck = "*"',
      "pandoc = '*'",
      '"r-data.table" = "*"'
    )
  )
  expect_true(manifest_has_package("rcmdcheck", dir))
  expect_true(manifest_has_package("conda::pandoc", dir))
  expect_true(manifest_has_package("data.table", dir))
  expect_false(manifest_has_package("covr", dir))
  expect_false(manifest_has_package("covr", withr::local_tempdir()))
})

test_that("installed_pixi_version() writes Pixi's version as setup-pixi takes it", {
  local_mocked_bindings(
    run_pixi = function(...) list(stdout = "pixi 0.81.0\n")
  )
  expect_equal(installed_pixi_version(), "v0.81.0")
})
