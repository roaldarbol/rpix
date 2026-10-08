# rpix (development version)

## Breaking changes

- `restart_rstudio_with_pixi()` is removed. Use `pixi_switch()` instead, or start RStudio with `pixi run rstudio` (#32).

## New features

- New `pixi_switch()` moves your work to another environment's R (#32). In RStudio it starts a new RStudio with that R, in Positron it opens the interpreter picker, and in VS Code it points the R extension at that R.
- New `pixi_tasks()`, `pixi_run()`, `pixi_add_task()` and `pixi_remove_task()` work with the project's Pixi tasks (#35).
- New `pixi_r()` runs a function in another environment's R, e.g. one with another version of R, and returns its result (#33).
- New `pixi_check_matrix()` runs a package's tests or `R CMD check` in several environments, e.g. one for each version of R, one at a time or all at once, and shows the results side by side. `use_pixi_check_matrix()` adds those environments (#34).
- New `pixi_import_description()` adds a package's dependencies from its `DESCRIPTION`: `Depends` and `Imports` to the project, and `Suggests` to a `test` environment. It finds Bioconductor packages on bioconda, and lists the packages that aren't on conda-forge or bioconda (#36).
- New `pixi_import_renv()` moves a project from renv: it adds the packages in `renv.lock`, at least at their locked versions or exactly, and turns renv off. It adds only the packages nothing else in the lock file needs, and lists those it can't add, e.g. from GitHub (#37).
- New `pixi_scan()` finds the packages the project's code uses, in `.R` files, the R chunks of `.qmd` and `.Rmd` documents, and Pixi tasks. It lists those missing from `pixi.toml`, and adds them with `add = TRUE`, and lists packages the code never uses (#38).
- In a Pixi environment's R, `install.packages()` adds packages with `pixi_add()`, so they're recorded in `pixi.toml` and `pixi.lock` (#3). Packages that aren't on conda-forge or bioconda, and arguments Pixi can't use, such as `lib`, give an error that points to `utils::install.packages()`. `pixi_activate()` sets this up; turn it off with `options(rpix.install_packages = FALSE)`.
- `pixi_sitrep()` lists packages in the environment that Pixi didn't install, so `pixi.toml` doesn't record them (#3).

## Minor improvements and fixes

- `pixi_tasks()`, `pixi_environments()`, `pixi_list()` and `pixi_info()` print their results in a readable form (#67). They're still data frames, or a list for `pixi_info()`.
- Pixi's output is no longer partly red. Pixi reports progress on stderr, which was shown in red; rpix now shows it in Pixi's own colours.
- `use_pixi()` adds R together with the packages it needs, so Pixi picks the newest R they're built for. When conda-forge had just released a new R, it picked that R, and adding packages failed until they were rebuilt for it (#72).
- `use_pixi_rstudio()` replaces the `rstudio` task if it's there, so it can be run again, e.g. after renaming the `.Rproj` file (#72).
- In Positron, `pixi_switch()` looks for interpreters again before opening the interpreter picker, so environments added while Positron is open are listed.
- `pixi_add()` explains when a package isn't built for the project's version of R yet, which happens for a while after conda-forge releases a new R, and suggests the newest R it's built for (#80).

# rpix 0.5.0

rpix now sets projects up for RStudio, Positron and VS Code, and makes sure R only uses the project's packages.

## Setting up a project

- New `use_pixi()` replaces `setup_pixi()`, which is deprecated (#26). Its `ide` argument sets the project up for an IDE, with the new `use_pixi_rstudio()`, `use_pixi_positron()` and `use_pixi_vscode()` (#27):
  - `use_pixi_rstudio()` adds an `rstudio` task for each of the project's platforms, so `pixi run rstudio` starts a new RStudio with the environment's R, in the project.
  - `use_pixi_positron()` turns on Positron's discovery of R in Pixi environments. Positron then activates the environment itself when it starts that R.
  - `use_pixi_vscode()` adds languageserver to the environment, and points the R extension for VS Code and VSCodium at the environment's R.
- New `pixi_activate()` activates the project's Pixi environment in R that an IDE started directly, without Pixi (#25). It sets the environment variables Pixi would set, and removes your personal library from `.libPaths()`. `use_pixi()` adds a block to the project's `.Rprofile` that calls it, and removes the personal library before any package loads.
- `use_pixi()` keeps your personal R library out of the environment's R, by adding conda-forge's `conda-ecosystem-user-package-isolation` to the project. conda-forge's R otherwise puts the personal library first on `.libPaths()`, so packages built for your usual R could be loaded, and crash it (conda-forge/r-base-feedstock#37).

## Environments

- `pixi_add()` and `pixi_remove()` gain `feature` and `platform` arguments, and new `pixi_environments()`, `pixi_add_environment()` and `pixi_remove_environment()` manage a project's environments, e.g. one with another version of R (#30).
- New `pixi_add_channel()` and `pixi_add_platform()`, and `pixi_install()`, `pixi_update()`, `pixi_upgrade()` and `pixi_lock()` (#30).

## Inspecting a project

- New `pixi_sitrep()` checks the project's Pixi setup, and suggests fixes for what's wrong (#28): Pixi itself, whether the lock file is up to date, whether R is the project's Pixi R and is activated, libraries and packages from outside the project, the `.Rprofile` block, and whether the IDE is set up.
- New `pixi_info()`, `pixi_list()` and `pixi_tree()` (#29). `pixi_list()` returns the packages in an environment as a data frame, with the name of each R package as R spells it (`Rcpp` for `r-rcpp`).

## Other changes

- `pixi_add()`, `pixi_remove()`, `pixi_search()` and `use_pixi()` gain a `path` argument, like the other functions, to work on a project other than the one in the working directory.
- The documentation covers the new workflow (#31): the IDE guide has a section for each IDE, with daily use, other environments and troubleshooting; "Several environments" is a new guide; Get started covers rendering Quarto documents and `pixi_sitrep()`; and a contributing guide describes rpix's own development environment.

# rpix 0.4.0

## Breaking changes
- Exported functions now follow one naming scheme (#20): functions that run a Pixi command are called `pixi_<command>()`.
  - `add()` is now `pixi_add()`. `add()` still works for now, with a deprecation warning.
  - `remove()` and `search()` are now `pixi_remove()` and `pixi_search()`. The old names were removed rather than deprecated, because they masked `base::remove()` and `base::search()` whenever rpix was attached.
  - `pixi_to_path()` is removed. rpix finds Pixi itself.
- rpix no longer points a running R at a Pixi environment's library (#22). R mixed with packages built for a different R could crash (#14). Work in R started by Pixi instead, e.g. with `pixi run R`.
  - `setup_pixi()` now only sets up the project: it creates `pixi.toml` if needed, adds R (`r_version` picks the version), and installs rpix into the environment, with its dependencies from conda-forge. Its `add_to_rprofile` and `global` arguments are gone.
  - `setup_pixi()` removes the "Pixi R library setup" block that earlier versions added to the project's `.Rprofile`, and warns if there's one in `~/.Rprofile`.
  - `reset_r_libraries()` is removed.

## Other changes
- All Pixi commands now go through a single internal runner built on *processx* (#19). Arguments are passed without shell quoting, commands work from any subfolder of a project (`--manifest-path`), Pixi failures become R errors, and Pixi is found even if it isn't on the `PATH` (set `options(rpix.pixi_path = ...)` for unusual installs).
- `pixi_add()`, `pixi_remove()` and `pixi_search()` with `dry_run = TRUE` now return the command invisibly.
- R package names are now translated to conda names properly (#21): names are lowercased (`"Rcpp"` becomes `r-rcpp`), and a pak-like prefix says where a package comes from: `"bioc::DESeq2"` for Bioconductor packages from bioconda (#17), and `"conda::gdal"` for conda packages that aren't R packages. Names with `-` or `_` are used as is.
- `pixi_add()` accepts version constraints inline (`"dplyr>=1.1"`) and one constraint per package in `versions`.
- `pixi_add(channel = )` works again: Pixi has no `--channel` flag for `pixi add`, so the channel is now added to the project and used in the package spec. The same happens automatically for bioconda.
- `pixi_add()` suggests `bioc::` and `conda::` when a package can't be found.
- The documentation is restructured (#48): a walk-through in Get started, guides to finding packages, coming from renv, sharing projects and using an IDE, and pages on how rpix works and troubleshooting.
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

