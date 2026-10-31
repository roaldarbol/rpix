# Use Python alongside R, for reticulate

**Experimental.** This may change, see
<https://github.com/roaldarbol/rpix/issues/108>.

Add Python to the project's environment, and point reticulate at it, so
Python and its packages are in the same environment and `pixi.lock` as R
and its packages. It installs what it adds below into that environment.

- It adds `python` (at `python_version`, if given), `r-reticulate`, and
  for Python 3.15 or later `libpython`: conda-forge has Python's shared
  library, which reticulate loads, apart from Python since 3.15.

- It sets `RETICULATE_PYTHON` to the environment's Python, in
  `pixi.toml`'s `[activation.env]`, so R started with `pixi run` uses
  it, and so does R started by an IDE, through the project's `.Rprofile`
  ([`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)).
  Without it, reticulate uses a Python of its own.

- It adds `micromamba`, and points `RETICULATE_CONDA` to it: reticulate
  activates a conda environment again with a conda program before it
  uses its Python, and a Pixi project doesn't have one
  (<https://github.com/rstudio/reticulate/issues/1650>).

Add Python packages with
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md):
`pixi_add("conda::numpy")` from conda-forge, or
`pixi_add("pypi::pydytuesday")` from PyPI. reticulate's `py_require()`
doesn't install into the project's Python.

Restart R afterwards, so reticulate finds the environment's Python. The
Windows settings are written only if the project has `win-64`: if you
add it later, run `use_pixi_python()` again.

## Usage

``` r
use_pixi_python(python_version = NULL, path = NULL)
```

## Arguments

- python_version:

  Optional. The Python version, such as `"3.13"`. Defaults to the newest
  one that solves with the project.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The path to the project's manifest, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
# Needs Pixi, and adds Python to the project
use_pixi_python()
pixi_add(c("conda::numpy", "pypi::pydytuesday"))
} # }
```
