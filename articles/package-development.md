# Developing a package

A package developed in a Pixi project has its R, its dependencies and
its development tools in `pixi.lock`: the same on every contributor’s
computer, and in CI. This guide goes through the workflow. [Several
environments](https://roald-arboel.com/rpix/articles/environments.md)
has more on checking across versions of R.

## Setting up

In the package’s folder, set up Pixi, then add what `DESCRIPTION` asks
for:

``` r

rpix::use_pixi(ide = "positron")   # or "rstudio", or "vscode"
rpix::pixi_import_description()
```

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds Pixi’s files (`.pixi`, `pixi.toml` and `pixi.lock`) to
  `.Rbuildignore`, and setting up an IDE adds `.vscode`, so they stay
  out of the package’s builds.
- [`pixi_import_description()`](https://roald-arboel.com/rpix/reference/pixi_import_description.md)
  adds `Depends`, `Imports` and `LinkingTo` to the project, and
  `Suggests` to a `test` environment, which uses the same versions as
  the default one. Packages that aren’t on conda-forge or bioconda are
  listed and left out: add them with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  which offers to build them from source (see [Finding
  packages](https://roald-arboel.com/rpix/articles/finding-packages.md)).

Then add the development tools, to a `dev` feature that the default
environment includes, so they’re there when you work but stay apart from
what the package needs:

``` r

pixi_add(c("devtools", "roxygen2", "testthat"), feature = "dev")
pixi_add_environment("default", features = "dev", overwrite = TRUE)
```

## The daily loop

Work in the environment’s R, as your IDE starts it once
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md) has
set it up, or with `pixi run R`. devtools works as usual there:

``` r

devtools::load_all()
devtools::document()
devtools::test()
devtools::check()
```

Install packages with
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md), not
with
[`devtools::install_dev_deps()`](https://devtools.r-lib.org/reference/install_deps.html),
`pak` or `remotes`: those install into the environment without recording
it in `pixi.toml`, so a collaborator doesn’t get them, and Pixi may
remove them the next time it installs the environment. In the
environment’s R,
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
goes through rpix.

Pixi tasks make the common commands one word, in a terminal and in CI:

``` r

pixi_add_task("test", "Rscript -e 'devtools::test()'", description = "Run the tests")
pixi_add_task("check", "Rscript -e 'devtools::check()'", description = "Run R CMD check")
```

Then `pixi run test`, or
[`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
to list them.

## Keeping DESCRIPTION and pixi.toml in step

`DESCRIPTION` and `pixi.toml` drift apart easily:
[`usethis::use_package()`](https://usethis.r-lib.org/reference/use_package.html)
only changes `DESCRIPTION`, and
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) only
`pixi.toml`.
[`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
compares them, in a “Package” section:

``` r

pixi_sitrep()
#> ── Package ──
#> ! 'DESCRIPTION' needs rlang, which isn't in the default environment in 'pixi.toml'.
#>   Add them with `pixi_import_description()`.
```

It also says when an installed package is older than `DESCRIPTION` asks
for. Run
[`pixi_import_description()`](https://roald-arboel.com/rpix/reference/pixi_import_description.md)
again to add what’s missing.

## Compiled code

conda-forge’s R comes with its C, C++ and Fortran compilers, and on
Linux and macOS with `make`, so packages with compiled code build
without Rtools or a separately installed compiler.

- **Windows:** R’s build tools also need MSYS2’s `make`, `sed` and
  `coreutils`, which conda-forge’s R doesn’t bring there. Without them,
  devtools asks for Rtools. Add them for Windows only:

  ``` r

  pixi_add(c("conda::m2-make", "conda::m2-sed", "conda::m2-coreutils"), feature = "dev", platform = "win-64")
  ```

- **macOS:** the compilers use Apple’s SDK, from Xcode’s Command Line
  Tools. If a build can’t find system headers such as `stdio.h`, install
  them with `xcode-select --install` in a terminal.

- **Rust:** add conda-forge’s `rust`, and on Windows also its GNU
  target: `pixi_add("conda::rust", feature = "dev")`, and
  `pixi_add("conda::rust-std-x86_64-pc-windows-gnu", feature = "dev", platform = "win-64")`.

## Checking across versions

- **Several versions of R:**
  `use_pixi_check_matrix(c("4.3", "4.4", "4.5"))` adds an environment
  for each, and
  [`pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
  runs the tests in all of them.
- **The minimum versions in `DESCRIPTION`:**
  `use_pixi_check_matrix(minimum = TRUE)` adds an environment with R and
  each dependency at the lowest version `DESCRIPTION` allows.
- **Packages as of a date:**
  [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)
  uses packages as they were on a date, e.g. to see whether a bug came
  with a dependency’s release.

See [Several
environments](https://roald-arboel.com/rpix/articles/environments.md)
for each of these.

## Continuous integration

[`use_pixi_github_action()`](https://roald-arboel.com/rpix/reference/use_pixi_github_action.md)
writes a GitHub Actions workflow that installs the environments from
`pixi.lock`, so CI runs with exactly what you ran:

``` r

use_pixi_check_matrix(c("4.4", "4.5"))
use_pixi_github_action("check", environments = c("r44", "r45"))
```

`"check"` runs `R CMD check` on Linux, macOS and Windows (those of the
project’s platforms), in each environment. Use environments that have
`rcmdcheck` and the package’s `Suggests`, as the check matrix’s `r44`
and `r45` do: the default environment has neither. `"test-coverage"` and
`"pkgdown"` write the other two workflows a package usually has. Commit
`pixi.lock`: the run fails when it’s out of date with `pixi.toml`.

## What Pixi doesn’t cover

- **R-devel** isn’t on conda-forge, so checking against it, as CRAN
  does, still needs r-lib’s [actions](https://github.com/r-lib/actions)
  with an R from outside Pixi.
- **CRAN’s own checks** (`--as-cran`, win-builder, R-hub) run outside
  your environment, as they always have.
