# Add dependencies

`add()` will add dependencies to the pixi.toml.

For more information, see
https://pixi.sh/latest/reference/cli/pixi/add/.

It will only add if the package with its version constraint is able to
work with rest of the dependencies in the project. More info on
[multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
configuration.

## Usage

``` r
add(packages, versions = NULL, channel = NULL, dry_run = FALSE)
```

## Arguments

- packages:

  Package name(s) to be added.

- versions:

  Optional. Version constraints for all packages.

- channel:

  Optional. Defaults to conda-forge, but other conda channels can be
  specified.

- dry_run:

  Should the command be executed? If TRUE, the final pixi command will
  be shown but not executed. FALSE (default) executes the command.

## Value

Doesn't return any objects.

## Examples

``` r
if (FALSE) { # \dontrun{
add("tibble")
} # }
```
