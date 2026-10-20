# Python alongside R

**Experimental:** this may still change, see
[\#108](https://github.com/roaldarbol/rpix/issues/108).

A Pixi environment can have Python and its packages next to R and its
packages, in the same `pixi.lock`, so a collaborator gets the same
Python stack too. R uses it through
[reticulate](https://rstudio.github.io/reticulate/).

## Set it up

``` r

library(rpix)

use_pixi_python()
```

or, for a new project, `use_pixi(python = TRUE)`. This adds Python,
reticulate, and what reticulate needs to use the environment’s Python,
and points reticulate at it. Restart R afterwards.

Then add Python packages. Most are on conda-forge:

``` r

pixi_add("conda::numpy")
```

For those that aren’t, such as
[pydytuesday](https://pypi.org/project/pydytuesday/) (TidyTuesday’s
data, for Python), add them from PyPI:

``` r

pixi_add("pypi::pydytuesday")
```

Use them from R as usual:

``` r

numpy <- reticulate::import("numpy")
```

## What it sets up

- **`RETICULATE_PYTHON`,** in `pixi.toml`’s `[activation.env]`, points
  reticulate at the environment’s Python. Without it, reticulate makes a
  Python of its own, which doesn’t have the project’s packages. It
  applies to R started with `pixi run`, and to R started by an IDE,
  through the project’s `.Rprofile`.
- **`micromamba` and `RETICULATE_CONDA`:** reticulate activates a conda
  environment again before using its Python, with a conda program, which
  a Pixi project doesn’t have
  ([rstudio/reticulate#1650](https://github.com/rstudio/reticulate/issues/1650)).
  conda-forge’s micromamba does that.
- **`libpython`,** for Python 3.15 or later: conda-forge keeps Python’s
  shared library, which reticulate loads, in a package of its own.
- On Windows, the settings are written differently, as Pixi doesn’t
  expand `$CONDA_PREFIX` there. They’re only written if the project has
  `win-64`; if you add it later, run
  [`use_pixi_python()`](https://roald-arboel.com/rpix/reference/use_pixi_python.md)
  again.

## Things to know

- **`reticulate::py_require()` doesn’t install into the project’s
  Python:** add Python packages with
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  instead.
- **PyPI packages** are for what conda-forge doesn’t have: a package
  from conda-forge can bring the system libraries it needs, one from
  PyPI can’t. They need Python in the environment, and Pixi installs
  them with uv, next to the conda packages.
