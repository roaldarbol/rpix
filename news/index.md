# Changelog

## rpix (development version)

- All pixi commands now go through a single internal runner built on
  *processx* ([\#19](https://github.com/roaldarbol/rpix/issues/19)).
  Arguments are passed without shell quoting, commands work from any
  subfolder of a project (`--manifest-path`), pixi failures become R
  errors, and pixi is found even if it isn’t on the `PATH` (set
  `options(rpix.pixi_path = ...)` for unusual installs).
- [`add()`](https://roald-arboel.com/rpix/reference/add.md),
  [`remove()`](https://roald-arboel.com/rpix/reference/remove.md) and
  [`search()`](https://roald-arboel.com/rpix/reference/search.md) with
  `dry_run = TRUE` now return the command invisibly.
- R package names are now translated to conda names properly
  ([\#21](https://github.com/roaldarbol/rpix/issues/21)): names are
  lowercased (`"Rcpp"` becomes `r-rcpp`), and a pak-like prefix says
  where a package comes from: `"bioc::DESeq2"` for Bioconductor packages
  from bioconda ([\#17](https://github.com/roaldarbol/rpix/issues/17)),
  and `"conda::gdal"` for conda packages that aren’t R packages. Names
  with `-` or `_` are used as is.
- [`add()`](https://roald-arboel.com/rpix/reference/add.md) accepts
  version constraints inline (`"dplyr>=1.1"`) and one constraint per
  package in `versions`.
- `add(channel = )` works again: pixi has no `--channel` flag for `add`,
  so the channel is now added to the project and used in the package
  spec. The same happens automatically for bioconda.
- [`add()`](https://roald-arboel.com/rpix/reference/add.md) suggests
  `bioc::` and `conda::` when a package can’t be found.
- Added tests.

## rpix 0.3.0

- `restart_rstudio_with_pixi` has been written to facilitate easier
  selection of the correct R version
- `setup_pixi` now installs *rpix* from CRAN into the pixi library. It’s
  a hacky solution until it’s on conda.

## rpix 0.2.0

- `add` can now add multiple packages simultaneously
- `dry_run` parameter added to multiple functions to allow inspections
  of pixi commands
- `setup_pixi` command to setup a pixi project from within R. Still very
  alpha, expect to break.
- `search` allows to search dependencies, their versions and their own
  dependencies.

## rpix 0.1.0
