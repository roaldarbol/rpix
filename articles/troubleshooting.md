# Troubleshooting

## R crashes when loading a package

A crash (“segfault”, “R is aborting now”) while loading a package
usually means it was built for a different R than the one loading it.
Check which R you’re in, and where its packages come from:

``` r

R.home()
.libPaths()
```

[`R.home()`](https://rdrr.io/r/base/Rhome.html) should be inside the
project’s `.pixi/envs/` folder, and
[`.libPaths()`](https://rdrr.io/r/base/libPaths.html) shouldn’t list any
library outside it. If it does:

- **You’re in your usual R, not the environment’s.** Start R with
  `pixi run R`, or see [Using rpix with an
  IDE](https://roald-arboel.com/rpix/articles/ide.md).
- **Your personal library is listed.** Keep it out of the environment;
  see [How rpix
  works](https://roald-arboel.com/rpix/articles/how-rpix-works.html#keep-your-personal-library-out).
- **The project’s `.Rprofile` changes
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).** rpix 0.3.0
  and earlier added a block starting with `# Pixi R library setup`.
  [`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
  removes it; for one in `~/.Rprofile`, remove it by hand.

## RStudio uses the wrong R

RStudio picks its R when it starts, so it has to be started from the
project’s environment. See [Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.md).

## A package can’t be found

    ! Some packages couldn't be found.

The package may need a `bioc::` or `conda::` prefix, or it isn’t on
conda-forge. See [Finding
packages](https://roald-arboel.com/rpix/articles/finding-packages.md).

## rpix can’t find Pixi

    ! Could not find Pixi.

rpix looks for Pixi on the `PATH`, and then where the installer puts it,
`~/.pixi/bin`. If you installed it somewhere else, tell rpix where:

``` r

options(rpix.pixi_path = "/path/to/pixi")
```

## rpix can’t find the project

    ! Could not find a Pixi project.

rpix looks for `pixi.toml` in the working directory and the folders
above it. Change the working directory to your project, or set it up
with
[`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md).

## Still stuck?

Ask in [GitHub
Discussions](https://github.com/roaldarbol/rpix/discussions), or [open
an issue](https://github.com/roaldarbol/rpix/issues).
