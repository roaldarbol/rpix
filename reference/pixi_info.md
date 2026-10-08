# Information about a Pixi project

- `pixi_info()` returns what `pixi info` reports: the Pixi version and
  platform, the project, and its environments with their features,
  platforms, channels, tasks and location.

- `pixi_list()` lists the packages installed in an environment.

- `pixi_tree()` shows which packages depend on which.

For more information, see
<https://pixi.sh/latest/reference/cli/pixi/info/>,
<https://pixi.sh/latest/reference/cli/pixi/list/> and
<https://pixi.sh/latest/reference/cli/pixi/tree/>.

## Usage

``` r
pixi_info(path = NULL)

pixi_list(environment = NULL, explicit = FALSE, path = NULL)

pixi_tree(packages = NULL, environment = NULL, invert = FALSE, path = NULL)
```

## Arguments

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- environment:

  Optional. The environment. Defaults to `default`.

- explicit:

  If `TRUE`, only list the packages in `pixi.toml`, not the ones they
  depend on.

- packages:

  Optional. Only show these packages, and what they depend on. Names are
  translated like in
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

- invert:

  If `TRUE`, show what depends on `packages` instead.

## Value

- `pixi_info()`: a list, as `pixi info --json` gives it.

- `pixi_list()`: a data frame with a row per package, and the columns
  `name`, `version`, `r_package` (the name of the R package, or `NA`),
  `explicit` (whether it's in `pixi.toml`), `channel` (its name, such as
  `conda-forge`), `kind` (`"conda"` or `"pypi"`) and `build`.

- `pixi_tree()`: the tree's lines, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_info()$environments_info$name
pixi_list(explicit = TRUE)
pixi_tree("dplyr")
} # }
```
