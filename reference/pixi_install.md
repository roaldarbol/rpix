# Install and update the project's packages

- `pixi_install()` installs an environment as `pixi.lock` describes it,
  e.g. after cloning a project. `pixi run` does this by itself, too. If
  `pixi.lock` is out of date with `pixi.toml`, Pixi updates it first,
  unless `locked` or `frozen` says otherwise.

- `pixi_update()` updates packages to the newest versions `pixi.toml`
  allows, in `pixi.lock`.

- `pixi_upgrade()` updates packages beyond that, and raises the versions
  in `pixi.toml` to match.

- `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
  installing anything.

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

pixi_upgrade(packages = NULL, feature = NULL, path = NULL, dry_run = FALSE)

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
#> ℹ Would run: `pixi install --manifest-path /tmp/RtmpfmLctB/rpix-example/pixi.toml`
pixi_update("dplyr", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi update r-dplyr --manifest-path /tmp/RtmpfmLctB/rpix-example/pixi.toml`
pixi_upgrade(path = project, dry_run = TRUE)
#> ℹ Would run: `pixi upgrade --manifest-path /tmp/RtmpfmLctB/rpix-example/pixi.toml`
```
