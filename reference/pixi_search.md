# Search for packages

Show the available versions of a conda package and their dependencies.

The package name is translated like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md):
`"dplyr"` searches for `r-dplyr`, `"bioc::DESeq2"` for
`bioconductor-deseq2` on bioconda, and `"conda::gdal"` for `gdal`. A
package that isn't on conda-forge is looked for on bioconda too, so
`"DESeq2"` works as well. An R package's name has to match exactly,
while Pixi also finds conda packages whose names contain the one
searched for.

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
# With `dry_run = TRUE`, rpix shows the Pixi command it would run
pixi_search("tibble", dry_run = TRUE)
#> ℹ Would run: `pixi search r-tibble --manifest-path /home/runner/work/rpix/rpix/pixi.toml`
pixi_search("bioc::DESeq2", dry_run = TRUE)
#> ℹ Would run: `pixi search bioconductor-deseq2 --channel bioconda --manifest-path /home/runner/work/rpix/rpix/pixi.toml`
pixi_search("conda::numpy", channel = "conda-forge", dry_run = TRUE)
#> ℹ Would run: `pixi search numpy --channel conda-forge --manifest-path /home/runner/work/rpix/rpix/pixi.toml`
```
