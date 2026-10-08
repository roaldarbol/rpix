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

The [setup-pixi](https://github.com/prefix-dev/setup-pixi) action
installs Pixi and the environment on GitHub Actions:

``` yaml
steps:
  - uses: actions/checkout@v4
  - uses: prefix-dev/setup-pixi@v0.10.2
    with:
      cache: true
  - run: pixi run report
```

It uses `pixi install --locked` by default, so the run fails if
`pixi.lock` is out of date.
