# Set up a pixi project for R

Create a pixi project in the working directory if there isn't one, add R
to it, and install rpix into its environment.

It can be run from any R. Afterwards, work in R started by pixi: run
`pixi run R` in a terminal, or point your IDE at the environment's R
(see <https://roald-arboel.com/rpix/articles/ide.html>). Each pixi
environment has its own R and package library, so rpix doesn't point a
running R at a pixi library: packages built for a different R can crash
it.

Projects set up with rpix 0.3.0 or earlier have a "Pixi R library setup"
block in their `.Rprofile`, which did exactly that. It's removed.

## Usage

``` r
setup_pixi(r_version = NULL, init_if_missing = TRUE, install_rpix = TRUE)
```

## Arguments

- r_version:

  Optional. The R version to add, such as `"4.5"`. Defaults to the
  latest on conda-forge.

- init_if_missing:

  If `TRUE`, create a pixi project if there isn't one.

- install_rpix:

  If `TRUE`, install rpix into the project's environment. Its
  dependencies come from conda-forge, and rpix itself from R-universe
  until it's on conda-forge.

## Value

The path to the project's manifest, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
setup_pixi()
setup_pixi(r_version = "4.5")
} # }
```
