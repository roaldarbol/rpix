# Add channels or platforms to the project

- `pixi_add_channel()` adds conda channels, which packages are installed
  from.
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  adds the ones it needs itself.

- `pixi_add_platform()` adds platforms, such as `"linux-64"`,
  `"osx-arm64"` or `"win-64"`, so `pixi.lock` covers them too and
  collaborators on them get the same packages.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/channel/add/>
and
<https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/platform/add/>.

## Usage

``` r
pixi_add_channel(channels, path = NULL, dry_run = FALSE)

pixi_add_platform(platforms, path = NULL, dry_run = FALSE)
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
if (FALSE) { # \dontrun{
pixi_add_channel("bioconda")
pixi_add_platform(c("linux-64", "osx-arm64", "win-64"))
} # }
```
