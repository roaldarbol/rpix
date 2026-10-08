# Find packages the project's code uses

Look through the project's R code for the packages it uses, and compare
them with the packages in `pixi.toml`:

- Packages the code uses, but that aren't in `pixi.toml`.

- R packages in the default environment that the code never uses.

It reads `.R` files, and the R chunks of `.qmd` and `.Rmd` files, and
finds [`library()`](https://rdrr.io/r/base/library.html),
[`require()`](https://rdrr.io/r/base/library.html),
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html),
[`loadNamespace()`](https://rdrr.io/r/base/ns-load.html) and `pkg::fun`.
It skips the `.pixi`, `renv`, `docs` and `.git` folders. It also finds
`pkg::fun` in the commands of the project's Pixi tasks, such as
`Rscript -e 'devtools::test()'`.

A package that only other packages need doesn't count as unused if it's
in `pixi.toml` on purpose, so check before removing one. rpix and the
packages it needs aren't listed as unused.

## Usage

``` r
pixi_scan(add = FALSE, path = NULL)
```

## Arguments

- add:

  If `TRUE`, add the missing packages that are on conda-forge or
  bioconda.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

A list, invisibly, with:

- `used`: a data frame with a row per package the code uses, and the
  columns `package` and `files` (a list of the files that use it).

- `missing`: the packages the code uses that aren't in `pixi.toml`.

- `unused`: the R packages in the default environment the code doesn't
  use, as conda names.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_scan()
pixi_scan(add = TRUE)
} # }
```
