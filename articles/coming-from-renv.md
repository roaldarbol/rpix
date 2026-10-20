# Coming from renv

renv and Pixi solve the same problem: giving each project its own,
recorded set of packages. If you know renv, most of rpix will feel
familiar.

## What’s different

- **Pixi manages R itself**, and the system libraries packages need,
  such as GDAL. With renv, you install those yourself.
- **Packages come from conda-forge**, as binaries for every platform,
  rather than from CRAN. The most used CRAN packages are there; for most
  of the others, and for packages from GitHub, Pixi can build them from
  source (experimental). See [Finding
  packages](https://roald-arboel.com/rpix/articles/finding-packages.md),
  and [How many packages you can
  use](https://roald-arboel.com/rpix/articles/package-availability.md).
- **Each environment has its own R.** You start R through Pixi rather
  than activating a library in the R you already have. See [How rpix
  works](https://roald-arboel.com/rpix/articles/how-rpix-works.md).
- **The lock file is always up to date.** There’s no snapshot step:
  adding or removing a package updates `pixi.lock`.

## renv’s functions in rpix

| renv | rpix or Pixi |
|----|----|
| [`renv::init()`](https://rstudio.github.io/renv/reference/init.html) | [`rpix::use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md) |
| `renv::install("dplyr")` | `rpix::pixi_add("dplyr")` |
| `renv::remove("dplyr")` | `rpix::pixi_remove("dplyr")` |
| [`renv::snapshot()`](https://rstudio.github.io/renv/reference/snapshot.html) | Not needed |
| [`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html) | [`rpix::pixi_install()`](https://roald-arboel.com/rpix/reference/pixi_install.md) |
| [`renv::status()`](https://rstudio.github.io/renv/reference/status.html) | [`rpix::pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md), which says when `pixi.lock` is out of date, or `rpix::pixi_install(locked = TRUE)`, which fails then |
| [`renv::update()`](https://rstudio.github.io/renv/reference/update.html) | [`rpix::pixi_update()`](https://roald-arboel.com/rpix/reference/pixi_install.md), within the versions `pixi.toml` allows, or [`rpix::pixi_upgrade()`](https://roald-arboel.com/rpix/reference/pixi_install.md) to raise those |
| `renv.lock` | `pixi.toml` and `pixi.lock` |

## Moving a project from renv

renv keeps rpix out of the project’s own R, so set the project up from
another R session, e.g. your usual R outside the project.
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
notices `renv.lock`, and offers to move the packages over first:

``` r

rpix::use_pixi(path = "~/myproject")
#> ℹ This project uses renv ('renv.lock').
#> ? Would you like to move its packages to Pixi, and turn renv off?
#> 1: Yes
#> 2: No
```

Yes runs
[`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md),
which:

- adds the packages in `renv.lock` to `pixi.toml`, at least at their
  locked versions, with the lock file’s version of R. Use
  `versions = "exact"` for the locked versions themselves, where
  conda-forge has them.
- adds only the packages that nothing else in the lock file needs: the
  ones your project uses. Pixi installs what they need.
- adds packages from GitHub too, built from source at the commit
  `renv.lock` records, and offers to build CRAN packages that aren’t on
  conda-forge from source (see [When a package isn’t on
  conda-forge](https://roald-arboel.com/rpix/articles/finding-packages.html#when-a-package-isnt-on-conda-forge)).
  Building from source is experimental, so it says which packages it
  built.
- lists packages it can’t add: those in a subfolder of a GitHub
  repository, from other sources such as GitLab, and those that aren’t
  on conda-forge or bioconda and can’t be built.
- turns renv off, by removing `source("renv/activate.R")` from
  `.Rprofile`. Delete `renv.lock` and the `renv` folder when you no
  longer need them.

Then open the project in your IDE, set up with `use_pixi(ide = )` (see
[Using rpix with an
IDE](https://roald-arboel.com/rpix/articles/ide.md)).

For other options, e.g. the locked versions themselves, answer no, and
run `rpix::pixi_import_renv(versions = "exact", path = "~/myproject")`
afterwards.
