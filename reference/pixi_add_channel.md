# Add or remove the project's channels and platforms

- `pixi_add_channel()` adds conda channels, which packages are installed
  from.
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  adds the ones it needs itself.

- `pixi_add_platform()` adds platforms, such as `"linux-64"`,
  `"osx-arm64"` or `"win-64"`, so `pixi.lock` covers them too and
  collaborators on them get the same packages.

- `pixi_remove_channel()` and `pixi_remove_platform()` remove them
  again, e.g. a platform no one uses, which Pixi then no longer solves
  for, or a channel the project no longer needs packages from.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/channel/>
and
<https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/platform/>.

## Usage

``` r
pixi_add_channel(channels, path = NULL, dry_run = FALSE)

pixi_add_platform(platforms, path = NULL, dry_run = FALSE)

pixi_remove_channel(channels, path = NULL, dry_run = FALSE)

pixi_remove_platform(platforms, path = NULL, dry_run = FALSE)
```

## Arguments

- channels:

  Channel names, such as `"bioconda"`, or URLs.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

- platforms:

  Platform names.

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

pixi_add_channel("bioconda", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi workspace channel add bioconda --manifest-path /tmp/RtmpnAxAUJ/rpix-example/pixi.toml`
pixi_add_platform("osx-64", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi workspace platform add osx-64 --manifest-path /tmp/RtmpnAxAUJ/rpix-example/pixi.toml`
```
