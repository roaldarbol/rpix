test_that("build_requirements() finds build tools in SystemRequirements", {
  tools <- function(text, older_backend = FALSE) {
    build_requirements(
      list(Package = "x", SystemRequirements = text),
      older_backend
    )
  }
  expect_equal(tools("CMake")$build, "cmake")
  expect_equal(tools("libxml2, pkg-config")$build, "pkg-config")

  # Java is needed when the package runs, too
  java <- tools("Java (>= 8)")
  expect_equal(java$build, "openjdk")
  expect_equal(java$run, "openjdk")

  # Not a build tool, or not one named alone
  expect_length(tools("GNU make, C++17, JavaScript, libcmakefoo")$build, 0)
  expect_length(tools(NA)$build, 0)
  expect_length(build_requirements(list(Package = "x"))$build, 0)

  # pixi-build-r adds Rust itself, but not before 2026-10-12
  rust <- "Cargo (Rust's package manager), rustc"
  expect_length(tools(rust)$build, 0)
  expect_equal(tools(rust, older_backend = TRUE)$build, "rust")
})

test_that("build_requirements() adds recommended packages for older pixi-build-r", {
  description <- list(
    Package = "x",
    Depends = "R (>= 4.1), Matrix (>= 1.6)",
    Imports = "stats, MASS,\n    cli",
    LinkingTo = "Rcpp",
    Suggests = "survival"
  )
  requirements <- build_requirements(description, older_backend = TRUE)
  expect_equal(requirements$host, c("r-matrix", "r-mass"))
  expect_equal(requirements$run, c("r-matrix", "r-mass"))
  expect_length(requirements$build, 0)

  # pixi-build-r adds them itself since 2026-10-12
  requirements <- build_requirements(description)
  expect_length(requirements$host, 0)
  expect_length(requirements$run, 0)
})

test_that("older_backend() says when a project's date may give older pixi-build-r", {
  newer <- numeric_version("0.82.0")
  expect_false(older_backend(NULL, newer))
  expect_false(older_backend("2026-10-13", newer))
  expect_false(older_backend("2026-11-01T12:00:00Z", newer))
  expect_true(older_backend("2026-10-12", newer))
  expect_true(older_backend("2025-06-01T12:00:00Z", newer))
  # A duration may reach back before then
  expect_true(older_backend("7d", newer))
})

test_that("older_backend() is TRUE for Pixi before 0.82, or an unknown one", {
  expect_true(older_backend(NULL, numeric_version("0.81.0")))
  expect_true(older_backend("2026-11-01", numeric_version("0.81.0")))
  expect_true(older_backend(NULL, NULL))
  expect_false(older_backend(NULL, numeric_version("0.83.0")))
})

test_that("description_packages() lists Depends, Imports and LinkingTo", {
  expect_equal(
    description_packages(list(
      Depends = "R (>= 4.1)",
      Imports = "cli (>= 3.0), rlang",
      LinkingTo = "Rcpp",
      Suggests = "testthat"
    )),
    c("R", "cli", "rlang", "Rcpp")
  )
  expect_equal(description_packages(list(Package = "x")), character())
})
