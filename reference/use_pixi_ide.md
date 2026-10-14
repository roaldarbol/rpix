# Set up an IDE for a Pixi project

Set an IDE up to use the R in the project's Pixi environment.
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
calls these with its `ide` argument.

- `use_pixi_rstudio()` adds, or replaces, an `rstudio` task in
  `pixi.toml`, for each of the project's platforms, that starts a new
  RStudio with the environment's R and the project's `.Rproj` file. It
  creates the `.Rproj` file if there isn't one. Start RStudio with
  `pixi run rstudio`.

- `use_pixi_positron()` turns on Positron's discovery of R in Pixi
  environments, and makes the default environment's R Positron's default
  for the project, in `.vscode/settings.json`. Positron (2026.10 or
  later) then starts that R when the project opens, until you pick
  another R there. The path is for the operating system you run it on;
  on another one, Positron ignores it.

- `use_pixi_vscode()` adds languageserver, and the console if it isn't
  R, to the environment. It points the R extension for VS Code (and
  VSCodium) at the environment's R and the console, in
  `.vscode/settings.json`. On Windows, the environment's R only starts
  when the environment is activated, so it leaves R and the console to
  be found on the `PATH` instead: start VS Code with `pixi run code .`.

Existing settings in `.vscode/settings.json` are kept. In a package,
`.vscode` is added to `.Rbuildignore`.

## Usage

``` r
use_pixi_rstudio(path = NULL)

use_pixi_positron(path = NULL, default_r = TRUE)

use_pixi_vscode(path = NULL, console = c("R", "arf", "radian"))
```

## Arguments

- path:

  The project. Defaults to the working directory.

- default_r:

  For `use_pixi_positron()`: if `TRUE`, make the default environment's R
  Positron's default for the project.

- console:

  For `use_pixi_vscode()`: the R console, `"R"`,
  [`"arf"`](https://github.com/eitsupi/arf) or
  [`"radian"`](https://github.com/randy3k/radian).

## Value

The file they changed, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_rstudio()
use_pixi_positron()
use_pixi_vscode(console = "arf")
} # }
```
