
<p style="text-align:center;">

<img style="padding-bottom: 20px; padding-top: 20px;" src="man/figures/logo.png" alt="rpix logo">
</p>

<!-- badges: start -->

![License](https://img.shields.io/badge/license-MIT-blue)
<img src="https://github.com/roaldarbol/rpix/workflows/R-CMD-check/badge.svg">
[![Project
Chat](https://img.shields.io/discord/1082332781146800168.svg?label=&logo=discord&logoColor=ffffff&color=7389D8&labelColor=6A7EC2)](https://discord.gg/kKV8ZxyzY4)
[![Pixi
Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)

<!-- badges: end -->

**rpix is currently in alpha. We don’t expect to support the entire pixi
CLI, but are open to implement useful features - feedback is welcome!**

## Overview

The **rpix** package provides an interface to manage dependencies with
[pixi](https://pixi.sh).

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
install.packages('devtools')
devtools::install_github('roaldarbol/rpix')
```

## Resources

## How to use rpix

``` r
library(rpix)
```

The primary use of rpix is the ability to add dependencies in the
console like you normally would with `install.packages` or
`renv::install`. With rpix, the command is `add`. Let’s try installing
the **tidyverse**:

    rpix::add("tidyverse")

------------------------------------------------------------------------

*Fun fact: rpix is a inspired by the Danish word **harpiks** which means
resin. I see it as the resin that binds pixi into the natural R
workflow.*
