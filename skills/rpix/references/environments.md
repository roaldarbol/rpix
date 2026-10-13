# Environments and features

Read this when a task needs another version of R, packages only for tests or development, environments kept on the same versions, or the IDE moved to another environment. The guide is [Several environments](https://roald-arboel.com/rpix/articles/environments.md); arguments are on the pages for `pixi_environments()`, `pixi_switch()` and `pixi_r()`, found through <https://roald-arboel.com/rpix/llms.txt>.

## The model

- A **feature** is a named set of packages. `pixi_add()` adds to the default feature; `pixi_add(..., feature = "test")` to another, which creates it.
- An **environment** is made of features, and includes the default feature unless told not to. Each has its own R and library, in `.pixi/envs/<name>/`.
- Environments in one **solve group** get the same versions of the packages they share. A test environment should share the default one's, so it tests what the project uses. Environments with different versions of R can't share a solve group.

## Recipes

Packages only for tests, on the same versions as the default environment:

```r
pixi_add("testthat", feature = "test")
pixi_add_environment("test", features = "test", solve_group = "default")
```

The feature has to exist before an environment can use it, so add its packages first.

Another version of R, next to the default environment's:

```r
pixi_add(c("r-base=4.4", "dplyr"), feature = "r44")
pixi_add_environment("r44", features = "r44", default_feature = FALSE)
```

`default_feature = FALSE` is needed because the default feature has its own R, and an environment can't have two. It also leaves out the default feature's `conda-ecosystem-user-package-isolation`, without which conda-forge's R loads packages from the user's personal library, built for another R. `pixi_add_environment()` adds it to the environment's first feature when the environment has R; an older rpix doesn't, so check with `pixi_sitrep()`, which reports environments with R that lack it, with the `pixi_add()` call that adds it. Write `no-default-feature = true` into `pixi.toml` by hand only with that check after. For a package's checks across R versions, `use_pixi_check_matrix()` does all this (see `package-development.md`).

## Using an environment

- Run its R, or a task in it: `pixi run -e r44 Rscript script.R`, `pixi run --environment test Rscript -e 'devtools::test()'`, `pixi run -e r44 <task>`.
- Run a function in it from another R, and get the result back: `pixi_r(function() R.version.string, environment = "r44")`. It starts a fresh R, so pass what the function needs in `args = list(...)`.
- Move the user's IDE to it: `pixi_switch("r44")`. RStudio gets a new RStudio with that R, Positron its interpreter picker (each environment is listed as "R x.y.z (Pixi: r44)"), VS Code new settings and a window reload. On Windows, VS Code has to be restarted from the environment instead: `pixi run -e r44 code .`.
- Install one or all: `pixi_install(environment = "r44")`, `pixi install --all`. `pixi run` installs an environment the first time it's used.
- List them, with their features: `pixi_environments()`, or `pixi info`.
- Remove one: `pixi_remove_environment("r44")`.

## Limits

- R-devel isn't on conda-forge.
- conda-forge builds packages for a new R some time after the R itself is out; an environment with the newest R may not solve yet. rpix's error names the newest R a package is built for.
