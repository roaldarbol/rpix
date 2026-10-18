# Move a project from renv

Add the packages in a project's `renv.lock` to its Pixi project, and
turn renv off.

- Packages from CRAN, or another CRAN-like repository, are looked up on
  conda-forge, and Bioconductor packages on bioconda. CRAN packages that
  aren't on conda-forge can be built from CRAN's source instead
  (experimental): `pixi_import_renv()` offers to, or if it can't ask,
  lists them with the command that does. Other packages that aren't on
  conda-forge or bioconda are left out, and listed.

- Packages from GitHub (experimental) are built from source at the
  commit `renv.lock` records, as `pixi_add("github::user/repo@commit")`
  does. With `versions = "none"`, they're built from the newest commit
  of the branch it records. Packages in a subfolder of a repository, and
  packages from elsewhere, are left out, and listed.

- By default only the packages that no other package in the lock file
  needs are added, so `pixi.toml` lists what the project uses, rather
  than everything those packages need too. Packages from GitHub are
  added either way, as conda-forge doesn't have them.

- The lock file's version of R becomes a constraint on R, if the project
  doesn't have R yet. If conda-forge doesn't have the packages for that
  R, e.g. a new R it hasn't built packages for yet, it says so and uses
  the newest R that has them.

It says which packages Pixi builds from source, as building them is
experimental; see
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md).

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

A list, invisibly, with the package specs added (`packages`), the
packages built from source (`from_source`), and the packages left out
because rpix can't add them from where they came (`not_from_repository`)
or they weren't found (`missing`).

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_import_renv()
pixi_import_renv(versions = "exact")
} # }
```
