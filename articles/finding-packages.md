# Finding packages

Pixi installs conda packages. The most used CRAN packages, and nearly
all of Bioconductor, are available as conda packages on
[conda-forge](https://conda-forge.org) and
[bioconda](https://bioconda.github.io), under slightly different names,
and Pixi can build most others from source. rpix translates the names
for you. For the numbers, see [How many packages you can
use](https://roald-arboel.com/rpix/articles/package-availability.md).

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
- **Bioconductor packages** come from the bioconda channel, which rpix
  adds to the project the first time you need it. When a package isn’t
  on conda-forge,
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  looks for it on bioconda, so `pixi_add("DESeq2")` works. Use a
  `bioc::` prefix to say so up front, e.g. when a name exists on both.
  Bioconductor’s annotation and data packages, such as org.Hs.eg.db,
  download their data when they’re installed, with a script that Pixi
  only runs in projects that allow it.
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  offers to allow it.
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

library(rpix)

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

If it really isn’t available, Pixi can build it from source.
(Experimental: this may still change, see
[\#96](https://github.com/roaldarbol/rpix/issues/96).) Pixi’s R build
backend,
[`pixi-build-r`](https://pixi.prefix.dev/latest/build/backends/pixi-build-r/),
builds a package from its GitHub repository, and its dependencies come
from conda-forge:

``` r

pixi_add("github::user/mypackage")
```

Add `@ref` for a branch, tag or commit,
e.g. `"github::user/mypackage@v1.2.0"`, or give it in `versions`, as
`pixi_add("github::user/mypackage", versions = "v1.2.0")`. `pixi.lock`
records the exact commit either way, so collaborators get the same code.
CRAN packages are on GitHub too, in [CRAN’s
mirror](https://github.com/cran), with a tag for every version. When
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
can’t find a CRAN package on conda-forge, it offers to build it from
there; or add it yourself:

``` r

pixi_add("github::cran/mypackage@1.2.3")
```

rpix writes the package into `pixi.toml`, turns on Pixi’s `pixi-build`
preview, and builds it for the project’s version of R. It asks for
`pixi-build-r` 0.2.0 or later, which adds the Rust, CMake, pkg-config
and R’s recommended packages (such as Matrix and MASS) that a package
needs. rpix adds what `pixi-build-r` doesn’t: Java, when the package’s
`SystemRequirements` names it, and in a project for Windows, what builds
there need. A project with packages as of a date before 2026-10-15 can’t
get that `pixi-build-r` (see
[`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)).
Building takes a minute or so. It doesn’t work yet for packages that
need Bioconductor packages, or system libraries such as GDAL.

Better still, add the package to conda-forge, so it’s available for
everyone. conda-forge accepts new packages through
[staged-recipes](https://github.com/conda-forge/staged-recipes).
[rattler-build](https://rattler.build) writes a recipe for a CRAN
package for you:

``` sh
pixi exec rattler-build generate-recipe cran mypackage
```
