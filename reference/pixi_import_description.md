# Add a package's dependencies from its DESCRIPTION

For package developers: add what the package in the project needs to the
project, from its `DESCRIPTION`.

- `Depends` and `Imports` (and `LinkingTo`) go into the default feature,
  with their version constraints.

- `Suggests` go into a `test` feature, with a `test` environment of the
  default and `test` features. It's in the same solve group as the
  default environment, so it tests the same versions.

- `Depends: R (>= 4.1)` becomes a constraint on R, if the project
  doesn't have R yet.

Each package is looked up on conda-forge, as `r-<name>`, and then on
bioconda, as `bioconductor-<name>`. Packages that are on neither are
left out, and listed.

## Usage

``` r
pixi_import_description(test = TRUE, path = NULL, dry_run = FALSE)
```

## Arguments

- test:

  If `TRUE`, add the `Suggests` to a `test` feature and environment. If
  `FALSE`, leave them out.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

## Value

A list with the package specs added to the default feature (`packages`)
and to the `test` feature (`test`), and the packages that weren't found
(`missing`), invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_import_description()
} # }
```
