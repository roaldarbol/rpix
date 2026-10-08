# Run a function in another environment's R

Call a function in the R of another Pixi environment, e.g. one with
another version of R, and get its result back, like
[`callr::r()`](https://callr.r-lib.org/reference/r.html). The function
runs in a new R process, started with `pixi run`, so it uses that
environment's R and packages; your current R is left alone.

The function and its arguments are copied to the new R, but not the
variables around it. Refer to packages with `::` or load them in the
function, and pass in what it needs as arguments.

## Usage

``` r
pixi_r(func, args = list(), environment = NULL, show = TRUE, path = NULL)
```

## Arguments

- func:

  A function.

- args:

  A list of arguments to call it with.

- environment:

  Optional. The environment. Defaults to `default`.

- show:

  If `TRUE`, show the function's output while it runs.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The function's result.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_r(function() R.version.string, environment = "r44")
pixi_r(function(x) packageVersion(x), list("dplyr"), environment = "r44")
} # }
```
