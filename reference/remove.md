# Remove dependencies

`remove()` removes packages from the pixi manifest. Package names are
translated like in
[`add()`](https://roald-arboel.com/rpix/reference/add.md), so `"dplyr"`
removes `r-dplyr` and `"bioc::DESeq2"` removes `bioconductor-deseq2`.

For more information, see
<https://pixi.sh/latest/reference/cli/pixi/remove/>.

## Usage

``` r
remove(packages, dry_run = FALSE)
```

## Arguments

- packages:

  Package names.

- dry_run:

  If `TRUE`, show the pixi command without running it.

## Value

The command (invisibly) if `dry_run = TRUE`, otherwise the result of the
pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
remove("tibble")
} # }
```
