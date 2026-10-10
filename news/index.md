# Changelog

## rpix (development version)

### Added

- [`install_pixi()`](https://roald-arboel.com/rpix/reference/install_pixi.md)
  installs Pixi with Pixi’s official installer
  ([\#87](https://github.com/roaldarbol/rpix/issues/87)). When a
  function can’t find Pixi, rpix offers to install it.

- [`pixi_auth_login()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md),
  [`pixi_auth_logout()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md)
  and
  [`pixi_auth_status()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md)
  log in to private conda channels, e.g. on prefix.dev, anaconda.org,
  Artifactory or S3 (experimental;
  [\#93](https://github.com/roaldarbol/rpix/issues/93),
  [\#97](https://github.com/roaldarbol/rpix/issues/97)).
  [`pixi_auth_login()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md)
  asks for the token or password without showing it, and rpix shows
  `<hidden>` wherever it would appear.

- When a channel refuses access, rpix’s errors and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  say which host refused and suggest
  [`pixi_auth_login()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md),
  and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  lists the hosts Pixi has logins for
  ([\#95](https://github.com/roaldarbol/rpix/issues/95)).

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  adds R packages from GitHub, built from source by Pixi’s R build
  backend, `pixi-build-r` (experimental;
  [\#88](https://github.com/roaldarbol/rpix/issues/88),
  [\#96](https://github.com/roaldarbol/rpix/issues/96)):

  ``` r

  pixi_add("github::user/repo")
  pixi_add("github::cran/praise", versions = "1.0.0")
  ```

  `@ref` or `versions` picks a branch, tag or commit.
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  removes them the same way.

- When
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  can’t find a CRAN package on conda-forge, it offers to build it from
  CRAN’s GitHub mirror, or, in a script, says how (experimental;
  [\#89](https://github.com/roaldarbol/rpix/issues/89),
  [\#96](https://github.com/roaldarbol/rpix/issues/96)).

- New guide: “Private channels and company networks”
  ([\#95](https://github.com/roaldarbol/rpix/issues/95)).

### Changed

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  finds Bioconductor packages on bioconda without the `bioc::` prefix,
  e.g. `pixi_add("DESeq2")` or
  `pixi_add("DESeq2", channel = "bioconda")`
  ([\#92](https://github.com/roaldarbol/rpix/issues/92)).
- In a Pixi environment’s R,
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  offers to build packages that aren’t on conda-forge from source, like
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  instead of pointing to
  [`utils::install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  ([\#91](https://github.com/roaldarbol/rpix/issues/91)).

### Removed

- `add()` and `setup_pixi()`, deprecated since 0.4.0 and 0.5.0. Use
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  ([\#85](https://github.com/roaldarbol/rpix/issues/85)).

### Fixed

- Errors in projects set up with
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  show their message again, rather than “there is no package called
  ‘rlang’” ([\#98](https://github.com/roaldarbol/rpix/issues/98)).

## rpix 0.6.0 (2026-10-09)

### Added

- [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  moves your work to another environment’s R
  ([\#32](https://github.com/roaldarbol/rpix/issues/32)). In RStudio it
  starts a new RStudio with that R; in Positron it looks for
  interpreters again and opens the interpreter picker; in VS Code it
  points the R extension at that R.
- [`pixi_r()`](https://roald-arboel.com/rpix/reference/pixi_r.md) runs a
  function in another environment’s R, e.g. one with another version of
  R, and returns its result
  ([\#33](https://github.com/roaldarbol/rpix/issues/33)).
- [`pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
  runs a package’s tests or `R CMD check` in several environments, one
  at a time or all at once, and shows the results side by side.
  [`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)
  adds an environment for each version of R
  ([\#34](https://github.com/roaldarbol/rpix/issues/34)).
- [`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
  moves a project from renv: it adds the packages in `renv.lock` that
  nothing else in it needs, at least at their locked versions or
  exactly, lists those it can’t add, and turns renv off
  ([\#37](https://github.com/roaldarbol/rpix/issues/37)).
- [`pixi_import_description()`](https://roald-arboel.com/rpix/reference/pixi_import_description.md)
  adds a package’s `Depends` and `Imports` to the project, and its
  `Suggests` to a `test` environment, finding Bioconductor packages on
  bioconda ([\#36](https://github.com/roaldarbol/rpix/issues/36)).
- [`pixi_scan()`](https://roald-arboel.com/rpix/reference/pixi_scan.md)
  finds the packages the project’s code uses, in `.R` files, the R
  chunks of `.qmd` and `.Rmd` documents and Pixi tasks, lists those
  missing from `pixi.toml` (and adds them with `add = TRUE`), and lists
  packages the code never uses
  ([\#38](https://github.com/roaldarbol/rpix/issues/38)).
- [`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_run()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_add_task()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
  and
  [`pixi_remove_task()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
  work with the project’s Pixi tasks
  ([\#35](https://github.com/roaldarbol/rpix/issues/35)).
- In a Pixi environment’s R,
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  adds packages with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  so they’re recorded in `pixi.toml` and `pixi.lock`
  ([\#3](https://github.com/roaldarbol/rpix/issues/3)). Turn it off with
  `options(rpix.install_packages = FALSE)`.
- [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  lists packages in the environment that Pixi didn’t install
  ([\#3](https://github.com/roaldarbol/rpix/issues/3)).

### Changed

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  explains when a package isn’t built for the project’s version of R
  yet, and suggests the newest R it’s built for
  ([\#80](https://github.com/roaldarbol/rpix/issues/80)).
- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds R together with the packages it needs, so Pixi picks the newest R
  they’re built for
  ([\#72](https://github.com/roaldarbol/rpix/issues/72)).
- [`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md),
  [`pixi_environments()`](https://roald-arboel.com/rpix/reference/pixi_environments.md),
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  and
  [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  print their results in a readable form
  ([\#67](https://github.com/roaldarbol/rpix/issues/67)). They’re still
  data frames, or a list for
  [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md).
- [`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  replaces the `rstudio` task if it’s there, so it can be run again
  ([\#72](https://github.com/roaldarbol/rpix/issues/72)).

### Removed

- `restart_rstudio_with_pixi()`. Use
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md),
  or start RStudio with `pixi run rstudio`
  ([\#32](https://github.com/roaldarbol/rpix/issues/32)).

### Fixed

- Pixi’s output is shown in Pixi’s own colours, rather than partly red
  ([\#68](https://github.com/roaldarbol/rpix/issues/68)).

## rpix 0.5.0 (2026-10-08)

### Added

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  sets a project up, with R, rpix and its dependencies
  ([\#26](https://github.com/roaldarbol/rpix/issues/26)). Its `ide`
  argument sets the project up for an IDE
  ([\#27](https://github.com/roaldarbol/rpix/issues/27)):
  - [`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    adds an `rstudio` task, so `pixi run rstudio` starts a new RStudio
    with the environment’s R, in the project.
  - [`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    turns on Positron’s discovery of R in Pixi environments.
  - [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
    adds languageserver, and points the R extension for VS Code and
    VSCodium at the environment’s R.
- [`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)
  activates the project’s Pixi environment in R that an IDE started
  directly ([\#25](https://github.com/roaldarbol/rpix/issues/25)).
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds a block to the project’s `.Rprofile` that calls it.
- [`pixi_environments()`](https://roald-arboel.com/rpix/reference/pixi_environments.md),
  [`pixi_add_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md)
  and
  [`pixi_remove_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md)
  manage a project’s environments, and
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  gain `feature` and `platform` arguments
  ([\#30](https://github.com/roaldarbol/rpix/issues/30)).
- [`pixi_add_channel()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md),
  [`pixi_add_platform()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md),
  [`pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md),
  [`pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md),
  [`pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  and
  [`pixi_lock()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  ([\#30](https://github.com/roaldarbol/rpix/issues/30)).
- [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  checks the project’s Pixi setup, and suggests fixes
  ([\#28](https://github.com/roaldarbol/rpix/issues/28)).
- [`pixi_info()`](https://roald-arboel.com/rpix/reference/pixi_info.md),
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  and
  [`pixi_tree()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  ([\#29](https://github.com/roaldarbol/rpix/issues/29)).
  [`pixi_list()`](https://roald-arboel.com/rpix/reference/pixi_info.md)
  returns an environment’s packages as a data frame, with each R
  package’s name as R spells it.
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md),
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  and
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  gain a `path` argument.
- New guides: using rpix with an IDE, and several environments
  ([\#31](https://github.com/roaldarbol/rpix/issues/31)).

### Changed

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  keeps your personal R library out of the environment’s R, by adding
  conda-forge’s `conda-ecosystem-user-package-isolation`
  (conda-forge/r-base-feedstock#37).

### Deprecated

- `setup_pixi()`. Use
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  ([\#26](https://github.com/roaldarbol/rpix/issues/26)).

## rpix 0.4.0 (2026-10-08)

### Added

- R package names are translated to conda names
  ([\#21](https://github.com/roaldarbol/rpix/issues/21)): `"Rcpp"`
  becomes `r-rcpp`, `"bioc::DESeq2"` a Bioconductor package from
  bioconda ([\#17](https://github.com/roaldarbol/rpix/issues/17)), and
  `"conda::gdal"` a conda package that isn’t an R package.
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  takes version constraints inline (`"dplyr>=1.1"`), and one per package
  in `versions`.
- New guides: getting started, finding packages, coming from renv,
  sharing projects, how rpix works and troubleshooting
  ([\#48](https://github.com/roaldarbol/rpix/issues/48)).

### Changed

- Functions that run a Pixi command are called `pixi_<command>()`
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)).
  [`remove()`](https://rdrr.io/r/base/rm.html) and
  [`search()`](https://rdrr.io/r/base/search.html) are now
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md).
- rpix no longer points a running R at a Pixi environment’s library,
  which could crash R
  ([\#14](https://github.com/roaldarbol/rpix/issues/14),
  [\#22](https://github.com/roaldarbol/rpix/issues/22)). Work in R
  started by Pixi instead, e.g. with `pixi run R`.
- `setup_pixi()` only sets up the project: it creates `pixi.toml`, adds
  R (`r_version` picks the version) and installs rpix. It removes the
  “Pixi R library setup” block from the project’s `.Rprofile`, and warns
  about one in `~/.Rprofile`.
- Pixi commands work from any subfolder of a project, Pixi’s failures
  become R errors, and Pixi is found even if it isn’t on the `PATH`
  ([\#19](https://github.com/roaldarbol/rpix/issues/19)). Set
  `options(rpix.pixi_path = )` for unusual installs.
- With `dry_run = TRUE`,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  return the command invisibly.
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  suggests `bioc::` and `conda::` when a package can’t be found.

### Deprecated

- `add()`. Use
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)).

### Removed

- [`remove()`](https://rdrr.io/r/base/rm.html) and
  [`search()`](https://rdrr.io/r/base/search.html), which masked the
  base functions. Use
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)).
- `pixi_to_path()`. rpix finds Pixi itself
  ([\#20](https://github.com/roaldarbol/rpix/issues/20)).
- `reset_r_libraries()`, and `setup_pixi()`’s `add_to_rprofile` and
  `global` arguments
  ([\#22](https://github.com/roaldarbol/rpix/issues/22)).

### Fixed

- `pixi_add(channel = )` adds the channel to the project and installs
  from it.

## rpix 0.3.0 (2025-06-16)

### Added

- `restart_rstudio_with_pixi()` restarts RStudio with the project’s R.

### Changed

- `setup_pixi()` installs rpix from CRAN into the Pixi environment.

## rpix 0.2.0 (2025-05-17)

### Added

- `setup_pixi()` sets up a Pixi project from R.
- [`search()`](https://rdrr.io/r/base/search.html) searches for
  packages, their versions and their dependencies.
- `dry_run` shows the Pixi command without running it.

### Changed

- `add()` adds several packages at once.

## rpix 0.1.0
