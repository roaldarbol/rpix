# Deprecated functions

- `add()` is now
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

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
