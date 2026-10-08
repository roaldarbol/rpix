# Changelog

## rpix (development version)

### Breaking changes

- The deprecated `add()` and `setup_pixi()` are removed. Use
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md).

## rpix 0.6.0

rpix now works with several environments, e.g. one for each version of
R, moves projects from renv, and keeps
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
from installing packages Pixi doesn’t know about.

### Breaking changes

- `restart_rstudio_with_pixi()` is removed. Use
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  instead, or start RStudio with `pixi run rstudio`
  ([\#32](https://github.com/roaldarbol/rpix/issues/32)).

### Several environments

- New
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  moves your work to another environment’s R
  ([\#32](https://github.com/roaldarbol/rpix/issues/32)). In RStudio it
  starts a new RStudio with that R. In Positron it looks for
  interpreters again, so new environments are listed, and opens the
  interpreter picker. In VS Code it points the R extension at that R.
- New [`pixi_r()`](https://roald-arboel.com/rpix/reference/pixi_r.md)
  runs a function in another environment’s R, e.g. one with another
  version of R, and returns its result
  ([\#33](https://github.com/roaldarbol/rpix/issues/33)).
- New
  [`pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
  runs a package’s tests or `R CMD check` in several environments, one
  at a time or all at once, and shows the results side by side.
  [`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
  adds an environment for each version of R you want to check
  ([\#34](https://github.com/roaldarbol/rpix/issues/34)).

### Moving to Pixi

- New
  [`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
  moves a project from renv: it adds the packages in `renv.lock`, at
  least at their locked versions or exactly, and turns renv off. It adds
  only the packages nothing else in the lock file needs, and lists those
  it can’t add, e.g. from GitHub
  ([\#37](https://github.com/roaldarbol/rpix/issues/37)).
- New
  [`pixi_import_description()`](https://roald-arboel.com/rpix/reference/pixi_import_description.md)
  adds a package’s dependencies from its `DESCRIPTION`: `Depends` and
  `Imports` to the project, and `Suggests` to a `test` environment. It
  finds Bioconductor packages on bioconda, and lists the packages that
  aren’t on conda-forge or bioconda
  ([\#36](https://github.com/roaldarbol/rpix/issues/36)).
- New
  [`pixi_scan()`](https://roald-arboel.com/rpix/reference/pixi_scan.md)
  finds the packages the project’s code uses, in `.R` files, the R
  chunks of `.qmd` and `.Rmd` documents, and Pixi tasks. It lists those
  missing from `pixi.toml`, adds them with `add = TRUE`, and lists
  packages the code never uses
  ([\#38](https://github.com/roaldarbol/rpix/issues/38)).

### Installing packages

- In a Pixi environment’s R,
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  adds packages with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  so they’re recorded in `pixi.toml` and `pixi.lock`
  ([\#3](https://github.com/roaldarbol/rpix/issues/3)). Packages that
  aren’t on conda-forge or bioconda, and arguments Pixi can’t use, such
  as `lib`, give an error that points to
  [`utils::install.packages()`](https://rdrr.io/r/utils/install.packages.html).
  [`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)
  sets this up; turn it off with
  `options(rpix.install_packages = FALSE)`.
- [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  lists packages in the environment that Pixi didn’t install, so
  `pixi.toml` doesn’t record them
  ([\#3](https://github.com/roaldarbol/rpix/issues/3)).
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  explains when a package isn’t built for the project’s version of R
  yet, which happens for a while after conda-forge releases a new R, and
  suggests the newest R it’s built for
  ([\#80](https://github.com/roaldarbol/rpix/issues/80)).
- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds R together with the packages it needs, so Pixi picks the newest R
  they’re built for. Just after conda-forge released a new R, it picked
  that R, and adding packages failed until they were rebuilt for it
  ([\#72](https://github.com/roaldarbol/rpix/issues/72)).

### Tasks

- New
  [`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_run()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_add_task()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
  and
  [`pixi_remove_task()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
  work with the project’s Pixi tasks
  ([\#35](https://github.com/roaldarbol/rpix/issues/35)).

### Other changes

- [`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_environments()`](https://roald-arboel.com/rpix/reference/pixi_environments.md),
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  and
  [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  print their results in a readable form
  ([\#67](https://github.com/roaldarbol/rpix/issues/67)). They’re still
  data frames, or a list for
  [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md).
- Pixi’s output is no longer partly red. Pixi reports progress on
  stderr, which was shown in red; rpix now shows it in Pixi’s own
  colours.
- [`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  replaces the `rstudio` task if it’s there, so it can be run again,
  e.g. after renaming the `.Rproj` file
  ([\#72](https://github.com/roaldarbol/rpix/issues/72)).

## rpix 0.5.0

rpix now sets projects up for RStudio, Positron and VS Code, and makes
sure R only uses the project’s packages.

### Setting up a project

- New
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  replaces `setup_pixi()`, which is deprecated
  ([\#26](https://github.com/roaldarbol/rpix/issues/26)). Its `ide`
  argument sets the project up for an IDE, with the new
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
  activates the project’s Pixi environment in R that an IDE started
  directly, without Pixi
  ([\#25](https://github.com/roaldarbol/rpix/issues/25)). It sets the
  environment variables Pixi would set, and removes your personal
  library from [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds a block to the project’s `.Rprofile` that calls it, and removes
  the personal library before any package loads.
- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  keeps your personal R library out of the environment’s R, by adding
  conda-forge’s `conda-ecosystem-user-package-isolation` to the project.
  conda-forge’s R otherwise puts the personal library first on
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html), so packages
  built for your usual R could be loaded, and crash it
  (conda-forge/r-base-feedstock#37).

### Environments

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  gain `feature` and `platform` arguments, and new
  [`pixi_environments()`](https://roald-arboel.com/rpix/reference/pixi_environments.md),
  [`pixi_add_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md)
  and
  [`pixi_remove_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md)
  manage a project’s environments, e.g. one with another version of R
  ([\#30](https://github.com/roaldarbol/rpix/issues/30)).
- New
  [`pixi_add_channel()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md)
  and
  [`pixi_add_platform()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md),
  and
  [`pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md),
  [`pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md),
  [`pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  and
  [`pixi_lock()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  ([\#30](https://github.com/roaldarbol/rpix/issues/30)).

### Inspecting a project

- New
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  checks the project’s Pixi setup, and suggests fixes for what’s wrong
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
  returns the packages in an environment as a data frame, with the name
  of each R package as R spells it (`Rcpp` for `r-rcpp`).

### Other changes

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md),
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  and
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  gain a `path` argument, like the other functions, to work on a project
  other than the one in the working directory.
- The documentation covers the new workflow
  ([\#31](https://github.com/roaldarbol/rpix/issues/31)): the IDE guide
  has a section for each IDE, with daily use, other environments and
  troubleshooting; “Several environments” is a new guide; Get started
  covers rendering Quarto documents and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md);
  and a contributing guide describes rpix’s own development environment.

## rpix 0.4.0

### Breaking changes

- Exported functions now follow one naming scheme
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)): functions that
  run a Pixi command are called `pixi_<command>()`.
  - `add()` is now
    [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).
    `add()` still works for now, with a deprecation warning.
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
  - `setup_pixi()` now only sets up the project: it creates `pixi.toml`
    if needed, adds R (`r_version` picks the version), and installs rpix
    into the environment, with its dependencies from conda-forge. Its
    `add_to_rprofile` and `global` arguments are gone.
  - `setup_pixi()` removes the “Pixi R library setup” block that earlier
    versions added to the project’s `.Rprofile`, and warns if there’s
    one in `~/.Rprofile`.
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
