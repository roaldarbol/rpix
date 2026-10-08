# Setup pixi environment safely

`setup_pixi()` provides a complete pixi setup for R projects. It checks
for pixi availability, initializes a pixi project if needed, and
configures R to use pixi-managed packages. The function prioritizes
safety and uses .libPaths() instead of environment variables to avoid
shared library conflicts.

## Usage

``` r
setup_pixi(add_to_rprofile = TRUE, global = FALSE, init_if_missing = TRUE)
```

## Arguments

- add_to_rprofile:

  Logical. If TRUE, adds the pixi library configuration to .Rprofile for
  persistence across sessions. Default is FALSE.

- global:

  Logical. If TRUE and `add_to_rprofile = TRUE`, adds to global
  ~/.Rprofile instead of project-local .Rprofile. Default is FALSE.

- init_if_missing:

  Logical. If TRUE, runs `pixi init` if pixi.toml is not found. Default
  is TRUE.

## Value

Invisibly returns a list with the status of each setup step.

## Details

The function performs the following steps:

1.  Checks if pixi is available in PATH (adds it if not found)

2.  Checks for pixi.toml in project root (runs `pixi init` if not found)

3.  Configures R to use the pixi library as the primary package source

4.  Optionally adds the configuration to .Rprofile for persistence

Instead of setting environment variables (which can cause shared library
conflicts), this function modifies .libPaths() to prioritize the pixi
library.

## See also

[`.libPaths()`](https://rdrr.io/r/base/libPaths.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic setup - just configure for current session
setup_pixi()

# Full setup - add to .Rprofile for persistence
setup_pixi(add_to_rprofile = TRUE)

# Setup without auto-initializing pixi project
setup_pixi(init_if_missing = FALSE)
} # }
```
