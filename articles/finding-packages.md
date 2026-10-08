# Finding packages

Pixi installs conda packages. Most CRAN and Bioconductor packages are
available as conda packages on [conda-forge](https://conda-forge.org)
and [bioconda](https://bioconda.github.io), under slightly different
names. rpix translates the names for you.

## Package names

| You write                   | Conda package         | Channel     |
|-----------------------------|-----------------------|-------------|
| `"dplyr"`                   | `r-dplyr`             | conda-forge |
| `"Rcpp"`                    | `r-rcpp`              | conda-forge |
| `"bioc::DESeq2"`            | `bioconductor-deseq2` | bioconda    |
| `"conda::gdal"`             | `gdal`                | conda-forge |
| `"r-dplyr"`, `"c-compiler"` | unchanged             | conda-forge |

- **CRAN packages** get an `r-` prefix and are lowercased, since conda
  package names are lowercase.
- **Bioconductor packages** take a `bioc::` prefix. They come from the
  bioconda channel, which rpix adds to the project the first time you
  need it.
- **Conda packages that aren’t R packages**, such as GDAL or Quarto,
  take a `conda::` prefix. Names containing `-` or `_` can’t be R
  package names, so they’re used as they are.

The same names work in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md),
[`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
and
[`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md).

## Search

[`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md)
shows the available versions of a package and what they depend on:

``` r

pixi_search("dplyr")
pixi_search("bioc::DESeq2")
```

You can also browse [conda-forge on
prefix.dev](https://prefix.dev/channels/conda-forge).

## Versions

Add a version constraint after the name:

``` r

pixi_add("dplyr>=1.1")
pixi_add("ggplot2==3.5.1")
```

Or give them separately, with `NA` for no constraint:

``` r

pixi_add(c("dplyr", "tidyr"), versions = c(">=1.1", NA))
```

A version without an operator, like `"1.1"`, means any `1.1.x`.

## Other channels

To install from a different conda channel, name it. rpix adds it to the
project’s channels:

``` r

pixi_add("mypackage", channel = "my-channel")
```

## When a package isn’t on conda-forge

If [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
can’t find a package, first check the name with
[`pixi_search()`](https://roald-arboel.com/rpix/reference/pixi_search.md),
and whether it needs `bioc::` or `conda::`.

If it really isn’t available, you can add it to conda-forge, so it’s
available for everyone. conda-forge accepts new packages through
[staged-recipes](https://github.com/conda-forge/staged-recipes).
[rattler-build](https://rattler.build) writes a recipe for a CRAN
package for you:

``` sh
pixi exec rattler-build generate-recipe cran mypackage
```

As a last resort,
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
works in the environment’s R. But the package isn’t recorded in
`pixi.toml` or `pixi.lock`, so collaborators won’t get it, and packages
with compiled code need compilers in the environment.
