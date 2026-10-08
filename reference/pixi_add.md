# Add packages

Add packages to the pixi manifest and install them. pixi only adds them
if they can be solved together with the rest of the project's
dependencies.

R package names are translated to conda names: `"dplyr"` becomes
`r-dplyr` and `"Rcpp"` becomes `r-rcpp` (conda names are lowercase). Use
a prefix to say where a package comes from:

- `"bioc::DESeq2"`: a Bioconductor package (`bioconductor-deseq2` from
  the bioconda channel, which is added to the project if needed).

- `"conda::gdal"`: a conda package that isn't an R package, used as is.
  Names containing `-` or `_`, such as `"c-compiler"`, are also used as
  is.

- `"cran::dplyr"`: same as `"dplyr"`.

For more information, see
<https://pixi.sh/latest/reference/cli/pixi/add/>.

## Usage

``` r
pixi_add(packages, versions = NULL, channel = NULL, dry_run = FALSE)
```

## Arguments

- packages:

  Package names. A version constraint can follow the name, as in
  `"dplyr>=1.1"`.

- versions:

  Optional. Version constraints, either one for all packages or one per
  package (use `NA` for no constraint). A version without an operator,
  such as `"1.1"`, means `1.1.*`.

- channel:

  Optional. A conda channel to install the packages from. It's added to
  the project's channels if it isn't there yet.

- dry_run:

  If `TRUE`, show the pixi commands without running them.

## Value

The commands (invisibly) if `dry_run = TRUE`, otherwise the result of
the pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_add("tibble")
pixi_add(c("dplyr>=1.1", "bioc::DESeq2", "conda::gdal"))
pixi_add("dplyr", versions = "1.1")
} # }
```
