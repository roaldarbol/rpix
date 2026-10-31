# Install and update the project's packages

- `pixi_install()` installs an environment as `pixi.lock` describes it,
  e.g. after cloning a project. `pixi run` does this by itself, too. If
  `pixi.lock` is out of date with `pixi.toml`, Pixi updates it first,
  unless `locked` or `frozen` says otherwise.

- `pixi_update()` updates packages to the newest versions `pixi.toml`
  allows, in `pixi.lock`, and installs them.

- `pixi_upgrade()` updates packages beyond that, and raises the versions
  in `pixi.toml` to match. It leaves R as it is, unless `r = TRUE`.

- `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
  installing anything.

In an interactive session, `pixi_update()` and `pixi_upgrade()` first
show what would change, and ask before going ahead. Then they install
the environment this R runs in, or else the default one (or
`environment`). If that's this R's own environment, restart R
afterwards, as the packages it has loaded still use the old files: in
RStudio, they offer to. On Windows, a running R keeps Pixi from
replacing its packages' files, so there they only update `pixi.lock`,
and say how to install it after closing R.

Upgrading R (`r = TRUE`) means every R package needs a build for the new
R. conda-forge has fewer packages for a new version of R at first, and
packages built from source are pinned to the R they were added for, so R
only moves as far as all the project's packages allow.

Package names are translated like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md). If
Pixi skips an install script that a package needs, such as the ones
Bioconductor's data packages download their data with, these functions
offer to allow them in the project, as
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
does.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/install/>,
<https://pixi.prefix.dev/latest/reference/cli/pixi/update/>,
<https://pixi.prefix.dev/latest/reference/cli/pixi/upgrade/> and
<https://pixi.prefix.dev/latest/reference/cli/pixi/lock/>.

## Usage

``` r
pixi_install(
  environment = NULL,
  all = FALSE,
  locked = FALSE,
  frozen = FALSE,
  path = NULL,
  dry_run = FALSE
)

pixi_update(packages = NULL, environment = NULL, path = NULL, dry_run = FALSE)

pixi_upgrade(
  packages = NULL,
  feature = NULL,
  r = FALSE,
  path = NULL,
  dry_run = FALSE
)

pixi_lock(path = NULL, dry_run = FALSE)
```

## Arguments

- environment:

  Optional. The environment. Defaults to `default`.

- all:

  If `TRUE`, install all the project's environments.

- locked:

  If `TRUE`, fail if `pixi.lock` is out of date with `pixi.toml`, rather
  than updating it, e.g. to check that a collaborator or CI gets exactly
  what's committed.

- frozen:

  If `TRUE`, install exactly what `pixi.lock` says, without checking it
  against `pixi.toml`.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

- packages:

  Optional. Only update these packages. Defaults to all.

- feature:

  Optional. Only upgrade the packages of this feature.

- r:

  If `TRUE`, upgrade R too (`r-base`), as far as the project's packages
  allow. Naming `"r-base"` in `packages` does the same.

## Value

The command (invisibly) if `dry_run = TRUE`, otherwise the result of the
Pixi call (invisibly).

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

pixi_install(path = project, dry_run = TRUE)
#> ℹ Would run: `pixi install --manifest-path /tmp/RtmpSQ1q83/rpix-example/pixi.toml`
pixi_update("dplyr", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi update r-dplyr --manifest-path /tmp/RtmpSQ1q83/rpix-example/pixi.toml`
pixi_upgrade(path = project, dry_run = TRUE)
#> ℹ Would run: `pixi upgrade --exclude r-base --manifest-path /tmp/RtmpSQ1q83/rpix-example/pixi.toml`
```
