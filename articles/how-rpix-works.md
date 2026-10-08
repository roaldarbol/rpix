# How rpix works

## An environment has its own R

A Pixi environment is a folder, `.pixi/envs/default/` in your project.
It holds everything the project needs: R itself, the R packages, and the
system libraries those packages use, such as GDAL or libxml2. They all
come from [conda-forge](https://conda-forge.org) and are built to work
together.

So a Pixi project doesn’t use the R you normally use. It uses the R in
its environment, with that R’s package library. Different projects can
use different versions of R, side by side.

## Start R through Pixi

`pixi run R` starts the environment’s R. Before it does, Pixi
*activates* the environment: it sets up environment variables that some
packages need, such as where GDAL finds its data.

IDEs need to be pointed at the environment’s R; see [Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.md).

## When an IDE starts R directly

Positron and VS Code start the environment’s R themselves, without Pixi,
so the environment isn’t activated.
[`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
adds a few lines to the project’s `.Rprofile` that make up for that.
When R starts, they:

1.  Remove your personal library from
    [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) (see below),
    before any package loads.
2.  Call
    [`rpix::pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md),
    which sets the environment variables Pixi would have set, and adds
    the project’s own library.

In R that isn’t from the project’s environment,
[`pixi_activate()`](https://roald-arboel.com/rpix/reference/pixi_activate.md)
changes nothing, and tells you how to start the right R instead.

On Windows, the environment’s R can’t start at all without activation,
so start the IDE through Pixi there; see [Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.html#on-windows-start-the-ide-through-pixi).

## Why rpix doesn’t change `.libPaths()`

You can’t safely point an R you already have running at a Pixi
environment’s library. Packages with compiled code are built for one
particular R and set of system libraries. Loaded into a different R,
they can crash it, often only when you load the package.

Earlier versions of rpix did this, from the `.Rprofile`.
[`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
removes that setup from projects that still have it.

## Keep your personal library out

conda-forge’s R also looks in your personal package library, and even
looks there first. That’s the one your usual R installs into, such as
`~/Library/R/x86_64/4.5/library` on macOS, or
`%LOCALAPPDATA%/R/win-library/4.5` on Windows. So packages built for
your usual R can be loaded into the environment’s R. This is a
[long-standing issue in conda-forge’s
R](https://github.com/conda-forge/r-base-feedstock/issues/37).

[`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
points `R_LIBS_USER` at a folder inside the project instead, in
`pixi.toml`:

``` toml
[activation.env]
R_LIBS_USER = "$PIXI_PROJECT_ROOT/.pixi/r-libs/$PIXI_ENVIRONMENT_NAME"

[target.win.activation.env]
R_LIBS_USER = "%PIXI_PROJECT_ROOT%\\.pixi\\r-libs\\%PIXI_ENVIRONMENT_NAME%"
```

Windows needs the second entry, because it only expands `%VAR%`.
[`setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
adds it if the project lists a Windows platform; if you add one later,
add the entry too. R ignores a library folder that doesn’t exist, so
this leaves only the environment’s own library.

Pixi applies this when it starts R, as `pixi run R` does, and the
project’s `.Rprofile` takes care of it when an IDE starts R directly.
Check with:

``` r

.libPaths()
```

## What rpix runs

Each rpix function runs a Pixi command, and shows it:

``` r

pixi_add("dplyr")
#> ℹ Running `pixi add r-dplyr --manifest-path pixi.toml`
```

So you can always do the same in a terminal, and learn Pixi along the
way. With `dry_run = TRUE`, rpix shows the command without running it.

rpix finds the project from the working directory, looking upwards for a
`pixi.toml`. In R started by Pixi, it uses that R’s project instead.
