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

On another computer, install Pixi, get the project, and run either:

``` sh
pixi install
pixi run R
```

`pixi install` only installs the environment. `pixi run R` installs it
if needed, then starts R.

If `pixi.toml` has changed since `pixi.lock` was written, Pixi updates
the lock file first. To install exactly what’s in the lock file instead,
use `pixi install --frozen`. Or use `pixi install --locked`, which stops
if the lock file is out of date.

Some packages finish installing with a script, which Pixi only runs in
projects that allow it. Bioconductor’s annotation and data packages,
such as org.Hs.eg.db, download their data that way. The setting is in
`.pixi/config.toml`, which isn’t committed, so allow it on each
computer:
[`pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
offers to, or run
`pixi config set --local run-post-link-scripts insecure`. `pixi.lock`
pins these packages, but not the data the script downloads.

## Platforms

`pixi.lock` covers every platform listed in `pixi.toml`, under
`platforms`. A new project lists only the platform it was created on.
Add the platforms your collaborators use:

``` sh
pixi workspace platform add linux-64 osx-arm64 osx-64 win-64
```

Every package then has to be available for all of them, which is worth
knowing before a collaborator finds out.

## Updating packages

Packages stay at the versions in `pixi.lock` until you update them:

``` sh
pixi update
```

This updates to the newest versions `pixi.toml` allows. `pixi upgrade`
also raises the version constraints in `pixi.toml`.

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

rpix::pixi_add_task("analysis", "Rscript analysis.R", description = "Run the analysis")
rpix::pixi_add_task("report", "quarto render report.qmd", depends_on = "analysis")
```

Then anyone can run them, from a terminal with `pixi run report`, or
from R:

``` r

rpix::pixi_run("report")
```

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
and Windows (those of the project’s platforms), and takes several
environments, e.g. those from
[`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md),
including the `minimum` one. `"test-coverage"` and `"pkgdown"` do what
r-lib’s workflows of the same name do. Pixi is pinned to the version you
have, and the run fails if `pixi.lock` is out of date with `pixi.toml`,
so commit both.
