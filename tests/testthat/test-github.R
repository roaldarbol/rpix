# Pretend GitHub, with a DESCRIPTION for each repository
local_github <- function(
  packages = c(emo = "emo", praise = "praise", Rcppy = "RcppY"),
  env = parent.frame()
) {
  local_mocked_bindings(
    read_url = function(url) {
      repo <- sub(
        "^https://raw.githubusercontent.com/[^/]+/([^/]+)/.*$",
        "\\1",
        url
      )
      if (!repo %in% names(packages)) {
        stop("404")
      }
      c(paste("Package:", packages[[repo]]), "Version: 1.0.0")
    },
    .env = env
  )
}

test_that("parse_github() reads the repository, ref and package name", {
  local_github()
  expect_equal(
    parse_github("github::hadley/emo"),
    list(git = "https://github.com/hadley/emo", ref = NULL, name = "r-emo")
  )
  expect_equal(parse_github("github::cran/praise@1.0.0")$ref, "1.0.0")
  # The package's name, which can differ from the repository's
  expect_equal(parse_github("GitHub::me/Rcppy")$name, "r-rcppy")
})

test_that("parse_github() explains bad references and missing packages", {
  local_github()
  expect_snapshot(error = TRUE, {
    parse_github("github::emo")
    parse_github("github::hadley/nope")
    parse_github("github::hadley/nope@dev")
  })
})

test_that("github_entry() builds with pixi-build-r, pinned to the project's R", {
  github <- list(
    git = "https://github.com/hadley/emo",
    ref = "v1",
    name = "r-emo"
  )
  expect_equal(
    github_entry(github, "4.5.*"),
    'r-emo = { git = "https://github.com/hadley/emo", rev = "v1", package = { build.backend.name = "pixi-build-r", host-dependencies = { r-base = "4.5.*" } } }'
  )
  github$ref <- NULL
  expect_equal(
    github_entry(github),
    'r-emo = { git = "https://github.com/hadley/emo", package = { build.backend.name = "pixi-build-r" } }'
  )
})

manifest <- c(
  "[workspace]",
  'name = "demo"',
  'channels = ["conda-forge"]',
  "",
  "[dependencies]",
  'r-base = "4.5.*"',
  'r-cli = "*"',
  "",
  "[feature.r44.dependencies]",
  'r-base = "4.4.*"',
  "",
  "[tasks]",
  'test = "Rscript -e 1"'
)

test_that("set_dependency() adds to a table, or replaces what's there", {
  lines <- set_dependency(manifest, "dependencies", "r-emo", "r-emo = 1")
  expect_equal(
    lines[5:8],
    c("[dependencies]", 'r-base = "4.5.*"', 'r-cli = "*"', "r-emo = 1")
  )

  lines <- set_dependency(lines, "dependencies", "r-emo", "r-emo = 2")
  expect_equal(sum(grepl("^r-emo", lines)), 1)
  expect_true("r-emo = 2" %in% lines)

  lines <- set_dependency(
    manifest,
    "feature.r44.dependencies",
    "r-emo",
    "r-emo = 1"
  )
  expect_equal(
    lines[match("[feature.r44.dependencies]", lines) + 2],
    "r-emo = 1"
  )

  lines <- set_dependency(
    c(manifest, ""),
    "target.linux-64.dependencies",
    "r-emo",
    "r-emo = 1"
  )
  expect_equal(
    utils::tail(lines, 3),
    c("", "[target.linux-64.dependencies]", "r-emo = 1")
  )
})

test_that("enable_preview() turns on a preview feature once", {
  lines <- enable_preview(manifest, "pixi-build")
  expect_equal(lines[4], 'preview = ["pixi-build"]')
  expect_identical(enable_preview(lines, "pixi-build"), lines)

  lines <- c("[workspace]", 'preview = ["pixi-other"]')
  expect_equal(
    enable_preview(lines, "pixi-build")[2],
    'preview = ["pixi-build", "pixi-other"]'
  )
  expect_equal(
    enable_preview(c("[workspace]", "preview = []"), "pixi-build")[2],
    'preview = ["pixi-build"]'
  )
  expect_equal(
    enable_preview(c("[project]", 'name = "x"'), "pixi-build")[3],
    'preview = ["pixi-build"]'
  )
  expect_equal(
    enable_preview("[tasks]", "pixi-build")[1],
    '[workspace]\npreview = ["pixi-build"]'
  )
})

test_that("manifest_r_base() finds the R a feature or the project uses", {
  expect_equal(manifest_r_base(manifest), "4.5.*")
  expect_equal(manifest_r_base(manifest, "r44"), "4.4.*")
  expect_equal(manifest_r_base(manifest, "test"), "4.5.*")
  expect_null(manifest_r_base("[workspace]"))
})

test_that("dependency_table() names the table for a feature and platform", {
  expect_equal(dependency_table(), "dependencies")
  expect_equal(
    dependency_table("test", "win-64"),
    "feature.test.target.win-64.dependencies"
  )
})

local_github_project <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  writeLines(manifest, file.path(dir, "pixi.toml"))
  local_github(env = env)
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      if (isTRUE(calls$fail)) {
        stop("build failed")
      }
      invisible(list(status = 0))
    },
    project_channels = function(...) "conda-forge",
    .env = env
  )
  calls$dir <- dir
  calls
}

test_that("pixi_add() adds GitHub packages to pixi.toml, and Pixi installs them", {
  calls <- local_github_project()

  expect_snapshot(pixi_add(c("dplyr", "github::hadley/emo"), path = calls$dir))
  expect_equal(calls$args[[1]][1:2], c("add", "r-dplyr"))
  expect_equal(calls$args[[2]], "install")
  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_true('preview = ["pixi-build"]' %in% lines)
  expect_true(any(grepl('^r-emo = .*r-base = "4.5.\\*"', lines)))

  # In a feature, Pixi only locks
  pixi_add("github::cran/praise@1.0.0", feature = "r44", path = calls$dir) |>
    suppressMessages()
  expect_equal(utils::tail(calls$args, 1)[[1]], "lock")
  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_true(any(grepl(
    '^r-praise = .*rev = "1.0.0".*r-base = "4.4.\\*"',
    lines
  )))
})

test_that("pixi_add() puts pixi.toml back if Pixi can't build the package", {
  calls <- local_github_project()
  calls$fail <- TRUE
  before <- readLines(file.path(calls$dir, "pixi.toml"))

  expect_snapshot(
    pixi_add("github::hadley/emo", path = calls$dir),
    error = TRUE
  )
  expect_equal(readLines(file.path(calls$dir, "pixi.toml")), before)
})

test_that("pixi_add() shows what it would add to pixi.toml", {
  calls <- local_github_project()
  before <- readLines(file.path(calls$dir, "pixi.toml"))

  expect_snapshot(pixi_add(
    "github::hadley/emo",
    path = calls$dir,
    dry_run = TRUE
  ))
  expect_equal(readLines(file.path(calls$dir, "pixi.toml")), before)
  expect_length(calls$args, 0)
})

test_that("pixi_add() needs pixi.toml for GitHub packages", {
  dir <- withr::local_tempdir()
  writeLines(
    c("[project]", "[tool.pixi.workspace]"),
    file.path(dir, "pyproject.toml")
  )
  expect_error(pixi_add("github::hadley/emo", path = dir), "pixi.toml")
})

test_that("pixi_remove() removes GitHub packages by their package name", {
  calls <- local_github_project()
  pixi_remove(c("github::hadley/emo", "cli"), path = calls$dir)
  expect_equal(calls$args[[1]][1:3], c("remove", "r-cli", "r-emo"))
  pixi_remove("github::hadley/emo", path = calls$dir)
  expect_equal(calls$args[[2]][1:2], c("remove", "r-emo"))
})

test_that("read_url() reads a URL, and fails without a warning", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  expect_match(
    read_url(
      "https://raw.githubusercontent.com/cran/praise/master/DESCRIPTION"
    ),
    "Package: praise",
    all = FALSE
  )
  expect_no_warning(
    expect_error(read_url(
      "https://raw.githubusercontent.com/cran/praise/master/NOPE"
    ))
  )
})

test_that("versions gives a GitHub package's branch, tag or commit", {
  expect_equal(
    with_github_refs(
      c("github::cran/praise", "github::hadley/emo", "github::me/x"),
      c("==1.0.0", "main", NA)
    ),
    c("github::cran/praise@1.0.0", "github::hadley/emo@main", "github::me/x")
  )
  expect_equal(with_github_refs("github::me/x", NULL), "github::me/x")
  expect_snapshot(error = TRUE, {
    with_github_refs("github::cran/praise", ">=1.0")
    with_github_refs("github::cran/praise@1.0.0", "1.0.0")
  })
})

test_that("pixi_add() takes versions for GitHub packages, next to others", {
  calls <- local_github_project()

  pixi_add(
    c("dplyr>=1.1", "github::cran/praise"),
    versions = c(NA, "1.0.0"),
    path = calls$dir
  ) |>
    suppressMessages()
  expect_equal(calls$args[[1]][1:2], c("add", "r-dplyr>=1.1"))
  lines <- readLines(file.path(calls$dir, "pixi.toml"))
  expect_true(any(grepl('^r-praise = .*rev = "1.0.0"', lines)))

  expect_error(
    pixi_add(c("dplyr", "github::cran/praise"), versions = c("1", "2", "3")),
    "length 1"
  )
  expect_error(
    pixi_add("github::cran/praise", channel = "bioconda", path = calls$dir),
    "doesn't apply"
  )
})
