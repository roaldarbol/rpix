# rpix (development version)
- All pixi commands now go through a single internal runner built on *processx* (#19). Arguments are passed without shell quoting, commands work from any subfolder of a project (`--manifest-path`), pixi failures become R errors, and pixi is found even if it isn't on the `PATH` (set `options(rpix.pixi_path = ...)` for unusual installs).
- `add()`, `remove()` and `search()` with `dry_run = TRUE` now return the command invisibly.
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


