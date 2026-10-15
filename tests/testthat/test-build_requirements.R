test_that("build_requirements() adds Java, for the build and the run", {
  tools <- function(text) {
    build_requirements(list(SystemRequirements = text))
  }
  expect_equal(
    tools("Java (>= 8)"),
    list(build = "openjdk", host = character(), run = "openjdk")
  )
  expect_equal(tools("JDK 11 or later")$build, "openjdk")
  expect_equal(tools("a JRE")$run, "openjdk")
  # Not part of another word
  expect_equal(tools("javascript")$build, character())

  # pixi-build-r adds these itself
  expect_equal(
    tools("Cargo (Rust's package manager), rustc")$build,
    character()
  )
  expect_equal(tools("cmake, pkg-config")$build, character())
  expect_equal(
    build_requirements(list(Imports = "MASS, Matrix")),
    list(build = character(), host = character(), run = character())
  )
})

test_that("date_hides_backend() is TRUE for a date before pixi-build-r 0.2.0", {
  expect_false(date_hides_backend(NULL))
  expect_false(date_hides_backend("2026-10-15"))
  expect_false(date_hides_backend("2026-11-01T12:00:00Z"))
  expect_true(date_hides_backend("2026-10-14"))
  expect_true(date_hides_backend("2025-06-01T12:00:00Z"))
  # rpix can't tell for a duration
  expect_false(date_hides_backend("7d"))
})
