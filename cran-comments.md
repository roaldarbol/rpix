## Submission

This is a new submission.

rpix is an R interface to Pixi (<https://pixi.prefix.dev>), a package manager
for conda packages: it sets up a project's R and packages from conda-forge,
records them in a lock file, and works with that project from the R console.

## Test environments

* GitHub Actions: R CMD check on macOS, Windows and Ubuntu (R release; Ubuntu
  also R-devel and oldrel-1), and with Pixi installed (the newest Pixi, and
  0.77, the oldest rpix supports).
* GitHub Actions: `R CMD check --as-cran` on Ubuntu (R release), with
  `NOT_CRAN=false` and without Pixi, as on CRAN's machines.
* Local, macOS (Intel), R 4.5: `R CMD check --as-cran` with CRAN's incoming
  checks, without Pixi on the `PATH`.
* win-builder: R-devel (2026-10-18 r90707 ucrt) and R 4.6.1, Windows.
* macOS builder: R 4.6.1, macOS 26.6 (Apple Silicon).
* R-hub: Linux, Windows and macOS (Apple Silicon) with R-devel, and the
  `nosuggests` and `clang-asan` checks.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

The macOS builder and R-hub report no notes. win-builder also flagged the
package's name, "rpix", as possibly misspelled in the Description; it's now
in single quotes, like the other names there.

## Pixi, an external program

Pixi is in `SystemRequirements`, as `pixi (>= 0.77)`: the name of its
executable and of its package in conda-forge and other package managers, so
tools that map `SystemRequirements` to system packages can match it. 0.77 is
the first Pixi that can build packages with the build backend rpix uses; a CI
job checks rpix with it. rpix doesn't need Pixi
to install or load. On a machine without it, its functions say how to install
it, and `install_pixi()` installs it.

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
settings such as `.vscode/settings.json`, `.envrc` and `.jupyter/kernels/`.
Examples and tests only write in `tempdir()`.

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

## RStudio and Positron

rpix has RStudio addins and a New Project template (in `inst/rstudio`). In
RStudio, a few functions call RStudio's own API functions (`.rs.api.*`, from
the `tools:rstudio` environment, as rstudioapi does, so rpix doesn't depend
on it): to read the editor's selection, show a prompt, or restart R after
the project's packages are updated, which the user is asked about first.
`pixi_switch()` uses Positron's `.ps.ui.executeCommand()` the same way.
Outside these IDEs, and outside interactive sessions, none of this runs.

## Questions at startup

The project's `.Rprofile` (written by `use_pixi()`) calls `pixi_activate()`.
In an interactive session, it may ask a question, such as whether to reopen
the project in RStudio with the project's own R. It never asks in a
non-interactive session, and `RPIX_OFFER_SWITCH=false` turns the question
off. Loading or attaching rpix by itself never asks anything.

## Network

Examples and tests don't use the network on CRAN. Functions that do (Pixi
itself, `install_pixi()`, `pixi_search()`, and installing rpix from GitHub
with `options(rpix.ref)`) only do so when the user calls them.
