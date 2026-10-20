# Get started

This guide takes a project from nothing to something a collaborator can
run on their own computer. It assumes you know R, but not Pixi.

## Install rpix

Install rpix in the R you normally use:

``` r

install.packages(
  "rpix",
  repos = c("https://roaldarbol.r-universe.dev", "https://cloud.r-project.org")
)
```

## Install Pixi

Pixi is the tool that does the work; rpix lets you use it from R.
Install it from R:

``` r

rpix::install_pixi()
```

This runs Pixi’s official installer, and adds `pixi` to your terminal’s
`PATH` too. (Skip it, and rpix offers to install Pixi the first time it
needs it.) To install it in a terminal instead, see the [Pixi
installation guide](https://pixi.prefix.dev/latest/installation/).

## Set up a project

In R, make your project folder the working directory (an RStudio project
does this for you), then set the project up for your IDE:

``` r

rpix::use_pixi(ide = "positron")   # or "rstudio", "vscode", ...
```

This adds to your project:

- `pixi.toml`: the project’s dependencies, which you edit with rpix or
  Pixi.
- `pixi.lock`: the exact version of every package, for Linux, macOS and
  Windows. Pixi writes it; you don’t edit it.
- `.pixi/`: the environment itself, with R and all its packages. Git
  ignores it.

It also installs rpix into the environment, so you can use it there.

## Start R from the project’s environment

The environment has its own R, separate from the R you normally use (see
[How rpix
works](https://roald-arboel.com/rpix/articles/how-rpix-works.md) for
why). Work in that R from now on:

- **Positron and VS Code:** open the project folder.
  [`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
  pointed them at the environment’s R.
- **RStudio:** it picks its R when it starts, so run
  [`rpix::pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md)
  in it, which starts a new RStudio with the environment’s R, in the
  project.

[Using rpix with an IDE](https://roald-arboel.com/rpix/articles/ide.md)
has the details for each IDE. From a terminal, `pixi run R` in the
project folder starts the environment’s R too.

To check that you’re in the right R, look at where it lives. It should
be inside the project’s `.pixi` folder:

``` r

R.home()
#> [1] "/path/to/project/.pixi/envs/default/lib/R"
```

## Add packages

Add packages with
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
instead of
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html):

``` r

library(rpix)

pixi_add(c("dplyr", "ggplot2"))
```

[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
records the packages in `pixi.toml`, updates `pixi.lock`, and installs
them. In the environment’s R,
[`install.packages()`](https://rdrr.io/r/utils/install.packages.html)
does the same: it adds the packages with
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).
Then use them as usual:

``` r

library(dplyr)
```

Bioconductor packages are found on bioconda, or say so with a `bioc::`
prefix; conda packages that aren’t R packages take `conda::`. See
[Finding
packages](https://roald-arboel.com/rpix/articles/finding-packages.md).

To remove a package again:

``` r

pixi_remove("ggplot2")
```

To check that `pixi.toml` has every package your code uses, in `.R`
files and in `.qmd` and `.Rmd` documents:

``` r

pixi_scan()
```

It lists the packages that are missing, and adds them with
`pixi_scan(add = TRUE)`. It also lists packages your code never uses.

## Render documents

Quarto and R Markdown documents are rendered by R, so render them with
the environment’s R too. Add Quarto to the environment, and save the
command as a task, which
[`pixi_run()`](https://roald-arboel.com/rpix/reference/pixi_tasks.md)
runs in the environment:

``` r

pixi_add("conda::quarto")
pixi_add_task("report", "quarto render report.qmd")
pixi_run("report")
```

The task is recorded in `pixi.toml`, so collaborators render the same
way. See
[Tasks](https://roald-arboel.com/rpix/articles/reproducibility.html#tasks).

## Check your setup

If something doesn’t work as expected, start with:

``` r

pixi_sitrep()
```

It checks that R, its packages and your IDE use the project’s
environment, and suggests fixes.

## Share the project

Commit `pixi.toml` and `pixi.lock`. A collaborator clones the project,
and installs its environment from their usual R, with rpix and Pixi
installed there:

``` r

library(rpix)

pixi_install(path = "path/to/project")
```

Pixi installs the same versions you have, from the lock file. Then they
open the project in their IDE, as above. (Without rpix, `pixi install`
in a terminal, in the project folder, does the same.) See [Sharing and
reproducibility](https://roald-arboel.com/rpix/articles/reproducibility.md)
for more, including other platforms and CI.

rpix is in the lock file too, as `r-rpix`, so the collaborator’s
environment has it. It isn’t on conda-forge yet, so until it is, it
comes from [rpix-forge](https://prefix.dev/roaldarbol/rpix-forge), a
channel
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md) adds
to the project after conda-forge: everything else still comes from
conda-forge. Other environments of the project may not have rpix. When R
starts in one of them, the project’s `.Rprofile` says so, with the
commands that add it:

``` sh
pixi workspace channel add https://prefix.dev/roaldarbol/rpix-forge
pixi add r-rpix
```
