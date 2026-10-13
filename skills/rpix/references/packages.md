# Adding, finding and removing packages

Read this when adding, removing or updating packages, or when one can't be found, solved or built. Arguments are in [`pixi_add()`'s page](https://roald-arboel.com/rpix/reference/pixi_add.md); the user-facing guide is [Finding packages](https://roald-arboel.com/rpix/articles/finding-packages.md).

## Names

rpix takes R names; the Pixi CLI needs conda names.

| Reference | Conda package | Notes |
|---|---|---|
| `"dplyr"`, `"cran::dplyr"` | `r-dplyr` | `r-` and the name in lower case |
| `"data.table"` | `r-data.table` | dots stay |
| `"bioc::DESeq2"` | `bioconductor-deseq2` | from bioconda |
| `"conda::gdal"` | `gdal` | used as it is |
| `"r-dplyr"`, `"c-compiler"` | unchanged | an R name can't contain `-` or `_`, so these are taken as conda names |
| `"github::user/repo"` | `r-<Package in its DESCRIPTION>` | built from source |

Without a prefix, a package that isn't on conda-forge is looked for on bioconda, so `"DESeq2"` works too; `bioc::` says so up front. A few packages have other names on conda-forge: when a translated name isn't found, `pixi_search()` or <https://prefix.dev/channels/conda-forge> settles it.

## Versions

- Inline, `"dplyr>=1.1"` or `"ggplot2==3.5.1"`; or in `versions =`, one per package, with `NA` for none.
- A version without an operator, `"1.1"`, means `1.1.*`.
- conda writes R's `1.2-3` as `1.2_3`.
- `pixi add` pins what it adds, e.g. `>=1.1.4,<2`.

## The Pixi CLI

| rpix | Pixi |
|---|---|
| `pixi_add("dplyr")` | `pixi add r-dplyr` |
| `pixi_add("bioc::DESeq2")` | `pixi workspace channel add bioconda`, then `pixi add bioconda::bioconductor-deseq2` |
| `pixi_add("testthat", feature = "test")` | `pixi add --feature test r-testthat` |
| `pixi_add("m2-make", platform = "win-64")` | `pixi add --platform win-64 m2-make` |
| `pixi_remove("dplyr")` | `pixi remove r-dplyr` |
| `pixi_search("dplyr")` | `pixi search r-dplyr` |
| `pixi_update("dplyr")` | `pixi update r-dplyr` |

The CLI has no counterpart for three things rpix does: packages from GitHub (`pixi add` can't set a build backend yet, prefix-dev/pixi#7213, so rpix writes the entry into `pixi.toml` itself), looking on bioconda when conda-forge lacks a package, and noticing skipped install scripts.

## Bioconductor

- From bioconda, as `bioconductor-<name in lower case>`. rpix adds the bioconda channel the first time it's needed.
- bioconda has no Windows builds.
- bioconda builds each Bioconductor release for one version of R, and its builds for a new R arrive later than conda-forge's. If Pixi can't solve, ask the user about pinning R to the version bioconda builds for.
- **Annotation and data packages** (`org.Hs.eg.db`, `GO.db`, `TxDb.*`, `BSgenome.*`) download their data in a post-link script. Pixi skips those unless the checkout allows them, and installs the package without its data.
  - `pixi_add()`, `pixi_install()`, `pixi_update()` and `pixi_upgrade()` notice. In an interactive R they offer to allow the scripts; from a script they warn, naming the packages and the commands.
  - The scripts run with the user's permissions, so allowing them is the user's decision. With their agreement: `pixi config set --local run-post-link-scripts insecure`, then `pixi reinstall <conda-names>`.
  - The setting is in `.pixi/config.toml`, which the `.gitignore` that `pixi init` writes doesn't ignore. Committed, it turns the scripts on for everyone who clones: the user's decision, not a side effect of `git add`. Uncommitted, each checkout and CI job needs the setting.
  - `pixi.lock` pins the package, not the data it downloads.
- Bioconductor packages can't be built from source yet (rpix#124, prefix-dev/pixi#6994).

## Packages that aren't on conda-forge

`pixi_add("github::user/repo")` has Pixi build the package from source, with its R build backend, `pixi-build-r`. Experimental (rpix#96): ask the user first.

- `@ref` picks a branch, tag or commit, or give it in `versions =`; a version range doesn't apply. `pixi.lock` records the commit either way.
- A CRAN package that isn't on conda-forge: `github::cran/<pkg>`, from CRAN's GitHub mirror, which has a tag for every version (`@1.2.3`). `pixi_add()` offers this itself; from a script it stops and prints the call.
- rpix writes the package into `pixi.toml`, turns on Pixi's `pixi-build` preview, and pins the build to the project's R. It also adds what `pixi-build-r` doesn't yet: R's recommended packages the package uses (Matrix, MASS...), build tools its `SystemRequirements` names (Rust, Java, CMake, pkg-config), and in a project for Windows, R's library folder and MSYS2's `make`, `sed` and `coreutils`. If the build fails, rpix puts `pixi.toml` back as it was.
- Its dependencies come from conda-forge. Not possible yet: dependencies that are themselves only on GitHub (prefix-dev/pixi#6925, rpix#122), Bioconductor dependencies (prefix-dev/pixi#6994), private repositories (rpix#136). A package that needs a system library R doesn't bring along, such as GDAL, may not build.
- An `exclude-newer` date (see `setup-and-sharing.md`) applies to Pixi's build backend too, so source builds fail with a date before the backend version Pixi needs: with Pixi 0.81, any date before 2026-08-18 (prefix-dev/pixi#7240). Use a later date, or a duration.
- Needs a `pixi.toml` manifest. A build takes a minute or more.
- Remove it with `pixi_remove("github::user/repo")`.

The lasting fix is the package on conda-forge, for everyone: `pixi exec rattler-build generate-recipe cran <pkg>` writes a recipe to submit to <https://github.com/conda-forge/staged-recipes>.

## What the code uses

`pixi_scan()` reads `.R` files, the R chunks of `.qmd` and `.Rmd` files, and task commands, for `library()`, `require()`, `requireNamespace()`, `loadNamespace()` and `pkg::fun`. It lists packages missing from `pixi.toml`, and R packages in the default feature that the code never uses; some of those are there on purpose, so check before removing any. `add = TRUE` adds the missing ones it finds on conda-forge or bioconda.

## Updating

`pixi update` (`pixi_update()`) moves packages to the newest versions `pixi.toml` allows; `pixi upgrade` (`pixi_upgrade()`) raises the constraints in `pixi.toml` too. Both rewrite `pixi.lock`: commit it.
