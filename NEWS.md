# rpix (development version)

## Fixed

* In a package, `use_pixi()` adds `.pixi`, `pixi.toml` and `pixi.lock` to
  `.Rbuildignore`, and the IDE setup adds `.vscode`, so they stay out of the
  package's builds. `pixi_sitrep()` reports them when they're missing (#114).

## Changed

* rpix's questions, when it offers to install Pixi or to build a package from
  source, say what will happen, then offer a numbered menu (#104).

# rpix 0.7.0 (2026-10-10)

## Added

* `install_pixi()` installs Pixi with Pixi's official installer (#87). When a
  function can't find Pixi, rpix offers to install it.
* `pixi_auth_login()`, `pixi_auth_logout()` and `pixi_auth_status()` log in to
  private conda channels, e.g. on prefix.dev, anaconda.org, Artifactory or S3
  (experimental; #93, #97). `pixi_auth_login()` asks for the token or password
  without showing it, and rpix shows `<hidden>` wherever it would appear.
* When a channel refuses access, rpix's errors and `pixi_sitrep()` say which host
  refused and suggest `pixi_auth_login()`, and `pixi_sitrep()` lists the hosts
  Pixi has logins for (#95).
* `pixi_add()` adds R packages from GitHub, built from source by Pixi's R build
  backend, `pixi-build-r` (experimental; #88, #96):

  ```r
  pixi_add("github::user/repo")
  pixi_add("github::cran/praise", versions = "1.0.0")
  ```

  `@ref` or `versions` picks a branch, tag or commit. `pixi_remove()` removes
  them the same way.
* When `pixi_add()` can't find a CRAN package on conda-forge, it offers to build
  it from CRAN's GitHub mirror, or, in a script, says how (experimental; #89,
  #96).
* New guide: "Private channels and company networks" (#95).

## Changed

* `pixi_add()` finds Bioconductor packages on bioconda without the `bioc::`
  prefix, e.g. `pixi_add("DESeq2")` or `pixi_add("DESeq2", channel = "bioconda")`
  (#92).
* In a Pixi environment's R, `install.packages()` offers to build packages that
  aren't on conda-forge from source, like `pixi_add()`, instead of pointing to
  `utils::install.packages()` (#91).

## Removed

* `add()` and `setup_pixi()`, deprecated since 0.4.0 and 0.5.0. Use `pixi_add()`
  and `use_pixi()` (#85).

## Fixed

* Errors in projects set up with `use_pixi()` show their message again, rather
  than "there is no package called 'rlang'" (#98).

# rpix 0.6.0 (2026-10-09)

## Added

* `pixi_switch()` moves your work to another environment's R (#32). In RStudio
  it starts a new RStudio with that R; in Positron it looks for interpreters
  again and opens the interpreter picker; in VS Code it points the R extension
  at that R.
* `pixi_r()` runs a function in another environment's R, e.g. one with another
  version of R, and returns its result (#33).
* `pixi_check_matrix()` runs a package's tests or `R CMD check` in several
  environments, one at a time or all at once, and shows the results side by
  side. `use_pixi_check_matrix()` adds an environment for each version of R
  (#34).
* `pixi_import_renv()` moves a project from renv: it adds the packages in
  `renv.lock` that nothing else in it needs, at least at their locked versions
  or exactly, lists those it can't add, and turns renv off (#37).
* `pixi_import_description()` adds a package's `Depends` and `Imports` to the
  project, and its `Suggests` to a `test` environment, finding Bioconductor
  packages on bioconda (#36).
* `pixi_scan()` finds the packages the project's code uses, in `.R` files, the R
  chunks of `.qmd` and `.Rmd` documents and Pixi tasks, lists those missing from
  `pixi.toml` (and adds them with `add = TRUE`), and lists packages the code
  never uses (#38).
* `pixi_tasks()`, `pixi_run()`, `pixi_add_task()` and `pixi_remove_task()` work
  with the project's Pixi tasks (#35).
* In a Pixi environment's R, `install.packages()` adds packages with
  `pixi_add()`, so they're recorded in `pixi.toml` and `pixi.lock` (#3). Turn it
  off with `options(rpix.install_packages = FALSE)`.
* `pixi_sitrep()` lists packages in the environment that Pixi didn't install
  (#3).

## Changed

* `pixi_add()` explains when a package isn't built for the project's version of
  R yet, and suggests the newest R it's built for (#80).
* `use_pixi()` adds R together with the packages it needs, so Pixi picks the
  newest R they're built for (#72).
* `pixi_tasks()`, `pixi_environments()`, `pixi_list()` and `pixi_info()` print
  their results in a readable form (#67). They're still data frames, or a list
  for `pixi_info()`.
* `use_pixi_rstudio()` replaces the `rstudio` task if it's there, so it can be
  run again (#72).

## Removed

* `restart_rstudio_with_pixi()`. Use `pixi_switch()`, or start RStudio with
  `pixi run rstudio` (#32).

## Fixed

* Pixi's output is shown in Pixi's own colours, rather than partly red (#68).

# rpix 0.5.0 (2026-10-08)

## Added

* `use_pixi()` sets a project up, with R, rpix and its dependencies (#26). Its
  `ide` argument sets the project up for an IDE (#27):
  * `use_pixi_rstudio()` adds an `rstudio` task, so `pixi run rstudio` starts a
    new RStudio with the environment's R, in the project.
  * `use_pixi_positron()` turns on Positron's discovery of R in Pixi
    environments.
  * `use_pixi_vscode()` adds languageserver, and points the R extension for VS
    Code and VSCodium at the environment's R.
* `pixi_activate()` activates the project's Pixi environment in R that an IDE
  started directly (#25). `use_pixi()` adds a block to the project's
  `.Rprofile` that calls it.
* `pixi_environments()`, `pixi_add_environment()` and
  `pixi_remove_environment()` manage a project's environments, and `pixi_add()`
  and `pixi_remove()` gain `feature` and `platform` arguments (#30).
* `pixi_add_channel()`, `pixi_add_platform()`, `pixi_install()`,
  `pixi_update()`, `pixi_upgrade()` and `pixi_lock()` (#30).
* `pixi_sitrep()` checks the project's Pixi setup, and suggests fixes (#28).
* `pixi_info()`, `pixi_list()` and `pixi_tree()` (#29). `pixi_list()` returns
  an environment's packages as a data frame, with each R package's name as R
  spells it.
* `pixi_add()`, `pixi_remove()`, `pixi_search()` and `use_pixi()` gain a `path`
  argument.
* New guides: using rpix with an IDE, and several environments (#31).

## Changed

* `use_pixi()` keeps your personal R library out of the environment's R, by
  adding conda-forge's `conda-ecosystem-user-package-isolation`
  (conda-forge/r-base-feedstock#37).

## Deprecated

* `setup_pixi()`. Use `use_pixi()` (#26).

# rpix 0.4.0 (2026-10-08)

## Added

* R package names are translated to conda names (#21): `"Rcpp"` becomes
  `r-rcpp`, `"bioc::DESeq2"` a Bioconductor package from bioconda (#17), and
  `"conda::gdal"` a conda package that isn't an R package.
* `pixi_add()` takes version constraints inline (`"dplyr>=1.1"`), and one per
  package in `versions`.
* New guides: getting started, finding packages, coming from renv, sharing
  projects, how rpix works and troubleshooting (#48).

## Changed

* Functions that run a Pixi command are called `pixi_<command>()` (#20).
  `remove()` and `search()` are now `pixi_remove()` and `pixi_search()`.
* rpix no longer points a running R at a Pixi environment's library, which
  could crash R (#14, #22). Work in R started by Pixi instead, e.g. with
  `pixi run R`.
* `setup_pixi()` only sets up the project: it creates `pixi.toml`, adds R
  (`r_version` picks the version) and installs rpix. It removes the "Pixi R
  library setup" block from the project's `.Rprofile`, and warns about one in
  `~/.Rprofile`.
* Pixi commands work from any subfolder of a project, Pixi's failures become R
  errors, and Pixi is found even if it isn't on the `PATH` (#19). Set
  `options(rpix.pixi_path = )` for unusual installs.
* With `dry_run = TRUE`, `pixi_add()`, `pixi_remove()` and `pixi_search()`
  return the command invisibly.
* `pixi_add()` suggests `bioc::` and `conda::` when a package can't be found.

## Deprecated

* `add()`. Use `pixi_add()` (#20).

## Removed

* `remove()` and `search()`, which masked the base functions. Use
  `pixi_remove()` and `pixi_search()` (#20).
* `pixi_to_path()`. rpix finds Pixi itself (#20).
* `reset_r_libraries()`, and `setup_pixi()`'s `add_to_rprofile` and `global`
  arguments (#22).

## Fixed

* `pixi_add(channel = )` adds the channel to the project and installs from it.

# rpix 0.3.0 (2025-06-16)

## Added

* `restart_rstudio_with_pixi()` restarts RStudio with the project's R.

## Changed

* `setup_pixi()` installs rpix from CRAN into the Pixi environment.

# rpix 0.2.0 (2025-05-17)

## Added

* `setup_pixi()` sets up a Pixi project from R.
* `search()` searches for packages, their versions and their dependencies.
* `dry_run` shows the Pixi command without running it.

## Changed

* `add()` adds several packages at once.

# rpix 0.1.0
