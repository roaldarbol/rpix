# Search for packages

Show the available versions of a conda package and their dependencies.

The package name is translated like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md):
`"dplyr"` searches for `r-dplyr`, `"bioc::DESeq2"` for
`bioconductor-deseq2` on bioconda, and `"conda::gdal"` for `gdal`.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/search/>.

## Usage

``` r
pixi_search(package, channel = NULL, path = NULL, dry_run = FALSE)
```

## Arguments

- package:

  A package name.

- channel:

  Optional. A conda channel to search. Inside a project, the project's
  channels are searched by default, and conda-forge otherwise.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

## Value

The command (invisibly) if `dry_run = TRUE`, otherwise the result of the
Pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_search("tibble")
pixi_search("bioc::DESeq2")
pixi_search("conda::numpy", channel = "conda-forge")
} # }
```
