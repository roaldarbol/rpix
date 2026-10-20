# Set up an IDE for a Pixi project

Set an IDE or editor up to use the R in the project's Pixi environment.
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
calls these with its `ide` argument.

- `use_pixi_rstudio()` adds, or replaces, an `rstudio` task in
  `pixi.toml` that starts a new RStudio with the environment's R and the
  project's `.Rproj` file, on Linux, macOS and Windows (`linux-64`,
  `osx-64`, `osx-arm64` and `win-64`). Pixi adds any of those platforms
  the project doesn't have. It creates the `.Rproj` file if there isn't
  one. Start RStudio with `pixi run rstudio`.

- `use_pixi_positron()` turns on Positron's discovery of R in Pixi
  environments, and makes the default environment's R Positron's default
  for the project, in `.vscode/settings.json`. Positron (2026.10 or
  later) then starts that R when the project opens, until you pick
  another R there. The path is for the operating system you run it on;
  on another one, Positron ignores it.

- `use_pixi_vscode()` adds languageserver, the R extension's sess (how
  it talks to R) and jgd (its plots), and the console if it isn't R, to
  the environment. sess and jgd come from
  <https://prefix.dev/roaldarbol/rpix-forge> until they're on
  conda-forge; it's added to the project's channels after conda-forge.
  It points the R extension for VS Code, and the editors based on it
  such as VSCodium, Cursor and Windsurf, at the environment's R and the
  console, in `.vscode/settings.json`. On Windows, the environment's R
  only starts when the environment is activated, so it leaves R and the
  console to be found on the `PATH` instead: start VS Code with
  `pixi run code .` (or `codium`, `cursor` or `windsurf` instead of
  `code`).

- `use_pixi_emacs()`, `use_pixi_neovim()` and `use_pixi_zed()` add
  languageserver to the environment, and a `.envrc` that activates the
  environment with direnv (see
  [`use_pixi_direnv()`](https://roald-arboel.com/rpix/reference/use_pixi_direnv.md)).
  The editor, or the shell it starts from, then finds the environment's
  R and languageserver on the `PATH`: Emacs with its envrc package,
  Neovim from a shell with direnv's hook or with a direnv plugin, and
  Zed by itself. On Windows, start the editor from the environment
  instead, e.g. with `pixi run nvim`.

In an interactive session, `use_pixi_vscode()` asks which console to
use, unless `console` is given. Otherwise it keeps the console already
set up, or R.

Existing settings in `.vscode/settings.json` are kept. In a package,
`.vscode` is added to `.Rbuildignore`.

## Usage

``` r
use_pixi_rstudio(path = NULL)

use_pixi_positron(path = NULL, default_r = TRUE)

use_pixi_vscode(path = NULL, console = NULL)

use_pixi_emacs(path = NULL)

use_pixi_neovim(path = NULL)

use_pixi_zed(path = NULL)
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
  [`"radian"`](https://github.com/randy3k/radian). `NULL` asks.

## Value

The file they changed, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_rstudio()
use_pixi_positron()
use_pixi_vscode(console = "arf")
use_pixi_neovim()
} # }
```
