# Remove packages

Remove packages from the Pixi manifest. Package names are translated
like in
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md):
`"dplyr"` removes `r-dplyr` and `"bioc::DESeq2"` removes
`bioconductor-deseq2`. `"DESeq2"` removes `bioconductor-deseq2` too,
when that's what the manifest has, as
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md) adds
it.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/remove/>.

## Usage

``` r
pixi_remove(
  packages,
  feature = NULL,
  platform = NULL,
  type = NULL,
  path = NULL,
  dry_run = FALSE
)
```

## Arguments

- packages:

  Package names.

- feature:

  Optional. The feature to add the packages to, rather than the default
  one. See
  [`pixi_add_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md).

- platform:

  Optional. Only add the packages for this platform, such as
  `"linux-64"`.

- type:

  Optional. In a package, also remove the packages from this field of
  `DESCRIPTION`, such as `"Imports"` or `"SystemRequirements"`, and
  packages from GitHub from `Remotes`.

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
# A throwaway Pixi project in R's temporary folder, so the examples leave
# yours alone. With `dry_run = TRUE`, rpix shows the Pixi command it would run.
project <- file.path(tempdir(), "rpix-example")
dir.create(project, showWarnings = FALSE)
writeLines(
  c(
    "[workspace]",
    'name = "rpix-example"',
    'channels = ["conda-forge"]',
    'platforms = ["linux-64", "osx-arm64", "win-64"]',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'conda-ecosystem-user-package-isolation = "*"'
  ),
  file.path(project, "pixi.toml")
)

pixi_remove("tibble", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi remove r-tibble --manifest-path /tmp/RtmpZ95YIq/rpix-example/pixi.toml`
```
