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

- If R isn't the R of a Pixi environment in this project, nothing
  changes; in an interactive session you get a hint instead.

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
