# Remove packages

Remove packages from the Pixi manifest. Package names are translated
like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md):
`"dplyr"` removes `r-dplyr` and `"bioc::DESeq2"` removes
`bioconductor-deseq2`.

For more information, see
<https://pixi.sh/latest/reference/cli/pixi/remove/>.

## Usage

``` r
pixi_remove(packages, dry_run = FALSE)
```

## Arguments

- packages:

  Package names.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

## Value

The command (invisibly) if `dry_run = TRUE`, otherwise the result of the
Pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_remove("tibble")
} # }
```
