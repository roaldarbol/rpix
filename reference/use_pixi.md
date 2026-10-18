# Set up a Pixi project for R

Create a Pixi project in the working directory, or `path`, if there
isn't one there, add R to it, and install rpix into its environment.

It sets up that folder even inside another Pixi project. If a parent
folder is a Pixi project, it says so, and in an interactive session asks
whether to set that one up instead.

It also adds conda-forge's `conda-ecosystem-user-package-isolation`,
which keeps your personal R library out of the environment's R.
Otherwise conda-forge's R loads packages installed for your usual R
first.

It can be run from any R. Afterwards, work in R started by Pixi: run
`pixi run R` in a terminal, or use an IDE set up with `ide` (see
<https://roald-arboel.com/rpix/articles/ide.html>). Each Pixi
environment has its own R and package library, so rpix doesn't point a
running R at a Pixi library: packages built for a different R can crash
it.

It also adds a block to the project's `.Rprofile` that calls
[`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md),
so the environment is activated when an IDE starts its R directly.
Projects set up with rpix 0.3.0 or earlier have a "Pixi R library setup"
block in their `.Rprofile` instead, which pointed a running R at the
Pixi library. It's removed.

In a package, it adds `.pixi`, `pixi.toml` and `pixi.lock` to
`.Rbuildignore`, so they stay out of the package's builds.

It turns on Pixi's activation cache for the project, in
`.pixi/config.toml`. Pixi then reuses the environment's activation until
the project changes, so R started through Pixi, e.g. by `pixi run` or
Positron, starts in a fraction of a second rather than a few. The cache
is experimental in Pixi, and doesn't notice changes outside the project,
e.g. a newly installed Java.

## Usage

``` r
use_pixi(
  r_version = NULL,
  ide = NULL,
  init_if_missing = TRUE,
  install_rpix = TRUE,
  date = NULL,
  path = NULL,
  activation_cache = TRUE,
  ...
)
```

## Arguments

- r_version:

  Optional. The R version to add, such as `"4.5"`. Defaults to the
  newest one that conda-forge has R packages for; it has a new R before
  its packages are built for it.

- ide:

  Optional. IDEs to set the project up for: any of `"rstudio"`,
  `"positron"`, `"vscode"`, `"emacs"`, `"neovim"` and `"zed"`. See
  [use_pixi_ide](https://roald-arboel.com/rpix/reference/use_pixi_ide.md).

- init_if_missing:

  If `TRUE`, create a Pixi project if there isn't one.

- install_rpix:

  If `TRUE`, install rpix into the project's environment, unless it has
  this version or a newer one. Its dependencies come from conda-forge,
  and rpix itself from R-universe until it's on conda-forge.

- date:

  Optional. Use packages as they were on this date, such as
  `"2025-06-01"`, e.g. to rerun an old analysis. Set before anything is
  added, so R and the packages are all as of that date. See
  [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md).

- path:

  The folder to set up. Defaults to the working directory.

- activation_cache:

  If `TRUE`, turn on Pixi's activation cache for the project.

- ...:

  Passed on to the IDE setup, e.g. `console = "arf"` for
  [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
  or `default_r = FALSE` for
  [`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md).

## Value

The path to the project's manifest, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi()
use_pixi(r_version = "4.5", ide = "positron")
use_pixi(ide = "vscode", console = "arf")
use_pixi(date = "2025-06-01")
} # }
```
