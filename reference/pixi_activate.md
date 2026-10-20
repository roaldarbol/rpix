# Activate the project's Pixi environment in the running R

Make R that was started directly from a Pixi environment, as IDEs such
as Positron and VS Code do, behave like R started with `pixi run R`.
Called from the project's `.Rprofile`, which
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md) sets
up.

- If Pixi didn't activate the environment, its environment variables are
  set, as `pixi shell-hook` reports them. Some packages need them, e.g.
  to find their data.

- Your personal library is removed from
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html), and the
  project's own library added if it exists. Other libraries, such as
  temporary ones that devtools adds, are kept.

- [`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
  adds packages with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  instead, so they're recorded in `pixi.toml` and `pixi.lock`. For a
  CRAN package that isn't on conda-forge,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  offers to build it from source. For a package already in `pixi.toml`,
  it says to update it with
  [`pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md)
  instead. `repos` is ignored, and other arguments Pixi can't use, such
  as `lib`, give an error. Package files and folders are installed with
  [`utils::install.packages()`](https://rdrr.io/r/utils/install.packages.html),
  so `pixi.toml` doesn't record them. Turn this off with
  `options(rpix.install_packages = FALSE)`.

- In a package, in an interactive session, rpix notices when
  `DESCRIPTION` comes to need packages that `pixi.toml` doesn't have,
  e.g. after
  [`usethis::use_package()`](https://usethis.r-lib.org/reference/use_package.html)
  or an edit, and offers to add them with
  [`pixi_import_description()`](https://roald-arboel.com/rpix/reference/pixi_import_description.md).
  It also says when `DESCRIPTION` no longer lists a package, which you
  can remove with
  [`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md).
  Turn this off with `options(rpix.watch_description = FALSE)`.

- If R isn't the R of a Pixi environment in this project, nothing
  changes; in an interactive session you get a hint instead.

- If the project was moved or copied, Pixi's activation cache, which has
  the old location, is removed, and environments that need reinstalling
  are named.

It never fails: problems are reported as messages.

## Usage

``` r
pixi_activate(path = getwd(), quiet = !interactive())
```

## Arguments

- path:

  The project. Defaults to the working directory, which is where R reads
  `.Rprofile` from.

- quiet:

  If `TRUE`, show no messages.

## Value

A list, invisibly: `activated` is `TRUE` if environment variables were
set, and `lib_paths` the new library paths, or `NULL` if they weren't
changed.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_activate()
} # }
```
