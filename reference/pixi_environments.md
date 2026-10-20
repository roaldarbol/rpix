# Features and environments

A Pixi project can have several environments, each with its own R and
packages: say one with R 4.4 and one with R 4.5, or one with the
packages your tests need on top of the project's own.

Environments are made of *features*: named sets of packages. The default
feature holds what
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
adds, and is in every environment unless it's left out. Add packages to
another feature with `pixi_add(feature = )`; that also creates the
feature. Then make an environment of it with `pixi_add_environment()`,
and start its R with `pixi run --environment <name> R`.

- `pixi_environments()` lists the project's environments.

- `pixi_add_environment()` adds an environment, made of features.

- `pixi_remove_environment()` removes one.

For more information, see
<https://pixi.prefix.dev/latest/workspace/multi_environment/>.

## Usage

``` r
pixi_environments(path = NULL)

pixi_add_environment(
  name,
  features = NULL,
  r_version = NULL,
  solve_group = NULL,
  default_feature = TRUE,
  overwrite = FALSE,
  path = NULL,
  dry_run = FALSE
)

pixi_remove_environment(name, path = NULL, dry_run = FALSE)
```

## Arguments

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- name:

  The environment's name.

- features:

  The features it's made of. They have to exist already, so add packages
  to them first with `pixi_add(feature = )`. Without any, the
  environment is a copy of the default one.

- r_version:

  Optional. Another version of R for the environment, such as `"4.4"`,
  in one step: a feature named after the environment gets that R, the
  default feature's packages (by name, so it gets the versions built for
  that R) and `conda-ecosystem-user-package-isolation`. The environment
  leaves out the default feature, which has the project's R, and is
  installed, with rpix in it if the project has rpix. Packages built
  from source aren't copied; rpix says how to add them. If that R can't
  have the project's packages, `pixi.toml` and `pixi.lock` are left as
  they were.

- solve_group:

  Optional. Environments in the same solve group get the same versions
  of the packages they share.

- default_feature:

  If `FALSE`, leave out the default feature. Needed when a feature
  conflicts with it, e.g. pins another version of R. If the environment
  has R, rpix then adds `conda-ecosystem-user-package-isolation` to its
  first feature, as
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  does to the default one, to keep your personal R library out.

- overwrite:

  If `TRUE`, replace an environment that already exists.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

## Value

- `pixi_environments()`: a data frame with a row per environment, and
  the columns `name`, `features` and `platforms` (lists of character
  vectors) and `solve_group`.

- The others: the command (invisibly) if `dry_run = TRUE`, otherwise the
  result of the Pixi call (invisibly).

## Examples

``` r
# A throwaway Pixi project in R's temporary folder, so the examples leave
# yours alone. With `dry_run = TRUE`, rpix shows the Pixi command it would run.
project <- file.path(tempdir(), "rpix-example")
dir.create(project, showWarnings = FALSE)
writeLines(
  c(
    "[workspace]",
    'name = "rpix-example"',
    'channels = ["conda-forge"]',
    'platforms = ["linux-64", "osx-arm64", "win-64"]',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'conda-ecosystem-user-package-isolation = "*"'
  ),
  file.path(project, "pixi.toml")
)

# An environment with R 4.4 and the project's packages, next to the
# default one
pixi_add_environment("r44", r_version = "4.4", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi add --feature r44 --no-install r-base=4.4 conda-ecosystem-user-package-isolation --manifest-path /tmp/RtmpJzlolV/rpix-example/pixi.toml`
#> ℹ Would run: `pixi workspace environment add r44 --feature r44 --no-default-feature --manifest-path /tmp/RtmpJzlolV/rpix-example/pixi.toml`
#> ℹ Would run: `pixi upgrade --feature r44 --exclude r-base --no-install --manifest-path /tmp/RtmpJzlolV/rpix-example/pixi.toml`

# An environment with the default packages plus testthat, on the same
# versions as the default environment
pixi_add("testthat", feature = "test", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi add r-testthat --feature test --manifest-path /tmp/RtmpJzlolV/rpix-example/pixi.toml`
pixi_add_environment(
  "test",
  features = "test",
  solve_group = "default",
  path = project,
  dry_run = TRUE
)
#> ℹ Would run: `pixi workspace environment add test --feature test --solve-group default --manifest-path /tmp/RtmpJzlolV/rpix-example/pixi.toml`

if (FALSE) { # \dontrun{
# Needs Pixi
pixi_environments()
} # }
```
