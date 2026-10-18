# Changelog

## rpix (development version)

### Added

- [`use_pixi_emacs()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
  [`use_pixi_neovim()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  and
  [`use_pixi_zed()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  set up those editors, and `use_pixi(ide = )` takes them too. They add
  languageserver, and a `.envrc` from the new
  [`use_pixi_direnv()`](https://roald-arboel.com/rpix/reference/use_pixi_direnv.md),
  which activates the project’s environment with direnv.
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  know them ([\#185](https://github.com/roaldarbol/rpix/issues/185),
  [\#186](https://github.com/roaldarbol/rpix/issues/186),
  [\#187](https://github.com/roaldarbol/rpix/issues/187)).
- [`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  makes the default environment’s R Positron’s default for the project,
  so Positron (2026.10 or later) starts it when the project opens,
  without picking it first. `default_r = FALSE` leaves it out
  ([\#133](https://github.com/roaldarbol/rpix/issues/133)).
- `use_pixi_vscode(console = )` sets up arf or radian as the R
  extension’s console, starting the environment’s R.
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  keeps the console
  ([\#132](https://github.com/roaldarbol/rpix/issues/132)).
- In an interactive session,
  [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  asks which console to use. `use_pixi(ide = )` passes the IDEs’
  settings on, e.g. `use_pixi(ide = "vscode", console = "arf")`
  ([\#134](https://github.com/roaldarbol/rpix/issues/134)).
- In an interactive session,
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  without an environment asks which, from a menu of the project’s
  environments ([\#189](https://github.com/roaldarbol/rpix/issues/189)).
- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  turns on Pixi’s activation cache for the project, so R started through
  Pixi, e.g. by `pixi run R` or Positron, starts in a fraction of a
  second rather than a few. `activation_cache = FALSE` leaves it off
  ([\#195](https://github.com/roaldarbol/rpix/issues/195)).
- `options(rpix.verbose = TRUE)` shows the output and build logs of Pixi
  that rpix keeps back, as they come
  ([\#222](https://github.com/roaldarbol/rpix/issues/222)).
- When R starts in a Pixi environment without rpix, e.g. a
  collaborator’s or another environment of the project, the project’s
  `.Rprofile` says so, with the command that installs it.
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  updates the `.Rprofile` of a project set up earlier
  ([\#216](https://github.com/roaldarbol/rpix/issues/216)).

### Changed

- Packages from GitHub build with `pixi-build-r` 0.2.0 or later, which
  rpix now asks for. It adds Rust, CMake, pkg-config and R’s recommended
  packages, and installs into R’s library on Windows, so rpix no longer
  does ([\#148](https://github.com/roaldarbol/rpix/issues/148),
  [\#149](https://github.com/roaldarbol/rpix/issues/149),
  [\#150](https://github.com/roaldarbol/rpix/issues/150),
  [\#152](https://github.com/roaldarbol/rpix/issues/152)). rpix still
  adds Java, and on Windows, MSYS2’s tools and MinGW’s compilers. A
  project with packages as of a date before 2026-10-15 can’t get that
  `pixi-build-r`, so rpix stops and says so.

- On Windows,
  [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
  and
  [`pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  also give the commands that start VSCodium, Cursor and Windsurf from
  the environment, and the IDE guide says the VS Code setup works in
  them too.

- rpix finds the project of the running Pixi environment from
  `PIXI_WORKSPACE_ROOT`, as Pixi 0.82 names it, and otherwise from
  `PIXI_PROJECT_ROOT`, which Pixi keeps as an alias and older versions
  set.

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  and the IDE setups only add the packages the project doesn’t have yet,
  rather than having Pixi say of each of the others that it’s there, and
  `use_pixi(ide = )` sets direnv up once for several editors, so running
  them again, or for several IDEs, says each thing once
  ([\#222](https://github.com/roaldarbol/rpix/issues/222)).

- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  and
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  in a Pixi environment, show Pixi’s output once the packages are added.
  When Pixi can’t add them but rpix can, e.g. from bioconda or by
  building from source, Pixi’s error isn’t shown; when rpix can’t, all
  of Pixi’s output is
  ([\#222](https://github.com/roaldarbol/rpix/issues/222)).

- A package from GitHub shows a line while it builds, rather than the
  build’s log, which is shown if the build fails
  ([\#222](https://github.com/roaldarbol/rpix/issues/222)).

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  installs rpix into the environment quietly, and only if the
  environment doesn’t have this version or a newer one
  ([\#222](https://github.com/roaldarbol/rpix/issues/222)).

### Fixed

- [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  sets up the folder it’s given, or the working directory, rather than a
  Pixi project in a parent folder. It says when a parent folder is a
  Pixi project, and in an interactive session asks whether to set that
  one up instead
  ([\#214](https://github.com/roaldarbol/rpix/issues/214)).
- In a package,
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  no longer says the package itself was installed without Pixi,
  e.g. after
  [`devtools::install()`](https://devtools.r-lib.org/reference/install.html)
  ([\#220](https://github.com/roaldarbol/rpix/issues/220)).
- In a project with several environments,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  install the environment R runs in, as Pixi doesn’t by itself there; a
  package added was missing until the next `pixi install`
  ([\#202](https://github.com/roaldarbol/rpix/issues/202)).
- On Windows, packages from GitHub with a `configure` script build: rpix
  gives their builds MinGW’s compilers, which R uses there, in place of
  `pixi-build-r`’s, whose Fortran compiler broke the script’s checks
  ([\#191](https://github.com/roaldarbol/rpix/issues/191)).
- When the IDE is set up for the project but runs another R,
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  says how to start the project’s R in it, e.g. `pixi run rstudio` for
  RStudio, rather than that the IDE is set up. It no longer lists R’s
  base packages as loaded from outside the project, and knows Emacs,
  Neovim and Zed when it’s in none of the IDEs
  ([\#219](https://github.com/roaldarbol/rpix/issues/219)).
- In a copy of a project, rpix’s functions such as
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) no
  longer change the original project. When the running Pixi environment
  says it’s from another project than the working directory’s, as Pixi’s
  activation cache can after a copy or move, rpix uses the working
  directory’s project, and says so
  ([\#218](https://github.com/roaldarbol/rpix/issues/218)).
- A moved or copied project no longer runs the R of its old location.
  Pixi’s activation cache, which
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  turns on, keeps the old paths, so rpix removes it when it has another
  location, before Pixi uses it, and says the project was moved or
  copied.
  [`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)
  and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  also name environments that were installed in the old location, which
  can’t be moved, and say how to reinstall them
  ([\#217](https://github.com/roaldarbol/rpix/issues/217)).
- When conda-forge has a new R but no R packages for it yet, as with R
  4.6: `use_pixi(install_rpix = FALSE)` picks the newest R it has
  packages for, rather than one no package can be added to;
  `use_pixi(r_version = )` with that R says so, and which R is the
  newest you can use; and
  [`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
  with a lock file from that R uses the newest R the packages are built
  for, and says so
  ([\#207](https://github.com/roaldarbol/rpix/issues/207)).
- When a package isn’t built for the project’s R,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  names it, also when it has a version constraint, and suggests a
  command that’s valid R and replaces the project’s R rather than adding
  a second one. For an old version pinned with `==` or `=`, which
  conda-forge won’t build for a newer R, it offers a newer version, a
  build of that version from source, or the older R for the whole
  project ([\#208](https://github.com/roaldarbol/rpix/issues/208)).
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  only offer to build a package from CRAN’s source when it’s on CRAN. A
  mistyped name, such as `"dplyrr"`, says it’s on neither conda-forge
  nor CRAN, and suggests close names: “Did you mean dplyr?”
  ([\#212](https://github.com/roaldarbol/rpix/issues/212)).
- A package from GitHub that rpix can’t read says why: there’s no public
  repository by that name, it has no such branch, tag or commit, or
  GitHub couldn’t be reached, rather than always that it needs a
  `DESCRIPTION`
  ([\#213](https://github.com/roaldarbol/rpix/issues/213)).
- [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
  and
  [`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
  take a Bioconductor package’s name without `bioc::`, as
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  does: `pixi_remove("limma")` removes bioconductor-limma when that’s
  what `pixi.toml` has, and `pixi_search("limma")` looks on bioconda
  when it isn’t on conda-forge
  ([\#211](https://github.com/roaldarbol/rpix/issues/211)).
- rpix only counts a package as on conda-forge or bioconda when one has
  its exact name, as Pixi’s search also finds names that contain it. So
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  offers to build a CRAN package such as faux from source, rather than
  failing because Pixi found r-fauxpas, and `pixi_search("faux")` no
  longer shows r-fauxpas
  ([\#205](https://github.com/roaldarbol/rpix/issues/205)).
- In a project with packages as of a date before 2026-10-15,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  and
  [`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
  no longer offer to build CRAN packages that aren’t on conda-forge from
  source, which then failed: they say that the date hides Pixi’s build
  backend instead
  ([\#221](https://github.com/roaldarbol/rpix/issues/221)).

## rpix 0.8.0 (2026-10-13)

### Added

- [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)
  and `use_pixi(date = )` use packages as they were on a date, with
  Pixi’s `exclude-newer`, e.g. to rerun an old analysis; a duration such
  as `"7d"` leaves out the newest releases instead.
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  reports it ([\#106](https://github.com/roaldarbol/rpix/issues/106)).
- `use_pixi_check_matrix(minimum = TRUE)` adds a `minimum` environment,
  with R and the package’s dependencies at the lowest versions its
  `DESCRIPTION` allows, to check that those minimums really work. It has
  the `Suggests` too, for the tests and examples; those without a
  minimum get at least the version the project has
  ([\#112](https://github.com/roaldarbol/rpix/issues/112),
  [\#168](https://github.com/roaldarbol/rpix/issues/168)).
- [`use_pixi_github_action()`](https://roald-arboel.com/rpix/reference/use_pixi_github_action.md)
  writes a GitHub Actions workflow that uses the project’s environments
  exactly as `pixi.lock` records them: `R CMD check` on Linux, macOS and
  Windows for each environment, test coverage, a pkgdown site, or a Pixi
  task. It uses the environments that have what the workflow needs, such
  as the check matrix’s for `R CMD check`, and says how to add what an
  environment lacks
  ([\#107](https://github.com/roaldarbol/rpix/issues/107),
  [\#159](https://github.com/roaldarbol/rpix/issues/159)).
- In a package,
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  checks that `pixi.toml` has what `DESCRIPTION` needs: the `Depends`,
  `Imports` and `LinkingTo` packages in the default environment, the
  `Suggests` somewhere, and installed versions at least the minimums
  `DESCRIPTION` asks for
  ([\#113](https://github.com/roaldarbol/rpix/issues/113)).
- New article: “How many packages you can use”, with how much of CRAN
  and Bioconductor works through Pixi and rpix, and what’s still missing
  ([\#121](https://github.com/roaldarbol/rpix/issues/121)).
- [`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
  adds the lock file’s GitHub packages, built from source at the commit
  it records, and offers to build CRAN packages that aren’t on
  conda-forge from CRAN’s source, as
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  does. As building from source is experimental, it says which packages
  it built ([\#162](https://github.com/roaldarbol/rpix/issues/162)).
- New guide: “Developing a package”, from setting up to CI
  ([\#117](https://github.com/roaldarbol/rpix/issues/117)).
- An agent skill, in `skills/rpix/`, teaches coding agents such as
  Claude Code, Codex and Cursor to work in R projects the Pixi way: add
  packages with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  rather than
  [`install.packages()`](https://rdrr.io/r/utils/install.packages.html),
  run the environment’s R, and start from
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  when something’s off. In Claude Code, install it with
  `/plugin marketplace add roaldarbol/rpix` and
  `/plugin install rpix@rpix`
  ([\#155](https://github.com/roaldarbol/rpix/issues/155)).

### Changed

- Packages built from source build on Windows too: in a project for
  Windows, rpix installs them into R’s library folder and adds MSYS2’s
  `make`, `sed` and `coreutils` (and, for Rust, the GNU target), which
  `pixi-build-r` doesn’t yet
  ([\#123](https://github.com/roaldarbol/rpix/issues/123)).
- Packages built from source (`pixi_add("github::...")`, and CRAN
  packages that aren’t on conda-forge) get what `pixi-build-r` doesn’t
  add yet: R’s recommended packages they use, such as Matrix and MASS,
  and the build tools their `SystemRequirements` names: Rust, Java,
  CMake or pkg-config
  ([\#118](https://github.com/roaldarbol/rpix/issues/118)).
- rpix’s questions, when it offers to install Pixi or to build a package
  from source, say what will happen, then offer a numbered menu
  ([\#104](https://github.com/roaldarbol/rpix/issues/104)).

### Fixed

- `pixi_add_environment(default_feature = FALSE)` adds
  `conda-ecosystem-user-package-isolation` to an environment with R,
  which keeps the personal R library out, as
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  does for the default feature. Before, such an environment, e.g. with
  another version of R, could load packages built for another R, and
  crash.
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  adds it too when it adds R to the default feature without it, and
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  reports environments with R that lack it, e.g. after editing
  `pixi.toml` by hand
  ([\#160](https://github.com/roaldarbol/rpix/issues/160)).
- “Coming from renv” no longer says that packages from GitHub aren’t
  available, and that only a few CRAN packages aren’t on conda-forge: it
  says that Pixi can build them from source
  ([\#161](https://github.com/roaldarbol/rpix/issues/161)).
- [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
  [`pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md),
  [`pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  and
  [`pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  notice when Pixi skips a package’s install script, which
  Bioconductor’s annotation and data packages (such as org.Hs.eg.db) use
  to download their data. They offer to allow these scripts in the
  project, and otherwise warn. Before, such packages were added without
  their data, and didn’t load. Committing `.pixi/config.toml` allows the
  scripts for everyone who uses the project, CI included
  ([\#142](https://github.com/roaldarbol/rpix/issues/142),
  [\#158](https://github.com/roaldarbol/rpix/issues/158)).
- The check matrix’s environments keep your personal R library out, as
  the default environment does. Without it, R could load packages built
  for your usual R, and crash
  ([\#112](https://github.com/roaldarbol/rpix/issues/112)).
- Packages built from source whose names have a dot, such as sym.arma,
  are written correctly into `pixi.toml`; Pixi couldn’t read them before
  ([\#120](https://github.com/roaldarbol/rpix/issues/120)).
- In a package,
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  adds `.pixi`, `pixi.toml` and `pixi.lock` to `.Rbuildignore`, and the
  IDE setup adds `.vscode`, so they stay out of the package’s builds.
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
  reports them when they’re missing
  ([\#114](https://github.com/roaldarbol/rpix/issues/114)).

## rpix 0.7.0 (2026-10-10)

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
