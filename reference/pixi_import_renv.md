# Move a project from renv

Add the packages in a project's `renv.lock` to its Pixi project, and
turn renv off.

- Packages from CRAN, or another CRAN-like repository, are looked up on
  conda-forge, and Bioconductor packages on bioconda. Packages from
  GitHub or elsewhere, and packages that aren't on conda-forge or
  bioconda, are left out, and listed.

- By default only the packages that no other package in the lock file
  needs are added, so `pixi.toml` lists what the project uses, rather
  than everything those packages need too.

- The lock file's version of R becomes a constraint on R, if the project
  doesn't have R yet.

renv's `.Rprofile` line, `source("renv/activate.R")`, makes R use renv's
library, so `deactivate = TRUE` removes it, like
[`renv::deactivate()`](https://rstudio.github.io/renv/reference/activate.html).
`renv.lock` and the `renv` folder stay; delete them when you no longer
need them.

## Usage

``` r
pixi_import_renv(
  lockfile = NULL,
  versions = c("minimum", "exact", "none"),
  all = FALSE,
  deactivate = TRUE,
  path = NULL,
  dry_run = FALSE
)
```

## Arguments

- lockfile:

  Optional. The lock file. Defaults to the project's `renv.lock`.

- versions:

  How to use the lock file's versions:

  - `"minimum"`: at least that version, e.g. `>=1.1.4`.

  - `"exact"`: that version, e.g. `==1.1.4`, if it's on conda-forge, and
    at least that version if it isn't.

  - `"none"`: the newest versions.

- all:

  If `TRUE`, add every package in the lock file, including those that
  are only there because other packages need them.

- deactivate:

  If `TRUE`, remove renv's line from the project's `.Rprofile`.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

## Value

A list with the package specs added (`packages`), and the packages left
out because they aren't from a repository (`not_from_repository`) or
weren't found (`missing`), invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_import_renv()
pixi_import_renv(versions = "exact")
} # }
```
