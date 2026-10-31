# Set up a Pixi project for R

Create a Pixi project in the working directory, or `path`, if there
isn't one there, and install R and rpix into its environment.

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

A new project supports Linux, macOS (Intel and Apple Silicon) and
Windows, as well as this computer's platform, so collaborators on any of
them can install it. `pixi.lock` then covers each of them, so a package
can only be added if it's on conda-forge for all of them; for one that
isn't, see `platform` in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

In a package, it adds `.pixi`, `pixi.toml` and `pixi.lock` to
`.Rbuildignore`, so they stay out of the package's builds.

In a project that uses renv (with a `renv.lock`), it offers to move the
packages over with
[`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
first, which also turns renv off. renv keeps rpix out of the project's
own R, so run `use_pixi(path = )` from another R session, e.g. your
usual R outside the project.

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
  platforms = NULL,
  python = FALSE,
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
  `"positron"`, `"vscode"`, `"emacs"`, `"neovim"` and `"zed"` (see
  [use_pixi_ide](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)),
  and `"jupyter"` (see
  [`use_pixi_jupyter()`](https://roald-arboel.com/rpix/reference/use_pixi_jupyter.md),
  experimental).

- init_if_missing:

  If `TRUE`, create a Pixi project if there isn't one.

- install_rpix:

  If `TRUE`, add rpix to the project (`r-rpix`), so it's in `pixi.lock`
  like the other packages, and a collaborator's environment has it too.
  Until rpix is on conda-forge, it comes from the
  [rpix-forge](https://prefix.dev/channels/rpix-forge) channel, which is
  added to the project's channels after conda-forge, so everything else
  still comes from conda-forge.

- date:

  Optional. Use packages as they were on this date, such as
  `"2025-06-01"`, e.g. to rerun an old analysis. Set before anything is
  added, so R and the packages are all as of that date. See
  [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md).

- path:

  The folder to set up. Defaults to the working directory.

- activation_cache:

  If `TRUE`, turn on Pixi's activation cache for the project.

- platforms:

  The platforms a new project supports, besides this computer's.
  Defaults to `"linux-64"`, `"osx-64"`, `"osx-arm64"` and `"win-64"`. To
  add platforms to an existing project, use
  [`pixi_add_platform()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md).

- python:

  If `TRUE`, add Python for reticulate, with
  [`use_pixi_python()`](https://roald-arboel.com/rpix/reference/use_pixi_python.md)
  (experimental).

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
