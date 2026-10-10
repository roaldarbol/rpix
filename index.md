# rpix

*Manage R project dependencies with Pixi*

rpix lets you use [Pixi](https://pixi.prefix.dev) from R. Pixi installs
R itself, R packages and the system libraries they need (such as GDAL)
from [conda-forge](https://conda-forge.org) into an environment inside
your project. It records the exact versions in a lock file, so the
project runs the same on every computer.

## Installation

Install rpix in the R you normally use, then let it install
[Pixi](https://pixi.prefix.dev/latest/installation/):

``` r

install.packages(
  "rpix",
  repos = c("https://roaldarbol.r-universe.dev", "https://cloud.r-project.org")
)
rpix::install_pixi()
```

## Example

Set up the project in the working directory, for your IDE. This creates
a Pixi project, adds R to it, installs rpix into its environment, and
points the IDE at that R:

``` r

rpix::use_pixi(ide = "positron") # or "rstudio", or "vscode"
```

From then on, work in R started by Pixi: in your IDE (see [Using rpix
with an IDE](https://roald-arboel.com/rpix/articles/ide.html)), or with
`pixi run R` in a terminal in the project folder. Add and remove
packages from there:

``` r

library(rpix)

pixi_add(c("dplyr", "ggplot2"))
pixi_add("bioc::DESeq2")
pixi_remove("ggplot2")
```

[`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
checks the setup, and suggests fixes if something’s off.

To start a new project from a template instead, see
[r-template](https://github.com/roaldarbol/r-template).

## Learn more

- [Get
  started](https://roald-arboel.com/rpix/articles/getting-started.html):
  from installing Pixi to sharing a project.
- [How rpix
  works](https://roald-arboel.com/rpix/articles/how-rpix-works.html):
  why each environment has its own R.
- [Finding
  packages](https://roald-arboel.com/rpix/articles/finding-packages.html):
  CRAN, Bioconductor and other conda packages.
- [Several
  environments](https://roald-arboel.com/rpix/articles/environments.html):
  another version of R, or extra packages for tests.
- [Coming from
  renv](https://roald-arboel.com/rpix/articles/coming-from-renv.html):
  renv’s functions and their rpix counterparts.

## Getting help

Ask questions and share ideas in [GitHub
Discussions](https://github.com/roaldarbol/rpix/discussions), and report
bugs in the [issues](https://github.com/roaldarbol/rpix/issues). For
Pixi itself, ask on the [Discord of
prefix.dev](https://discord.com/invite/kKV8ZxyzY4), the makers of Pixi.

------------------------------------------------------------------------

*Fun fact: rpix is inspired by the Danish word **harpiks**, which means
resin. I see it as the resin that binds Pixi into the natural R
workflow.*
