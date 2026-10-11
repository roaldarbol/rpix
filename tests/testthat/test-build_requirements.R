test_that("build_requirements() finds build tools in SystemRequirements", {
  tools <- function(text) {
    build_requirements(list(Package = "x", SystemRequirements = text))
  }
  expect_equal(tools("Cargo (Rust's package manager), rustc")$build, "rust")
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
})

test_that("build_requirements() adds the recommended packages a package uses", {
  requirements <- build_requirements(list(
    Package = "x",
    Depends = "R (>= 4.1), Matrix (>= 1.6)",
    Imports = "stats, MASS,\n    cli",
    LinkingTo = "Rcpp",
    Suggests = "survival"
  ))
  expect_equal(requirements$host, c("r-matrix", "r-mass"))
  expect_equal(requirements$run, c("r-matrix", "r-mass"))
  expect_length(requirements$build, 0)
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
