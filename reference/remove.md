# Remove dependencies

`remove()` will remove dependencies from the pixi.toml.

For more information, see
https://pixi.sh/latest/reference/cli/pixi/remove/

## Usage

``` r
remove(packages, dry_run = FALSE)
```

## Arguments

- packages:

  Package name(s) to be removed.

- dry_run:

  Just show command or also run.

## Value

The command (invisibly) if `dry_run = TRUE`, otherwise the result of the
pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
remove("tibble")
} # }
```
