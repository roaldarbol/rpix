# Test a package in several environments

For package developers: run the tests or `R CMD check` in several of the
project's environments, e.g. one for each version of R, and see the
results side by side.

- `pixi_check_matrix()` runs them. Each environment needs the package's
  dependencies, and testthat and pkgload for the tests, or rcmdcheck for
  `R CMD check`.

- `use_pixi_check_matrix()` adds an environment for each version of R,
  with those packages, named after the version: `r44` for R 4.4.

## Usage

``` r
pixi_check_matrix(
  environments = NULL,
  what = c("test", "check"),
  task = NULL,
  parallel = FALSE,
  path = NULL
)

use_pixi_check_matrix(r_versions, path = NULL)
```

## Arguments

- environments:

  Optional. The environments. Defaults to all of them.

- what:

  `"test"` to run the tests with
  [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html),
  or `"check"` to run `R CMD check` with
  [`rcmdcheck::rcmdcheck()`](http://r-lib.github.io/rcmdcheck/reference/rcmdcheck.md).

- task:

  Optional. A Pixi task to run instead, such as `"check"`. It passes if
  it succeeds.

- parallel:

  If `TRUE`, run in all environments at once.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- r_versions:

  Versions of R, such as `"4.4"`.

## Value

- `pixi_check_matrix()`: a data frame with a row per environment, and
  the columns `environment`, `r_version`, `ok`, the counts (`passed`,
  `failed`, `skipped` and `warnings` for tests; `errors`, `warnings` and
  `notes` for `R CMD check`), `seconds`, and `output`: what it printed.

- `use_pixi_check_matrix()`: the names of the environments, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_check_matrix(c("4.3", "4.4", "4.5"))
pixi_check_matrix()
pixi_check_matrix(what = "check", parallel = TRUE)
} # }
```
