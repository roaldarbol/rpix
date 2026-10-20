# Report on the project's Pixi setup

Check that R, its packages and the IDE use the project's Pixi
environment, and suggest fixes for what doesn't. It reports:

- Pixi: where it is, and its version.

- The project, and whether `pixi.lock` is up to date with `pixi.toml`.

- Whether the project was moved or copied: Pixi's activation cache then
  has the old location, so it's removed, and environments installed in
  the old location need reinstalling.

- The date the project's packages are as of, if it has one (see
  [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)).

- In a package, whether `pixi.toml` has what its `DESCRIPTION` needs:
  the `Depends`, `Imports` and `LinkingTo` packages in the default
  environment, the `Suggests` somewhere (e.g. a `test` environment), and
  installed versions at least the minimums `DESCRIPTION` asks for.

- In a package, whether `.Rbuildignore` leaves Pixi's files out of its
  builds.

- Environments with R that don't keep your personal R library out, e.g.
  ones that leave out the default feature.

- Private channels that refuse access, and the hosts Pixi has logins for
  (see
  [`pixi_auth_login()`](https://roald-arboel.com/rpix/reference/pixi_auth_login.md)).

- Whether the running R is the R of the project's environment, and
  whether the environment is activated.

- Libraries and loaded packages from outside the project, such as your
  personal library. R's base packages come with every R, so aren't
  listed.

- Packages in the environment that Pixi didn't install, e.g. with
  [`utils::install.packages()`](https://rdrr.io/r/utils/install.packages.html),
  so `pixi.toml` doesn't record them.

- Whether the project's `.Rprofile` activates the environment when an
  IDE starts R directly.

- Whether the IDE you're in is set up for the project: it runs the
  project's R, or is set up by
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md).
  If it's set up but runs another R, how to start the project's R in it.

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
# A throwaway Pixi project in R's temporary folder, so the examples leave
# yours alone. With `dry_run = TRUE`, rpix shows the Pixi command it would run.
project <- file.path(tempdir(), "rpix-example")
dir.create(project, showWarnings = FALSE)
writeLines(
  c(
    "[workspace]",
    'name = "rpix-example"',
    'channels = ["conda-forge"]',
    'platforms = ["linux-64", "osx-arm64", "win-64"]',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'conda-ecosystem-user-package-isolation = "*"'
  ),
  file.path(project, "pixi.toml")
)

pixi_sitrep(path = project)
#> 
#> ── Pixi ──
#> 
#> ✔ pixi 0.82.0 at /home/runner/.pixi/bin/pixi
#> 
#> ── Project ──
#> 
#> ✔ /tmp/RtmpfmLctB/rpix-example
#> ! pixi.lock isn't up to date with pixi.toml.
#>   Run `pixi install`.
#> 
#> ── R ──
#> 
#> ℹ R 4.5.3 at /home/runner/work/rpix/rpix/.pixi/envs/default/lib/R
#> ✖ This R is from another project's Pixi environment, in /home/runner/work/rpix/rpix.
#> ! Libraries from outside the project:
#> • /tmp/RtmpfmLctB/temp_libpatha3070578e07
#> • /home/runner/work/rpix/rpix/.pixi/envs/default/lib/R/library
#>   Packages built for another R can crash this one. See
#>   <https://roald-arboel.com/rpix/articles/how-rpix-works.html>.
#> ! Loaded from outside the project: R6, Rcpp, askpass, brio, bslib, cachem, callr, cli, curl, desc, devtools, digest, downlit, ellipsis, evaluate, fansi, fastmap, fontawesome, …, xopen, and yaml
#> ℹ .Rprofile doesn't activate the environment when an IDE starts R.
#>   Run `rpix::use_pixi()` to add it.
#> 
#> ── IDE ──
#> 
#> ℹ Not in RStudio, Positron, VS Code, Emacs, Neovim or Zed.
```
