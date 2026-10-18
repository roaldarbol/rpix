# rpix (development version)

## Added

* `use_pixi_emacs()`, `use_pixi_neovim()` and `use_pixi_zed()` set up those
  editors, and `use_pixi(ide = )` takes them too. They add languageserver,
  and a `.envrc` from the new `use_pixi_direnv()`, which activates the
  project's environment with direnv. `pixi_switch()` and `pixi_sitrep()`
  know them (#185, #186, #187).
* `use_pixi_positron()` makes the default environment's R Positron's default
  for the project, so Positron (2026.10 or later) starts it when the project
  opens, without picking it first. `default_r = FALSE` leaves it out (#133).
* `use_pixi_vscode(console = )` sets up arf or radian as the R extension's
  console, starting the environment's R. `pixi_switch()` keeps the console
  (#132).
* In an interactive session, `use_pixi_vscode()` asks which console to use.
  `use_pixi(ide = )` passes the IDEs' settings on, e.g.
  `use_pixi(ide = "vscode", console = "arf")` (#134).
* In an interactive session, `pixi_switch()` without an environment asks
  which, from a menu of the project's environments (#189).
* `use_pixi()` turns on Pixi's activation cache for the project, so R started
  through Pixi, e.g. by `pixi run R` or Positron, starts in a fraction of a
  second rather than a few. `activation_cache = FALSE` leaves it off (#195).
* `options(rpix.verbose = TRUE)` shows the output and build logs of Pixi
  that rpix keeps back, as they come (#222).
* When R starts in a Pixi environment without rpix, e.g. a collaborator's or
  another environment of the project, the project's `.Rprofile` says so, with
  the command that installs it. `use_pixi()` updates the `.Rprofile` of a
  project set up earlier (#216).

## Changed

* Packages from GitHub build with `pixi-build-r` 0.2.0 or later, which rpix
  now asks for. It adds Rust, CMake, pkg-config and R's recommended packages,
  and installs into R's library on Windows, so rpix no longer does (#148,
  #149, #150, #152). rpix still adds Java, and on Windows, MSYS2's tools and
  MinGW's compilers. A project with packages as of a date before 2026-10-15
  can't get that `pixi-build-r`, so rpix stops and says so.
* On Windows, `use_pixi_vscode()` and `pixi_switch()` also give the commands
  that start VSCodium, Cursor and Windsurf from the environment, and the IDE
  guide says the VS Code setup works in them too.

* rpix finds the project of the running Pixi environment from
  `PIXI_WORKSPACE_ROOT`, as Pixi 0.82 names it, and otherwise from
  `PIXI_PROJECT_ROOT`, which Pixi keeps as an alias and older versions set.
* `use_pixi()` and the IDE setups only add the packages the project doesn't
  have yet, rather than having Pixi say of each of the others that it's
  there, and `use_pixi(ide = )` sets direnv up once for several editors, so
  running them again, or for several IDEs, says each thing once (#222).
* `pixi_add()`, and `install.packages()` in a Pixi environment, show Pixi's
  output once the packages are added. When Pixi can't add them but rpix can,
  e.g. from bioconda or by building from source, Pixi's error isn't shown;
  when rpix can't, all of Pixi's output is (#222).
* A package from GitHub shows a line while it builds, rather than the
  build's log, which is shown if the build fails (#222).
* `use_pixi()` installs rpix into the environment quietly, and only if the
  environment doesn't have this version or a newer one (#222).

## Fixed

* `use_pixi()` sets up the folder it's given, or the working directory, rather
  than a Pixi project in a parent folder. It says when a parent folder is a
  Pixi project, and in an interactive session asks whether to set that one up
  instead (#214).
* In a package, `pixi_sitrep()` no longer says the package itself was
  installed without Pixi, e.g. after `devtools::install()` (#220).
* In a project with several environments, `pixi_add()`, `pixi_remove()` and
  `install.packages()` install the environment R runs in, as Pixi doesn't by
  itself there; a package added was missing until the next `pixi install`
  (#202).
* On Windows, packages from GitHub with a `configure` script build: rpix
  gives their builds MinGW's compilers, which R uses there, in place of
  `pixi-build-r`'s, whose Fortran compiler broke the script's checks
  (#191).
* When the IDE is set up for the project but runs another R, `pixi_sitrep()`
  says how to start the project's R in it, e.g. `pixi run rstudio` for
  RStudio, rather than that the IDE is set up. It no longer lists R's base
  packages as loaded from outside the project, and knows Emacs, Neovim and
  Zed when it's in none of the IDEs (#219).
* In a copy of a project, rpix's functions such as `pixi_add()` no longer
  change the original project. When the running Pixi environment says it's
  from another project than the working directory's, as Pixi's activation
  cache can after a copy or move, rpix uses the working directory's project,
  and says so (#218).
* A moved or copied project no longer runs the R of its old location. Pixi's
  activation cache, which `use_pixi()` turns on, keeps the old paths, so rpix
  removes it when it has another location, before Pixi uses it, and says the
  project was moved or copied. `pixi_activate()` and `pixi_sitrep()` also
  name environments that were installed in the old location, which can't be
  moved, and say how to reinstall them (#217).
* When conda-forge has a new R but no R packages for it yet, as with R 4.6:
  `use_pixi(install_rpix = FALSE)` picks the newest R it has packages for,
  rather than one no package can be added to; `use_pixi(r_version = )` with
  that R says so, and which R is the newest you can use; and
  `pixi_import_renv()` with a lock file from that R uses the newest R the
  packages are built for, and says so (#207).
* When a package isn't built for the project's R, `pixi_add()` names it,
  also when it has a version constraint, and suggests a command that's valid
  R and replaces the project's R rather than adding a second one. For an old
  version pinned with `==` or `=`, which conda-forge won't build for a newer
  R, it offers a newer version, a build of that version from source, or the
  older R for the whole project (#208).
* `pixi_add()` and `install.packages()` only offer to build a package from
  CRAN's source when it's on CRAN. A mistyped name, such as `"dplyrr"`, says
  it's on neither conda-forge nor CRAN, and suggests close names: "Did you
  mean dplyr?" (#212).
* A package from GitHub that rpix can't read says why: there's no public
  repository by that name, it has no such branch, tag or commit, or GitHub
  couldn't be reached, rather than always that it needs a `DESCRIPTION`
  (#213).
* `pixi_remove()` and `pixi_search()` take a Bioconductor package's name
  without `bioc::`, as `pixi_add()` does: `pixi_remove("limma")` removes
  bioconductor-limma when that's what `pixi.toml` has, and
  `pixi_search("limma")` looks on bioconda when it isn't on conda-forge
  (#211).
* rpix only counts a package as on conda-forge or bioconda when one has its
  exact name, as Pixi's search also finds names that contain it. So
  `pixi_add()` offers to build a CRAN package such as faux from source, rather
  than failing because Pixi found r-fauxpas, and `pixi_search("faux")` no
  longer shows r-fauxpas (#205).
* In a project with packages as of a date before 2026-10-15, `pixi_add()`
  and `pixi_import_renv()` no longer offer to build CRAN packages that
  aren't on conda-forge from source, which then failed: they say that the
  date hides Pixi's build backend instead (#221).

# rpix 0.8.0 (2026-10-13)

## Added

* `pixi_set_date()` and `use_pixi(date = )` use packages as they were on a
  date, with Pixi's `exclude-newer`, e.g. to rerun an old analysis; a duration
  such as `"7d"` leaves out the newest releases instead. `pixi_sitrep()`
  reports it (#106).
* `use_pixi_check_matrix(minimum = TRUE)` adds a `minimum` environment, with
  R and the package's dependencies at the lowest versions its `DESCRIPTION`
  allows, to check that those minimums really work. It has the `Suggests` too,
  for the tests and examples; those without a minimum get at least the
  version the project has (#112, #168).
* `use_pixi_github_action()` writes a GitHub Actions workflow that uses the
  project's environments exactly as `pixi.lock` records them: `R CMD check`
  on Linux, macOS and Windows for each environment, test coverage, a pkgdown
  site, or a Pixi task. It uses the environments that have what the workflow
  needs, such as the check matrix's for `R CMD check`, and says how to add
  what an environment lacks (#107, #159).
* In a package, `pixi_sitrep()` checks that `pixi.toml` has what
  `DESCRIPTION` needs: the `Depends`, `Imports` and `LinkingTo` packages in
  the default environment, the `Suggests` somewhere, and installed versions at
  least the minimums `DESCRIPTION` asks for (#113).
* New article: "How many packages you can use", with how much of CRAN and
  Bioconductor works through Pixi and rpix, and what's still missing (#121).
* `pixi_import_renv()` adds the lock file's GitHub packages, built from source
  at the commit it records, and offers to build CRAN packages that aren't on
  conda-forge from CRAN's source, as `pixi_add()` does. As building from
  source is experimental, it says which packages it built (#162).
* New guide: "Developing a package", from setting up to CI (#117).
* An agent skill, in `skills/rpix/`, teaches coding agents such as Claude
  Code, Codex and Cursor to work in R projects the Pixi way: add packages with
  `pixi_add()` rather than `install.packages()`, run the environment's R, and
  start from `pixi_sitrep()` when something's off. In Claude Code, install it
  with `/plugin marketplace add roaldarbol/rpix` and
  `/plugin install rpix@rpix` (#155).

## Changed

* Packages built from source build on Windows too: in a project for Windows,
  rpix installs them into R's library folder and adds MSYS2's `make`, `sed`
  and `coreutils` (and, for Rust, the GNU target), which `pixi-build-r` doesn't
  yet (#123).
* Packages built from source (`pixi_add("github::...")`, and CRAN packages that
  aren't on conda-forge) get what `pixi-build-r` doesn't add yet: R's
  recommended packages they use, such as Matrix and MASS, and the build tools
  their `SystemRequirements` names: Rust, Java, CMake or pkg-config (#118).
* rpix's questions, when it offers to install Pixi or to build a package from
  source, say what will happen, then offer a numbered menu (#104).

## Fixed

* `pixi_add_environment(default_feature = FALSE)` adds
  `conda-ecosystem-user-package-isolation` to an environment with R, which
  keeps the personal R library out, as `use_pixi()` does for the default
  feature. Before, such an environment, e.g. with another version of R, could
  load packages built for another R, and crash. `pixi_add()` adds it too when
  it adds R to the default feature without it, and `pixi_sitrep()` reports
  environments with R that lack it, e.g. after editing `pixi.toml` by hand
  (#160).
* "Coming from renv" no longer says that packages from GitHub aren't
  available, and that only a few CRAN packages aren't on conda-forge: it says
  that Pixi can build them from source (#161).
* `pixi_add()`, `pixi_install()`, `pixi_update()` and `pixi_upgrade()` notice
  when Pixi skips a package's install script, which Bioconductor's annotation
  and data packages (such as org.Hs.eg.db) use to download their data. They
  offer to allow these scripts in the project, and otherwise warn. Before,
  such packages were added without their data, and didn't load. Committing
  `.pixi/config.toml` allows the scripts for everyone who uses the project,
  CI included (#142, #158).
* The check matrix's environments keep your personal R library out, as the
  default environment does. Without it, R could load packages built for your
  usual R, and crash (#112).
* Packages built from source whose names have a dot, such as sym.arma, are
  written correctly into `pixi.toml`; Pixi couldn't read them before (#120).
* In a package, `use_pixi()` adds `.pixi`, `pixi.toml` and `pixi.lock` to
  `.Rbuildignore`, and the IDE setup adds `.vscode`, so they stay out of the
  package's builds. `pixi_sitrep()` reports them when they're missing (#114).

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
