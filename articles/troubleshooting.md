# Troubleshooting

Start with:

``` r

rpix::pixi_sitrep()
```

It checks the project’s setup, and suggests fixes for what’s wrong.

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

- **You’re in your usual R, not the environment’s.** Open the project in
  an IDE set up with `use_pixi(ide = )`, or in RStudio run
  [`rpix::pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md);
  see [Using rpix with an
  IDE](https://roald-arboel.com/rpix/articles/ide.md). From a terminal,
  `pixi run R`.
- **Your personal library is listed.** Keep it out of the environment;
  see [How rpix
  works](https://roald-arboel.com/rpix/articles/how-rpix-works.html#keep-your-personal-library-out).
- **The project’s `.Rprofile` changes
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).** rpix 0.3.0
  and earlier added a block starting with `# Pixi R library setup`.
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  removes it; for one in `~/.Rprofile`, remove it by hand.

## A package fails to load on Windows

`The specified procedure could not be found`, when R loads a compiled
package such as dplyr, means Windows found a DLL the package needs, but
an older copy, without a function it uses. Within an environment, that
happens when two packages install the same file, and the older copy
wins: conda-forge’s Strawberry Perl puts its own MinGW runtime
(`libstdc++-6.dll` and others) over conda-forge’s
([conda-forge/perl-feedstock#89](https://github.com/conda-forge/perl-feedstock/issues/89)).
freetds, and so pymssql, bring perl into an environment on Windows.

[`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
lists files that more than one package in an environment installs, and
says when it’s Strawberry Perl’s runtime. To see what brings perl in:

``` r

rpix::pixi_tree("perl", invert = TRUE)
```

Then drop that package, or move it to an environment without R (see
[Several
environments](https://roald-arboel.com/rpix/articles/environments.md)).

## RStudio uses the wrong R

RStudio picks its R when it starts, so it has to be started from the
project’s environment, as a new RStudio: set the project up with
[`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
then run
[`rpix::pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
in RStudio, which starts one (or `pixi run rstudio` in a terminal). See
[Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.html#rstudio).

## R doesn’t start in VS Code on Windows

On Windows, the environment’s R only starts when the environment is
activated. Start VS Code from the project’s environment, with
`pixi run code .`; for VSCodium, Cursor or Windsurf,
`pixi run codium .`, `pixi run cursor .` or `pixi run windsurf .`. See
[Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.html#vs-code).

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
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md).

## Still stuck?

Ask in [GitHub
Discussions](https://github.com/roaldarbol/rpix/discussions), or [open
an issue](https://github.com/roaldarbol/rpix/issues).
