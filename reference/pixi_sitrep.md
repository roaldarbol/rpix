# Report on the project's Pixi setup

Check that R, its packages and the IDE use the project's Pixi
environment, and suggest fixes for what doesn't. It reports:

- Pixi: where it is, and its version.

- The project, and whether `pixi.lock` is up to date with `pixi.toml`.

- Private channels that refuse access, and the hosts Pixi has logins for
  (see
  [`pixi_auth_login()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md)).

- Whether the running R is the R of the project's environment, and
  whether the environment is activated.

- Libraries and loaded packages from outside the project, such as your
  personal library.

- Packages in the environment that Pixi didn't install, e.g. with
  [`utils::install.packages()`](https://rdrr.io/r/utils/install.packages.html),
  so `pixi.toml` doesn't record them.

- Whether the project's `.Rprofile` activates the environment when an
  IDE starts R directly.

- Whether the IDE you're in is set up for the project: it runs the
  project's R, or is set up by
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md).

## Usage

``` r
pixi_sitrep(path = NULL)
```

## Arguments

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

A list with what it found, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_sitrep()
} # }
```
