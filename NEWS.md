# rpix (development version)

## Breaking changes
- Exported functions now follow one naming scheme (#20): functions that run a pixi command are called `pixi_<command>()`.
  - `add()` is now `pixi_add()`. `add()` still works for now, with a deprecation warning.
  - `remove()` and `search()` are now `pixi_remove()` and `pixi_search()`. The old names were removed rather than deprecated, because they masked `base::remove()` and `base::search()` whenever rpix was attached.
  - `pixi_to_path()` is no longer exported. rpix finds pixi itself.

## Other changes
- All pixi commands now go through a single internal runner built on *processx* (#19). Arguments are passed without shell quoting, commands work from any subfolder of a project (`--manifest-path`), pixi failures become R errors, and pixi is found even if it isn't on the `PATH` (set `options(rpix.pixi_path = ...)` for unusual installs).
- `pixi_add()`, `pixi_remove()` and `pixi_search()` with `dry_run = TRUE` now return the command invisibly.
- R package names are now translated to conda names properly (#21): names are lowercased (`"Rcpp"` becomes `r-rcpp`), and a pak-like prefix says where a package comes from: `"bioc::DESeq2"` for Bioconductor packages from bioconda (#17), and `"conda::gdal"` for conda packages that aren't R packages. Names with `-` or `_` are used as is.
- `pixi_add()` accepts version constraints inline (`"dplyr>=1.1"`) and one constraint per package in `versions`.
- `pixi_add(channel = )` works again: pixi has no `--channel` flag for `pixi add`, so the channel is now added to the project and used in the package spec. The same happens automatically for bioconda.
- `pixi_add()` suggests `bioc::` and `conda::` when a package can't be found.
- Added tests.

# rpix 0.3.0
- `restart_rstudio_with_pixi` has been written to facilitate easier selection of the correct R version
- `setup_pixi` now installs *rpix* from CRAN into the pixi library. It's a hacky solution until it's on conda.

# rpix 0.2.0
- `add` can now add multiple packages simultaneously
- `dry_run` parameter added to multiple functions to allow inspections of pixi commands
- `setup_pixi` command to setup a pixi project from within R. Still very alpha, expect to break.
- `search` allows to search dependencies, their versions and their own dependencies.

# rpix 0.1.0


