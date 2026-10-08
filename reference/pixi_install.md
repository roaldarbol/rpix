# Install and update the project's packages

- `pixi_install()` installs an environment as `pixi.lock` describes it,
  e.g. after cloning a project. `pixi run` does this by itself, too.

- `pixi_update()` updates packages to the newest versions `pixi.toml`
  allows, in `pixi.lock`.

- `pixi_upgrade()` updates packages beyond that, and raises the versions
  in `pixi.toml` to match.

- `pixi_lock()` updates `pixi.lock` to match `pixi.toml`, without
  installing anything.

Package names are translated like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/install/>,
<https://pixi.prefix.dev/latest/reference/cli/pixi/update/>,
<https://pixi.prefix.dev/latest/reference/cli/pixi/upgrade/> and
<https://pixi.prefix.dev/latest/reference/cli/pixi/lock/>.

## Usage

``` r
pixi_install(environment = NULL, all = FALSE, path = NULL, dry_run = FALSE)

pixi_update(packages = NULL, environment = NULL, path = NULL, dry_run = FALSE)

pixi_upgrade(packages = NULL, feature = NULL, path = NULL, dry_run = FALSE)

pixi_lock(path = NULL, dry_run = FALSE)
```

## Arguments

- environment:

  Optional. The environment. Defaults to `default`.

- all:

  If `TRUE`, install all the project's environments.

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
if (FALSE) { # \dontrun{
pixi_install()
pixi_update("dplyr")
pixi_upgrade()
} # }
```
