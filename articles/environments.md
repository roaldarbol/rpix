# Several environments

A Pixi project can have several environments, each with its own R and
packages. For example:

- An environment with an older R, to check your code still runs there.
- An environment with extra packages for tests or documentation, which
  the project itself doesn’t need.

## Features and environments

Environments are made of *features*: named sets of packages. The default
feature holds what
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
adds, and every environment includes it, unless you leave it out.

To make an environment, add packages to a feature, which creates it,
then make an environment of that feature:

``` r

library(rpix)

pixi_add("testthat", feature = "test")
pixi_add_environment("test", features = "test")
```

The feature has to exist before an environment can use it, so add its
packages first.

## Another version of R

An environment with R 4.4, next to the default one with the latest R:

``` r

pixi_add(c("r-base=4.4", "dplyr"), feature = "r44")
pixi_add_environment("r44", features = "r44", default_feature = FALSE)
```

`default_feature = FALSE` leaves out the default feature. Here that’s
needed: the default feature has its own version of R, and an environment
can’t have two.

## Keeping environments in step

Environments in the same *solve group* get the same versions of the
packages they share. That suits a test environment, which should test
the versions the project uses:

``` r

pixi_add_environment("test", features = "test", solve_group = "default", overwrite = TRUE)
```

Environments with different versions of R can’t share a solve group.

## Using an environment

Start an environment’s R with:

``` sh
pixi run --environment r44 R
```

Or run a function in it from the R you’re in, and get the result back:

``` r

pixi_r(function() R.version.string, environment = "r44")
#> [1] "R version 4.4.3 (2025-02-28)"
```

The function runs in a new R, so it doesn’t see your variables: pass
what it needs as arguments, with `args = list(...)`.

In Positron, each environment shows up as its own R in the interpreter
picker, e.g. “R 4.4.3 (Pixi: r44)”.

See the project’s environments, and their features, with:

``` r

pixi_environments()
```

## Checking a package on several versions of R

For package developers,
[`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
adds an environment for each version of R, with the package’s
dependencies and what the tests and `R CMD check` need:

``` r

use_pixi_check_matrix(c("4.3", "4.4", "4.5"))
```

Then run the tests in all of them, and see the results side by side:

``` r

pixi_check_matrix()
#> ── Tests ──────────────────────────────────────────────────────────
#> ✔ r43  R 4.3.3: 120 passed, 0 failed, 2 skipped, 0 warnings (41 s)
#> ✖ r44  R 4.4.3: 119 passed, 1 failed, 2 skipped, 0 warnings (38 s)
#> ✔ r45  R 4.5.3: 120 passed, 0 failed, 2 skipped, 0 warnings (37 s)
```

`what = "check"` runs `R CMD check` instead, and `parallel = TRUE` runs
in all environments at once. What each run printed is in the `output`
column.

Install an environment with `pixi_install(environment = "r44")`, or all
of them with `pixi_install(all = TRUE)`. `pixi run` also installs an
environment the first time it’s used.
