# Changelog

## rpix (development version)

- New
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  reports on the project’s Pixi setup, with hints for what’s wrong
  ([\#28](https://github.com/roaldarbol/rpix/issues/28)): Pixi itself,
  whether the lock file is up to date, whether R is the project’s Pixi R
  and is activated, libraries and packages from outside the project, the
  `.Rprofile` block, and whether the IDE is set up.
- New
  [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md),
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  and
  [`pixi_tree()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  ([\#29](https://github.com/roaldarbol/rpix/issues/29)).
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  returns the packages in an environment as a data frame, including the
  name of each R package as R spells it (`Rcpp` for `r-rcpp`).
- New
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  replaces
  [`setup_pixi()`](https://roald-arboel.com/rpix/reference/rpix-deprecated.md),
  which is deprecated
  ([\#26](https://github.com/roaldarbol/rpix/issues/26)). Its new `ide`
  argument sets the project up for RStudio, Positron or VS Code, with
  the new
  [`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
  [`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  and
  [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  ([\#27](https://github.com/roaldarbol/rpix/issues/27)):
  - [`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    adds an `rstudio` task for each of the project’s platforms, so
    `pixi run rstudio` starts a new RStudio with the environment’s R, in
    the project.
  - [`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    turns on Positron’s discovery of R in Pixi environments. Positron
    then activates the environment itself when it starts that R.
  - [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    adds languageserver to the environment, and points the R extension
    for VS Code and VSCodium at the environment’s R.
- New
  [`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)
  activates the project’s Pixi environment in R that an IDE such as
  Positron or VS Code started directly, without Pixi
  ([\#25](https://github.com/roaldarbol/rpix/issues/25)). It sets the
  environment variables Pixi would set, and removes your personal
  library from [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds a block to the project’s `.Rprofile` that calls it, and removes
  the personal library before any package loads. Activation is fast,
  using Pixi’s activation cache.
- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  keeps your personal R library out of the environment’s R, by adding
  conda-forge’s `conda-ecosystem-user-package-isolation` to the project.
  conda-forge’s R otherwise puts the personal library first on
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html), so packages
  built for your usual R could be loaded
  (conda-forge/r-base-feedstock#37).
- The IDE guide’s RStudio commands now work as expected: `open -n` on
  macOS, so a running RStudio doesn’t keep its R, and a task that sets
  `RSTUDIO_WHICH_R` on Windows
  ([\#24](https://github.com/roaldarbol/rpix/issues/24)). It also
  explains that on Windows, Positron and VS Code have to be started
  through Pixi.

## rpix 0.4.0

### Breaking changes

- Exported functions now follow one naming scheme
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)): functions that
  run a Pixi command are called `pixi_<command>()`.
  - [`add()`](https://roald-arboel.com/rpix/reference/rpix-deprecated.md)
    is now
    [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).
    [`add()`](https://roald-arboel.com/rpix/reference/rpix-deprecated.md)
    still works for now, with a deprecation warning.
  - [`remove()`](https://rdrr.io/r/base/rm.html) and
    [`search()`](https://rdrr.io/r/base/search.html) are now
    [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
    and
    [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md).
    The old names were removed rather than deprecated, because they
    masked [`base::remove()`](https://rdrr.io/r/base/rm.html) and
    [`base::search()`](https://rdrr.io/r/base/search.html) whenever rpix
    was attached.
  - `pixi_to_path()` is removed. rpix finds Pixi itself.
- rpix no longer points a running R at a Pixi environment’s library
  ([\#22](https://github.com/roaldarbol/rpix/issues/22)). R mixed with
  packages built for a different R could crash
  ([\#14](https://github.com/roaldarbol/rpix/issues/14)). Work in R
  started by Pixi instead, e.g. with `pixi run R`.
  - [`setup_pixi()`](https://roald-arboel.com/rpix/reference/rpix-deprecated.md)
    now only sets up the project: it creates `pixi.toml` if needed, adds
    R (`r_version` picks the version), and installs rpix into the
    environment, with its dependencies from conda-forge. Its
    `add_to_rprofile` and `global` arguments are gone.
  - [`setup_pixi()`](https://roald-arboel.com/rpix/reference/rpix-deprecated.md)
    removes the “Pixi R library setup” block that earlier versions added
    to the project’s `.Rprofile`, and warns if there’s one in
    `~/.Rprofile`.
  - `reset_r_libraries()` is removed.

### Other changes

- All Pixi commands now go through a single internal runner built on
  *processx* ([\#19](https://github.com/roaldarbol/rpix/issues/19)).
  Arguments are passed without shell quoting, commands work from any
  subfolder of a project (`--manifest-path`), Pixi failures become R
  errors, and Pixi is found even if it isn’t on the `PATH` (set
  `options(rpix.pixi_path = ...)` for unusual installs).
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  with `dry_run = TRUE` now return the command invisibly.
- R package names are now translated to conda names properly
  ([\#21](https://github.com/roaldarbol/rpix/issues/21)): names are
  lowercased (`"Rcpp"` becomes `r-rcpp`), and a pak-like prefix says
  where a package comes from: `"bioc::DESeq2"` for Bioconductor packages
  from bioconda ([\#17](https://github.com/roaldarbol/rpix/issues/17)),
  and `"conda::gdal"` for conda packages that aren’t R packages. Names
  with `-` or `_` are used as is.
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  accepts version constraints inline (`"dplyr>=1.1"`) and one constraint
  per package in `versions`.
- `pixi_add(channel = )` works again: Pixi has no `--channel` flag for
  `pixi add`, so the channel is now added to the project and used in the
  package spec. The same happens automatically for bioconda.
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  suggests `bioc::` and `conda::` when a package can’t be found.
- The documentation is restructured
  ([\#48](https://github.com/roaldarbol/rpix/issues/48)): a walk-through
  in Get started, guides to finding packages, coming from renv, sharing
  projects and using an IDE, and pages on how rpix works and
  troubleshooting.
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
