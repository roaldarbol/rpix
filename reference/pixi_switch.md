# Switch to another environment's R

Move your work to the R of another of the project's environments, e.g.
one with another version of R. A running R can't change its own version
or library, so this starts the other R the way your IDE needs:

- RStudio: starts a new RStudio with the environment's R, in the
  project. Close the old one when you're done with it.

- Positron: looks for interpreters again, and opens the interpreter
  picker, to pick the environment's R.

- VS Code, and editors based on it: points the R extension at the
  environment's R, in the project's `.vscode/settings.json`, keeping its
  console (R, arf or radian; see
  [`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)).
  Reload the window to use it. On Windows, start the editor from the
  environment instead.

- Emacs, Neovim and Zed: points the project's `.envrc` at the
  environment (see
  [`use_pixi_direnv()`](https://roald-arboel.com/rpix/reference/use_pixi_direnv.md)).
  Reload direnv in the editor, and restart R. On Windows, start the
  editor from the environment instead.

- Elsewhere: shows the command that starts the environment's R.

The environment is installed first, if it isn't yet.

## Usage

``` r
pixi_switch(environment = NULL, ide = NULL, path = NULL)
```

## Arguments

- environment:

  The environment. In an interactive session, leave it out to pick one
  from a menu.

- ide:

  Optional. The IDE: `"rstudio"`, `"positron"`, `"vscode"`, `"emacs"`,
  `"neovim"` or `"zed"`. Defaults to the one you're in.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The environment's R, invisibly, or `NULL` if you cancel the menu.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_switch("r44")
# Pick from a menu
pixi_switch()
} # }
```
