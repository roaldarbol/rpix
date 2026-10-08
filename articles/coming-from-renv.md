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

1.  Keep a copy of the lock file, then turn renv off for the project.
    `clean = TRUE` also deletes renv’s files, including `renv.lock`:

    ``` r

    file.copy("renv.lock", "renv-old.lock")
    renv::deactivate(clean = TRUE)
    ```

2.  Set the project up with Pixi:

    ``` r

    rpix::use_pixi()
    ```

3.  Start R from the project’s environment, with `pixi run R`, and add
    the packages that were in the lock file:

    ``` r

    lock <- jsonlite::read_json("renv-old.lock")
    packages <- setdiff(names(lock$Packages), "renv")
    rpix::pixi_add(packages)
    ```

    This adds the latest versions. Packages renv only installed as
    dependencies of others get added too; you can remove them from
    `pixi.toml` afterwards. Packages from GitHub, or not on conda-forge,
    need [another
    route](https://roald-arboel.com/rpix/articles/finding-packages.html#when-a-package-isnt-on-conda-forge).
