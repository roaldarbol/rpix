# Switch to another environment's R

Move your work to the R of another of the project's environments, e.g.
one with another version of R. A running R can't change its own version
or library, so this starts the other R the way your IDE needs:

- RStudio: starts a new RStudio with the environment's R, in the
  project. Close the old one when you're done with it.

- Positron: opens the interpreter picker, to pick the environment's R.

- VS Code: points the R extension at the environment's R, in the
  project's `.vscode/settings.json`. Reload the window to use it. On
  Windows, start VS Code from the environment instead.

- Elsewhere: shows the command that starts the environment's R.

The environment is installed first, if it isn't yet.

## Usage

``` r
pixi_switch(environment, ide = NULL, path = NULL)
```

## Arguments

- environment:

  The environment.

- ide:

  Optional. The IDE: `"rstudio"`, `"positron"` or `"vscode"`. Defaults
  to the one you're in.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The environment's R, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_switch("r44")
} # }
```
