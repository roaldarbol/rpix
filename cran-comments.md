## Submission

This is a new submission.

rpix is an R interface to Pixi (<https://pixi.prefix.dev>), a package manager
for conda packages: it sets up a project's R and packages from conda-forge,
records them in a lock file, and works with that project from the R console.

## Test environments

<!-- Fill in before submitting, from the runs of this version. -->

* GitHub Actions: R CMD check on macOS, Windows and Ubuntu (R release; Ubuntu
  also R-devel and oldrel-1), with Pixi installed.
* GitHub Actions: `R CMD check --as-cran` on Ubuntu (R release), with
  `NOT_CRAN=false` and without Pixi, as on CRAN's machines.
* win-builder (R-devel and release):
* macOS builder (R release):
* R-hub:

## R CMD check results

<!-- Fill in from the runs above. -->

0 errors | 0 warnings | 1 note

* This is a new submission.

## Pixi, an external program

Pixi is in `SystemRequirements`. rpix doesn't need it to load, and on a
machine without Pixi its functions say how to install it.

* **Tests** that need Pixi skip when it isn't installed (and on CRAN). The
  rest run without it.
* **Examples** run without Pixi where they can: they set up a small Pixi
  project in `tempdir()` and use `dry_run = TRUE`, which prints the Pixi
  command instead of running it. The examples in `\dontrun{}` need Pixi, and
  most would also download packages or change a project, so they can't run
  on CRAN.

## Writing files

rpix writes files only when the user calls a function that is meant to, and
only in the project folder it's given (`path`, by default the working
directory), as usethis does: `pixi.toml`, `.Rprofile`, `.gitignore`, and IDE
settings such as `.vscode/settings.json`. Examples and tests only write in
`tempdir()`.

`install_pixi()` installs Pixi with Pixi's official installer, into
`~/.pixi`, and by default lets the installer add it to the shell's `PATH`
(`update_path = FALSE` doesn't). It only runs when the user calls it, or
agrees to it in an interactive session, much like
`tinytex::install_tinytex()`.

## install.packages() in a Pixi project

In a Pixi project's R, rpix makes `install.packages()` add packages with Pixi,
so they are recorded in the project's `pixi.toml` and lock file. It does this
with `attach()`, putting an environment named `rpix:install` with its own
`install.packages()` in front of utils'. That only happens when the project's
`.Rprofile`, which `use_pixi()` writes, calls `pixi_activate()` in R started
from that project's Pixi environment. Loading or attaching rpix never changes
the search path, and `options(rpix.install_packages = FALSE)` turns it off.

## Network

Examples and tests don't use the network on CRAN. Functions that do (Pixi
itself, `install_pixi()`, `pixi_search()`, and installing rpix from GitHub
with `options(rpix.ref)`) only do so when the user calls them.
