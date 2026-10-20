# Activate the project's environment with direnv

Write a `.envrc` file that activates the project's Pixi environment with
[direnv](https://direnv.net) whenever you're in the project's folder: in
a shell with direnv's hook, and in editors that load direnv, such as
Emacs, Neovim and Zed (see
[`use_pixi_emacs()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)).
R, languageserver and anything else started there then come from the
environment.

If the project has a `.envrc` already, its other lines are kept. direnv
only loads a `.envrc` you've allowed, and again after it changes: in an
interactive session, `use_pixi_direnv()` offers to allow it. Install
direnv with `pixi global install direnv`. In a package, `.envrc` is
added to `.Rbuildignore`.

## Usage

``` r
use_pixi_direnv(path = NULL, environment = "default")
```

## Arguments

- path:

  The project. Defaults to the working directory.

- environment:

  The environment to activate.

## Value

The `.envrc` file, invisibly.

## Examples

``` r
# A throwaway Pixi project in R's temporary folder, so the examples leave
# yours alone. With `dry_run = TRUE`, rpix shows the Pixi command it would run.
project <- file.path(tempdir(), "rpix-example")
dir.create(project, showWarnings = FALSE)
writeLines(
  c(
    "[workspace]",
    'name = "rpix-example"',
    'channels = ["conda-forge"]',
    'platforms = ["linux-64", "osx-arm64", "win-64"]',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'conda-ecosystem-user-package-isolation = "*"'
  ),
  file.path(project, "pixi.toml")
)

use_pixi_direnv(path = project)
#> ✔ Set .envrc to activate the "default" environment.
#> ℹ Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
use_pixi_direnv(path = project, environment = "r44")
#> ✔ Set .envrc to activate the "r44" environment.
#> ℹ Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
```
