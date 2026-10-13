# Developing an R package with Pixi

Read this when the project is an R package (a `DESCRIPTION` with a `Package` field) and the task touches its dependencies, tests, checks or CI. Arguments are on the pages for `pixi_import_description()`, `pixi_check_matrix()` and `use_pixi_github_action()`, found through <https://roald-arboel.com/rpix/llms.txt>; the whole workflow in [Developing a package](https://roald-arboel.com/rpix/articles/package-development.md).

## DESCRIPTION and pixi.toml

`DESCRIPTION` stays the source of truth for what the package needs; `pixi.toml` provides an environment to develop it in.

- `pixi_import_description()` adds `Depends`, `Imports` and `LinkingTo` to the default feature, with their minimum versions, and `Suggests` to a `test` feature with a `test` environment in the default environment's solve group. `Depends: R (>= x)` becomes the constraint on R if the project has no R yet. Packages on neither conda-forge nor bioconda are listed and left out: see `packages.md` for building them from GitHub.
- A new dependency goes in both files: `DESCRIPTION` (e.g. `usethis::use_package()`), and `pixi.toml` with `pixi_add()`, using `feature = "test"` for a `Suggests`. Or edit `DESCRIPTION` and run `pixi_import_description()` again.
- In a package, `pixi_sitrep()` checks that the default environment has the hard dependencies, that `pixi.toml` has the `Suggests` somewhere, that installed versions meet `DESCRIPTION`'s minimums, and that `.Rbuildignore` leaves out `.pixi`, `pixi.toml` and `pixi.lock` (and `.vscode`), which `use_pixi()` and the IDE setup add.
- Tools for developing, such as devtools and roxygen2, go in a feature of their own, not in `DESCRIPTION`. rpix's own `pixi.toml` keeps them in a `dev` feature that its default environment includes (`[environments]` with `default = ["dev"]`).

## Working on it

- Run the tools with the environment's R: `pixi run Rscript -e 'devtools::test()'`, `devtools::document()`, `devtools::check()`, or in the `test` environment with `pixi run -e test ...`. Save them as tasks (`pixi_add_task("test", "Rscript -e 'devtools::test()'")`) so everyone runs them the same way.
- Prefer `devtools::load_all()` to installing the package into the environment; an installed copy isn't recorded, and `pixi_sitrep()` lists it.
- Compiled code: conda-forge's R brings compilers and `make` on Linux and macOS. On Windows it has no `make`; MSYS2's tools are conda packages, and rpix adds `m2-make`, `m2-sed` and `m2-coreutils` for its own source builds there. A package with compiled code developed or checked on Windows needs them too: `pixi_add(c("m2-make", "m2-sed", "m2-coreutils"), platform = "win-64")`.

## Checking across versions of R, and minimum versions

- `use_pixi_check_matrix(c("4.4", "4.5"))` adds an environment for each R (`r44`, `r45`), with all of `DESCRIPTION`'s dependencies, including `Suggests`, plus testthat, pkgload and rcmdcheck, and the personal-library isolation.
- `minimum = TRUE` also adds a `minimum` environment: R at the version `Depends` asks for, and each hard dependency at the lowest version its constraint allows. It lacks the `Suggests` for now (rpix issue #168), so tests that use them unguarded fail there. A dependency without a minimum gets the oldest version on conda-forge for that R, which rpix lists. Only versions on conda-forge count, and old builds sometimes record looser dependencies than their `DESCRIPTION`, so a failure there isn't necessarily the package's fault.
- `pixi_check_matrix()` runs the tests in every environment, or `what = "check"` for `R CMD check`, `parallel = TRUE` for all at once. It returns a data frame; what each run printed is in its `output` column.
- R-devel isn't on conda-forge. A check against it needs a separate job with r-lib's `setup-r`.

## CI

`use_pixi_github_action()` writes a GitHub Actions workflow that installs the environments exactly as `pixi.lock` records them, with prefix-dev's setup-pixi in place of r-lib's `setup-r`, `setup-r-dependencies` and `setup-pandoc`. Use it rather than writing an r-lib workflow by hand: those install packages from CRAN, ignoring the lock file.

- `"check"`: r-lib's `check-r-package`, for each environment, on each of the project's platforms that GitHub runs (`linux-64`, `osx-arm64`, `win-64`). Each environment needs rcmdcheck and the package's dependencies, `Suggests` included; the default environment has neither rcmdcheck nor the `Suggests`. Without `environments`, rpix picks every environment that has them, e.g. the check matrix's `r44` and `r45`, and stops with the `pixi_add()` call to run if none does; so set up the check matrix first (`use_pixi_check_matrix(c("4.4", "4.5"))`), or add rcmdcheck to the `test` feature. With `environments`, it warns about each that lacks something. An older rpix defaults to `"default"` without checking: name the environments then.
- `"test-coverage"` needs covr and xml2 (and the package's dependencies) in the environment it uses; `"pkgdown"` needs pkgdown and `conda::pandoc`. Without `environments`, rpix picks the first that has them. `"task"` runs a Pixi task (`task = "..."`) in the default environment.
- The workflow pins Pixi to the version installed locally, and fails when `pixi.lock` is out of date with `pixi.toml`: commit `pixi.toml`, `pixi.lock` and the workflow together.
- Missing platforms are reported; add them with `pixi_add_platform()` before writing the workflow.
- Private channels in CI: setup-pixi's `auth-*` inputs, with the credentials in repository secrets.
