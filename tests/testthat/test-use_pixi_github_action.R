# A project with a pixi.toml, without running Pixi. `environments` gives each
# environment's dependencies, and `features` its features (the environment's
# own name and, except for the default environment, "default").
local_action_project <- function(
  platforms = c("linux-64", "osx-arm64", "win-64"),
  environments = list(default = c("r-base", "r-rcmdcheck")),
  features = NULL,
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(c("[workspace]", 'name = "demo"'), file.path(dir, "pixi.toml"))
  features <- features %||%
    lapply(names(environments), function(name) unique(c(name, "default")))
  local_mocked_bindings(
    require_project = function(path) dir,
    project_platforms = function(path) platforms,
    installed_pixi_version = function() "v0.81.0",
    pixi_info = function(path) {
      list(
        environments_info = data.frame(
          name = names(environments),
          features = I(features),
          dependencies = I(unname(environments))
        )
      )
    },
    .env = env
  )
  dir
}

# A package's DESCRIPTION in the project
local_package <- function(
  dir,
  imports = "cli",
  suggests = c("testthat", "withr")
) {
  writeLines(
    c(
      "Package: demo",
      "Version: 0.0.1",
      paste("Depends: R (>= 4.1)"),
      paste("Imports:", paste(imports, collapse = ", ")),
      paste("Suggests:", paste(suggests, collapse = ", "))
    ),
    file.path(dir, "DESCRIPTION")
  )
}

# A package set up with pixi_import_description() and
# use_pixi_check_matrix(c("4.4", "4.5"), minimum = TRUE)
matrix_packages <- c(
  "r-base",
  "r-cli",
  "r-testthat",
  "r-withr",
  "r-pkgload",
  "r-rcmdcheck"
)
package_environments <- list(
  default = c("r-base", "r-cli"),
  test = c("r-testthat", "r-withr", "r-base", "r-cli"),
  r44 = matrix_packages,
  r45 = matrix_packages,
  minimum = matrix_packages
)
package_features <- list(
  "default",
  c("test", "default"),
  "r44",
  "r45",
  "minimum"
)

workflow_file <- function(dir, name) {
  readLines(file.path(
    dir,
    ".github",
    "workflows",
    paste0("pixi-", name, ".yaml")
  ))
}

test_that("use_pixi_github_action() writes a check workflow from the template", {
  dir <- local_action_project(
    environments = list(
      default = "r-base",
      r44 = c("r-base", "r-rcmdcheck"),
      minimum = c("r-base", "r-rcmdcheck")
    )
  )
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
  dir <- local_action_project(environments = list(default = "r-base"))
  expect_snapshot(use_pixi_github_action("pkgdown"))
  lines <- workflow_file(dir, "pkgdown")
  expect_true("          environments: default" %in% lines)

  dir <- local_action_project(
    environments = list(default = c("r-base", "r-covr", "r-xml2"))
  )
  expect_no_message(
    use_pixi_github_action("test-coverage"),
    message = "lacks"
  )
})

test_that("use_pixi_github_action() checks in the environments that can", {
  dir <- local_action_project(
    environments = package_environments,
    features = package_features
  )
  # notonconda is in no environment, so no environment can have it
  local_package(dir, suggests = c("testthat", "withr", "notonconda"))
  expect_snapshot(use_pixi_github_action("check"))
  expect_true(
    "        environment: [r44, r45, minimum]" %in% workflow_file(dir, "check")
  )

  # The default environment lacks the Suggests, and rcmdcheck
  expect_snapshot(use_pixi_github_action(
    "check",
    c("r44", "default"),
    overwrite = TRUE
  ))
  expect_true(
    "        environment: [r44, default]" %in% workflow_file(dir, "check")
  )
})

test_that("use_pixi_github_action() stops if no environment can check", {
  dir <- local_action_project(
    environments = package_environments[c("default", "test")],
    features = package_features[1:2]
  )
  local_package(dir)
  expect_snapshot(use_pixi_github_action("check"), error = TRUE)
  expect_false(file.exists(file.path(dir, ".github")))
})

test_that("use_pixi_github_action() uses the first environment that has what it needs", {
  dir <- local_action_project(
    environments = list(
      default = c("r-base", "bioconductor-limma"),
      test = c("r-covr", "r-xml2", "r-base", "bioconductor-limma"),
      docs = c("r-pkgdown", "pandoc", "r-base")
    )
  )
  local_package(dir, imports = "limma", suggests = character())
  expect_snapshot(use_pixi_github_action("test-coverage"))
  expect_true(
    "          environments: test" %in% workflow_file(dir, "test-coverage")
  )

  # docs lacks limma, from Bioconductor
  expect_snapshot(use_pixi_github_action("pkgdown", "docs"))
})

test_that("use_pixi_github_action() stops at environments the project doesn't have", {
  local_action_project()
  expect_snapshot(use_pixi_github_action("check", "r44"), error = TRUE)
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

  suppressMessages(use_pixi_github_action("task", task = "report"))
  expect_true(
    "        environment: [default]" %in% workflow_file(dir, "report")
  )
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

test_that("installed_pixi_version() writes Pixi's version as setup-pixi takes it", {
  local_mocked_bindings(
    run_pixi = function(...) list(stdout = "pixi 0.81.0\n")
  )
  expect_equal(installed_pixi_version(), "v0.81.0")
})

test_that("use_pixi_github_action() offers to add linux-64", {
  dir <- local_action_project(platforms = "osx-64")
  has <- "osx-64"
  local_mocked_bindings(
    project_platforms = function(path) has,
    is_interactive = function() TRUE,
    ask_yes_no = function(question) TRUE,
    pixi_add_platform = function(platforms, path) has <<- c(has, platforms)
  )
  suppressMessages(use_pixi_github_action("check"))
  expect_equal(has, c("osx-64", "linux-64"))
  expect_true("        os: [ubuntu-latest]" %in% workflow_file(dir, "check"))
})
