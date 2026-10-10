# Install Pixi

Install Pixi from R, with Pixi's official installer, so you don't need a
terminal. It installs Pixi into `~/.pixi/bin` (or `$PIXI_HOME/bin`),
where rpix finds it straight away. When an rpix function can't find
Pixi, it offers to run `install_pixi()`.

By default, the installer also adds Pixi to your shell's `PATH`, so
`pixi` works in a terminal too, after you open a new one. If Pixi is
installed already, nothing happens unless `force = TRUE`; update an
existing Pixi with `pixi self-update` in a terminal.

The installer is downloaded from <https://pixi.sh>. It may send
prefix.dev an anonymous install count; set `PIXI_NO_TELEMETRY=1` to turn
that off. See <https://pixi.prefix.dev/latest/installation/>.

## Usage

``` r
install_pixi(version = NULL, update_path = TRUE, force = FALSE)
```

## Arguments

- version:

  Optional. The version of Pixi, such as `"0.81.0"`. Defaults to the
  latest.

- update_path:

  If `TRUE`, let the installer add Pixi to your shell's `PATH`, e.g. in
  `~/.zshrc`. If `FALSE`, only rpix will find it.

- force:

  If `TRUE`, install even if Pixi is installed already.

## Value

The path to Pixi, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
install_pixi()
} # }
```
