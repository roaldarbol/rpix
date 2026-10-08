# rpix

**rpix is currently in alpha. We don’t expect to support the entire pixi
CLI, but are open to implement useful features - feedback is welcome!**

## Overview

The **rpix** package provides an interface to manage dependencies with
[pixi](https://pixi.sh).

Each pixi environment has its own R and its own package library, so you
work in R started by pixi (e.g. `pixi run R`, or an IDE pointed at the
environment’s R) and manage its packages from there.
[`rpix::setup_pixi()`](https://roald-arboel.com/rpix/reference/setup_pixi.md)
sets a project up from any R.

## Installation

**rpix** depends on having **pixi** installed - so if you haven’t got it
yet, install pixi first.

- **Project template**. For a fully-fledged, ready-to-use R project,
  create a project with the
  [r-template](https://github.com/roaldarbol/r-template)
- **Add to existing project**. To add **rpix** to an existing pixi
  project: `pixi add r-rpix` (**THIS DOES NOT YET WORK, SEE
  [ISSUE](https://github.com/roaldarbol/rpix/issues/2)**)

``` r

install.packages(
  "rpix",
  repos = c("https://roaldarbol.r-universe.dev", "https://cloud.r-project.org")
)
```

## Resources

## How to use rpix

``` r

library(rpix)
```

The primary use of rpix is the ability to add dependencies in the
console like you normally would with `install.packages` or
[`renv::install`](https://rstudio.github.io/renv/reference/install.html).
With rpix, the command is
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).
Let’s try installing the **tidyverse**:

``` R
rpix::pixi_add("tidyverse")
```

------------------------------------------------------------------------

*Fun fact: rpix is a inspired by the Danish word **harpiks** which means
resin. I see it as the resin that binds pixi into the natural R
workflow.*
