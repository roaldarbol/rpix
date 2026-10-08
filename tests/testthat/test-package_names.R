test_that("CRAN packages get a lowercase r- prefix", {
  parsed <- parse_packages(c("dplyr", "Rcpp", "data.table", "cran::R6"))
  expect_equal(parsed$name, c("r-dplyr", "r-rcpp", "r-data.table", "r-r6"))
  expect_equal(parsed$source, rep("cran", 4))
  expect_true(all(is.na(parsed$channel)))
})

test_that("Bioconductor packages come from bioconda", {
  parsed <- parse_packages("bioc::DESeq2")
  expect_equal(parsed$name, "bioconductor-deseq2")
  expect_equal(parsed$channel, "bioconda")
  expect_equal(package_specs(parsed), "bioconda::bioconductor-deseq2")
})

test_that("conda packages are passed through", {
  parsed <- parse_packages(c(
    "conda::gdal",
    "r-dplyr",
    "c-compiler",
    "libgdal_core",
    "conda::Quarto"
  ))
  expect_equal(
    parsed$name,
    c("gdal", "r-dplyr", "c-compiler", "libgdal_core", "Quarto")
  )
  expect_equal(parsed$source, rep("conda", 5))
})

test_that("inline version constraints are kept", {
  parsed <- parse_packages(c(
    "dplyr>=1.1",
    "Rcpp ==1.0.12",
    "bioc::limma<4",
    "conda::gdal=3.9"
  ))
  expect_equal(
    parsed$name,
    c("r-dplyr", "r-rcpp", "bioconductor-limma", "gdal")
  )
  expect_equal(parsed$constraint, c(">=1.1", "==1.0.12", "<4", "=3.9"))
  expect_equal(
    package_specs(parsed),
    c(
      "r-dplyr>=1.1",
      "r-rcpp==1.0.12",
      "bioconda::bioconductor-limma<4",
      "gdal=3.9"
    )
  )
})

test_that("prefixes are case-insensitive", {
  expect_equal(parse_packages("BIOC::limma")$name, "bioconductor-limma")
})

test_that("invalid input is an error", {
  expect_error(parse_packages(character()), "character vector")
  expect_error(parse_packages(NA_character_), "character vector")
  expect_error(parse_packages("github::r-lib/cli"), "Unknown source")
  expect_error(parse_packages("2fast"), "valid R package name")
  expect_error(parse_packages("bioc::my-pkg"), "valid R package name")
})

test_that("versions without an operator get =", {
  expect_equal(
    normalise_versions(c("1.1", ">=2", "==1.0.0", NA, "", " 3 ")),
    c("=1.1", ">=2", "==1.0.0", "", "", "=3")
  )
})
