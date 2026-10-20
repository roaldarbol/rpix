# Sharing and reproducibility

A Pixi project records everything it needs, including R itself, in two
files. Share those, and anyone can recreate the environment.

## What to commit

- **Commit `pixi.toml`**: the packages you asked for, with any version
  constraints.
- **Commit `pixi.lock`**: the exact version of every package, including
  the ones they depend on, for every platform the project supports.
- **Don’t commit `.pixi/`**: the installed environment. `pixi init` (and
  so
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md))
  adds it to `.gitignore`.

## Recreate the environment

On another computer, get the project, and install its environment from
R:

``` r

library(rpix)

pixi_install(path = "path/to/project")
```

Then open the project in your IDE (see [Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.md)). From a terminal,
`pixi install` does the same, and `pixi run R` installs the environment
if needed, then starts R.

If `pixi.toml` has changed since `pixi.lock` was written, Pixi updates
the lock file first. To install exactly what’s in the lock file instead,
use `pixi_install(frozen = TRUE)`. Or use `pixi_install(locked = TRUE)`,
which stops if the lock file is out of date.

Some packages finish installing with a script, which Pixi only runs in
projects that allow it. Bioconductor’s annotation and data packages,
such as org.Hs.eg.db, download their data that way. The setting is in
`.pixi/config.toml`, which `pixi init` leaves out of `.gitignore`.
Commit it to allow the scripts for everyone who uses the project, CI
included. Otherwise, allow them on each computer:
[`pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
offers to, or run
`pixi config set --local run-post-link-scripts insecure`. `pixi.lock`
pins these packages, but not the data the script downloads.

## Platforms

`pixi.lock` covers every platform listed in `pixi.toml`, under
`platforms`.
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
creates a project for Linux, macOS (Intel and Apple Silicon) and
Windows, `linux-64`, `osx-64`, `osx-arm64` and `win-64`, and for your
computer’s platform if it’s another one, so collaborators on any of them
can install it. Choose others with `use_pixi(platforms = )`, or add them
to an existing project:

``` r

pixi_add_platform(c("linux-64", "osx-64", "osx-arm64", "win-64"))
```

Every package then has to be on conda-forge for all of them. When one
isn’t,
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) says
for which platform, and adds nothing. You can add it only for the
platforms that have it, one at a time,
e.g. `pixi_add("Rmpi", platform = "linux-64")`, though code that uses it
then doesn’t run on the others. Or remove the platform with
[`pixi_remove_platform()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md).

Packages from GitHub are built on each computer that installs them, so
the first install takes longer there. Pixi brings what the build needs,
on every platform the project has.

## Updating packages

Packages stay at the versions in `pixi.lock` until you update them:

``` r

pixi_update()
```

This updates to the newest versions `pixi.toml` allows.
[`pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
also raises the version constraints in `pixi.toml`. Both show what would
change first, and ask.

[`pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
leaves R as it is. A new version of R means a new build of every R
package, and conda-forge has fewer packages for a new R at first, so
upgrading R is a step of its own: `pixi_upgrade(r = TRUE)`.

If you update from the project’s own R, restart R afterwards, as the
packages it has loaded still use the old files; in RStudio, rpix offers
to. On Windows, R keeps Pixi from replacing the files of packages it has
loaded, so there rpix only updates `pixi.lock`, and says how to install
it once R is closed.

## Packages as of a date

Pixi can leave out every package published after a date, so a project
gets packages as they were on that day. That’s useful to rerun an old
analysis with the versions it was written for, without its lock file, or
to check that a package still works with what users had a year ago. Set
the date when you create the project, so R and every package you add are
as of that day:

``` r

use_pixi(date = "2025-06-01")
```

In an existing project,
[`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)
sets it and updates `pixi.lock` to match. That fails when the project
pins versions newer than the date, which
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) does
for what it adds; `pixi.toml` is then left as it was.

A duration leaves out only the newest releases, e.g. those from the last
week, in case one turns out to be broken or compromised:

``` r

pixi_set_date("7d")
```

Only packages that were on conda-forge at the time are available. The
date applies to Pixi’s build backend as well, so packages built from
source (`pixi_add("github::...")`) need a date after the backend’s
release, or a duration. `pixi_set_date(NULL)` removes the date.

## Tasks

Save the commands that run the project as tasks in `pixi.toml`, so
collaborators run them the same way:

``` r

pixi_add_task("analysis", "Rscript analysis.R", description = "Run the analysis")
pixi_add_task("report", "quarto render report.qmd", depends_on = "analysis")
```

Then anyone can run them, from R:

``` r

pixi_run("report")
```

or from a terminal, with `pixi run report`.

`report` runs `analysis` first.
[`pixi_tasks()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
lists a project’s tasks.

## Continuous integration

[`use_pixi_github_action()`](https://roald-arboel.com/rpix/reference/use_pixi_github_action.md)
writes a GitHub Actions workflow that installs the project’s
environments exactly as `pixi.lock` records them, with the
[setup-pixi](https://github.com/prefix-dev/setup-pixi) action, so CI
runs with the same R and packages as your computer:

``` r

use_pixi_github_action("task", task = "report")   # run a Pixi task, e.g. render a report
use_pixi_github_action("check")                   # R CMD check, for a package
```

For a package, `"check"` runs r-lib’s `check-r-package` on Linux, macOS
and Windows (those of the project’s platforms), in each environment that
has rcmdcheck and the package’s dependencies, `Suggests` included,
e.g. those from
[`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md).
`"test-coverage"` and `"pkgdown"` do what r-lib’s workflows of the same
name do, in the first environment that has what they need. Name the
environments with `environments =`; rpix warns about any that lack
something, and says how to add it. Pixi is pinned to the version you
have, and the run fails if `pixi.lock` is out of date with `pixi.toml`,
so commit both.
