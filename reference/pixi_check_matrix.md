# Test a package in several environments

For package developers: run the tests or `R CMD check` in several of the
project's environments, e.g. one for each version of R, and see the
results side by side.

- `pixi_check_matrix()` runs them. Each environment needs the package's
  dependencies, and testthat and pkgload for the tests, or rcmdcheck for
  `R CMD check`.

- `use_pixi_check_matrix()` adds an environment for each version of R,
  with those packages, named after the version: `r44` for R 4.4. With
  `minimum = TRUE`, it also adds a `minimum` environment, with the
  oldest versions the package's `DESCRIPTION` allows.

## Usage

``` r
pixi_check_matrix(
  environments = NULL,
  what = c("test", "check"),
  task = NULL,
  parallel = FALSE,
  path = NULL
)

use_pixi_check_matrix(r_versions = NULL, minimum = FALSE, path = NULL)
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

  Versions of R, such as `"4.4"`. Optional with `minimum = TRUE`.

- minimum:

  If `TRUE`, also add a `minimum` environment; see below.

## Value

- `pixi_check_matrix()`: a data frame with a row per environment, and
  the columns `environment`, `r_version`, `ok`, the counts (`passed`,
  `failed`, `skipped` and `warnings` for tests; `errors`, `warnings` and
  `notes` for `R CMD check`), `seconds`, and `output`: what it printed.

- `use_pixi_check_matrix()`: the names of the environments, invisibly.

## The `minimum` environment

Checks that the minimum versions in `DESCRIPTION` really work: R at the
version `Depends` asks for, and each package in `Depends`, `Imports` and
`LinkingTo` at the lowest version its constraint allows (Pixi's
`solve-strategy = "lowest-direct"`; their own dependencies are the
newest that fit). testthat, pkgload and rcmdcheck, which run the checks,
aren't the packages under test, so they're kept at recent minimums.

- A package without a minimum gets the oldest version on conda-forge for
  that R, which may be much older than you meant; rpix lists them.

- Without a minimum R in `Depends`, it uses the oldest of `r_versions`,
  or the project's R.

- Only versions on conda-forge (and bioconda) count, for the project's
  platforms. An old build's own dependencies are as conda-forge recorded
  them, which for old builds is sometimes looser than its `DESCRIPTION`:
  then R refuses to load it, although Pixi installed it.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_check_matrix(c("4.3", "4.4", "4.5"))
use_pixi_check_matrix(minimum = TRUE)
pixi_check_matrix()
pixi_check_matrix(what = "check", parallel = TRUE)
} # }
```
