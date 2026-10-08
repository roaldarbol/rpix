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
  to them first with `pixi_add(feature = )`.

- solve_group:

  Optional. Environments in the same solve group get the same versions
  of the packages they share.

- default_feature:

  If `FALSE`, leave out the default feature. Needed when a feature
  conflicts with it, e.g. pins another version of R.

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
if (FALSE) { # \dontrun{
# An environment with R 4.4, next to the default one. It leaves out the
# default feature, since that has another version of R.
pixi_add(c("r-base=4.4", "dplyr"), feature = "r44")
pixi_add_environment("r44", features = "r44", default_feature = FALSE)

# An environment with the default packages plus testthat, on the same
# versions as the default environment
pixi_add("testthat", feature = "test")
pixi_add_environment("test", features = "test", solve_group = "default")
pixi_environments()
} # }
```
