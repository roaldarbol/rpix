# Coming from renv

renv and Pixi solve the same problem: giving each project its own,
recorded set of packages. If you know renv, most of rpix will feel
familiar.

## What’s different

- **Pixi manages R itself**, and the system libraries packages need,
  such as GDAL. With renv, you install those yourself.
- **Packages come from conda-forge**, as binaries for every platform,
  rather than from CRAN. A few CRAN packages aren’t on conda-forge, and
  packages from GitHub aren’t available. See [Finding
  packages](https://roald-arboel.com/rpix/articles/finding-packages.md).
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
| [`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html) | `pixi install` in a terminal, or just `pixi run R` |
| [`renv::status()`](https://rstudio.github.io/renv/reference/status.html) | `pixi lock --check`, which fails if `pixi.lock` is out of date |
| [`renv::update()`](https://rstudio.github.io/renv/reference/update.html) | `pixi update`, within the versions `pixi.toml` allows, or `pixi upgrade` to raise those |
| `renv.lock` | `pixi.toml` and `pixi.lock` |

## Moving a project from renv

In a terminal, in the project’s folder, create a Pixi project, then let
rpix move the packages over and set the project up:

``` sh
pixi init
Rscript --no-init-file -e 'rpix::pixi_import_renv(); rpix::use_pixi()'
```

`--no-init-file` keeps renv from starting, so this runs in your usual R,
where rpix is installed.

[`pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md):

- adds the packages in `renv.lock` to `pixi.toml`, at least at their
  locked versions, with the lock file’s version of R. Use
  `versions = "exact"` for the locked versions themselves, where
  conda-forge has them.
- adds only the packages that nothing else in the lock file needs: the
  ones your project uses. Pixi installs what they need.
- lists packages it can’t add: those from GitHub, and those not on
  conda-forge or bioconda. They need [another
  route](https://roald-arboel.com/rpix/articles/finding-packages.html#when-a-package-isnt-on-conda-forge).
- turns renv off, by removing `source("renv/activate.R")` from
  `.Rprofile`. Delete `renv.lock` and the `renv` folder when you no
  longer need them.

Then start R with `pixi run R`, or set up your IDE (see [Using rpix with
an IDE](https://roald-arboel.com/rpix/articles/ide.md)).
