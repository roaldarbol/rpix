# Use packages as they were on a date

Make Pixi leave out every package published after a date, with the
project's `exclude-newer` setting. The project then gets packages as
they were on that day, like a snapshot of a package repository: useful
to rerun an old analysis with the versions it was written for, or to
check that a package still works with what users had a year ago.
`pixi_set_date()` sets it, and updates `pixi.lock` to match.

A duration, such as `"7d"`, leaves out packages published in the last
week instead, e.g. to stay clear of a release that turns out to be
broken or compromised. `pixi_set_date(NULL)` removes the setting;
packages stay as they are until you update them with
[`pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md).

Only packages that were on conda-forge (or the project's other channels)
at the time are available, even if they were on CRAN then.

## Usage

``` r
pixi_set_date(date, path = NULL)
```

## Arguments

- date:

  A date, such as `"2025-06-01"` or `Sys.Date() - 365`, a timestamp
  (`"2025-06-01T12:00:00Z"`), or a duration, such as `"7d"`. `NULL`
  removes the setting.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The previous setting, or `NULL`, invisibly.

## Details

[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) pins
the versions it adds, so an existing project's pins may be newer than an
earlier date. Pixi then can't solve the project, and `pixi.toml` is left
as it was. Setting the date when you create the project, with
`use_pixi(date = )`, avoids that.

The date applies to Pixi's build backend too, so packages built from
source (`pixi_add("github::...")`) need a date after the backend's
release, or a duration.

See
<https://pixi.prefix.dev/latest/reference/pixi_manifest/#exclude-newer-optional>.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_set_date("2025-06-01")
pixi_set_date("7d")
pixi_set_date(NULL)
} # }
```
