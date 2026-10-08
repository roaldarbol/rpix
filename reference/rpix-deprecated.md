# Deprecated functions

- `add()` is now
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

- `setup_pixi()` is now
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md).

[`remove()`](https://rdrr.io/r/base/rm.html) and
[`search()`](https://rdrr.io/r/base/search.html) were removed rather
than deprecated, because they masked the base R functions of the same
name. Use
[`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
and
[`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md).

## Usage

``` r
add(packages, versions = NULL, channel = NULL, dry_run = FALSE)

setup_pixi(r_version = NULL, init_if_missing = TRUE, install_rpix = TRUE)
```

## Arguments

- packages:

  Package names. A version constraint can follow the name, as in
  `"dplyr>=1.1"`.

- versions:

  Optional. Version constraints, either one for all packages or one per
  package (use `NA` for no constraint). A version without an operator,
  such as `"1.1"`, means `1.1.*`.

- channel:

  Optional. A conda channel to install the packages from. It's added to
  the project's channels if it isn't there yet.

- dry_run:

  If `TRUE`, show the Pixi commands without running them.

- r_version:

  Optional. The R version to add, such as `"4.5"`. Defaults to the
  newest one that the packages
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds are built for on conda-forge.

- init_if_missing:

  If `TRUE`, create a Pixi project if there isn't one.

- install_rpix:

  If `TRUE`, install rpix into the project's environment. Its
  dependencies come from conda-forge, and rpix itself from R-universe
  until it's on conda-forge.
