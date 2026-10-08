# Set up an IDE for a Pixi project

Set an IDE up to use the R in the project's Pixi environment.
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
calls these with its `ide` argument.

- `use_pixi_rstudio()` adds an `rstudio` task to `pixi.toml`, for each
  of the project's platforms, that starts a new RStudio with the
  environment's R and the project's `.Rproj` file. It creates the
  `.Rproj` file if there isn't one. Start RStudio with
  `pixi run rstudio`.

- `use_pixi_positron()` turns on Positron's discovery of R in Pixi
  environments, in `.vscode/settings.json`. Pick the project's R ("R
  (Pixi: default)") once in Positron's interpreter picker; Positron
  activates the environment when it starts R.

- `use_pixi_vscode()` adds languageserver to the environment, and points
  the R extension for VS Code (and VSCodium) at the environment's R, in
  `.vscode/settings.json`. On Windows, the environment's R only starts
  when the environment is activated, so it leaves R to be found on the
  `PATH` instead: start VS Code with `pixi run code .`.

Existing settings in `.vscode/settings.json` are kept.

## Usage

``` r
use_pixi_rstudio(path = NULL)

use_pixi_positron(path = NULL)

use_pixi_vscode(path = NULL)
```

## Arguments

- path:

  The project. Defaults to the working directory.

## Value

The file they changed, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_rstudio()
use_pixi_positron()
use_pixi_vscode()
} # }
```
