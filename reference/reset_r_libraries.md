# Reset R library configuration

`reset_r_libraries()` resets R's library configuration to default
settings, removing any pixi-specific configurations. This is useful for
troubleshooting or when you want to stop using pixi-managed packages.

## Usage

``` r
reset_r_libraries(remove_from_rprofile = FALSE, global = FALSE)
```

## Arguments

- remove_from_rprofile:

  Logical. If TRUE, attempts to remove pixi setup from .Rprofile files.
  Default is FALSE.

- global:

  Logical. If TRUE and `remove_from_rprofile = TRUE`, removes from
  global ~/.Rprofile. Default is FALSE.

## Examples

``` r
if (FALSE) { # \dontrun{
# Reset library paths to default
reset_r_libraries()

# Reset and clean .Rprofile
reset_r_libraries(remove_from_rprofile = TRUE)
} # }
```
