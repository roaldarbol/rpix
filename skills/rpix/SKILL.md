---
name: rpix
description: >-
  Use whenever R code lives in a Pixi project, meaning a pixi.toml (or a
  pyproject.toml with [tool.pixi]) next to .R, .qmd or .Rmd files or a
  DESCRIPTION, and when asked to set up an R project with Pixi or rpix, or to
  move one from renv. Covers installing and adding R packages (CRAN,
  Bioconductor, GitHub, conda) so pixi.toml and pixi.lock record them, instead
  of install.packages(), pak, remotes, BiocManager or renv; running R, scripts,
  tests and documents with the environment's R; fixing R that won't start, the
  wrong R, crashes and "there is no package called"; sharing, platforms and
  package dates; several versions of R; R package development, checks and CI.
  Not for R projects without Pixi, or Pixi projects without R.
license: MIT
---

# rpix

A Pixi project keeps R itself, its packages and the system libraries they need in an environment inside the project (`.pixi/envs/<name>/`), from conda-forge and bioconda. `pixi.toml` records what was asked for, `pixi.lock` the exact builds for every platform. [rpix](https://roald-arboel.com/rpix/) is the R package that drives Pixi from R. Everything below follows from one rule: **R and its packages come from Pixi, so the lock file stays the truth.**

## Rules

1. **Add packages through Pixi:** `rpix::pixi_add()`, or `pixi add r-<name>` in a terminal. Never `install.packages()`, `pak`, `remotes`, `BiocManager::install()`, `devtools::install_deps()` or renv: they write into the environment's library behind Pixi's back, so nothing records them, collaborators and CI don't get them, and Pixi can remove or strand them.
2. **Run the project's R:** `pixi run Rscript script.R`, `pixi run Rscript -e '...'`, or a task (`pixi run <task>`). A bare `R` or `Rscript` is another R, with other packages. Never point another R at `.pixi/` (`.libPaths()`, `R_LIBS`): packages built for one R crash another.
3. **Leave `pixi.lock` to Pixi.** Never edit it. Editing `pixi.toml` is fine, then run `pixi lock` (or `pixi install`) so the lock follows. Commit both; never commit the environments in `.pixi/`.
4. **No renv in a Pixi project:** two lock files contradict each other. Moving from renv: `references/setup-and-sharing.md`.
5. **Ask the user first** before allowing install scripts (`run-post-link-scripts`), building a package from source, installing Pixi, or anything that needs a login. rpix asks these itself in an interactive R; from a script it doesn't ask, but stops or warns with the command to run. Put the choice to the user, then run what it printed.
6. **Never handle secrets.** Don't take tokens in chat or put them on a command line; the user runs `rpix::pixi_auth_login()` in their own interactive R.
7. **Verify, don't recall.** rpix and Pixi change between releases. Before calling an rpix function, find it in <https://roald-arboel.com/rpix/llms.txt> and read its page there (`reference/<page>.md`). The installed rpix is what runs, and may be older: `pixi run Rscript -e 'args(rpix::pixi_add)'`. For Pixi, `pixi <command> --help`, or <https://pixi.prefix.dev/latest/llms.txt>.

## Calling rpix from a shell

rpix works from any R and finds the project by looking upwards from the working directory for `pixi.toml`. Function names below are bare; from a shell, write them as `rpix::`. In order of preference:

1. `pixi run Rscript -e 'rpix::pixi_add("dplyr")'`: the environment's R, where `use_pixi()` installed rpix.
2. `Rscript -e 'rpix::pixi_add("dplyr")'`: the user's usual R, if rpix is installed there. Fine for rpix's functions, which only drive Pixi; never for the project's own code.
3. The Pixi CLI, with conda names: `pixi add r-dplyr`. rpix prints each Pixi command it runs, and `dry_run = TRUE` shows it without running it.

rpix is in `pixi.toml` as `r-rpix`. It isn't on conda-forge yet, so it comes from the channel `https://prefix.dev/roaldarbol/rpix-forge`, which `use_pixi()` adds after conda-forge. A project set up by an earlier rpix, or another environment, may lack it (`pixi run Rscript -e 'packageVersion("rpix")'`); then use 2 or 3, or run `use_pixi()` again from the user's usual R, which keeps the project's versions and adds rpix.

For more than a line of R, write a script and `pixi run Rscript script.R` rather than fight shell quoting. The first `pixi run` or `pixi install` downloads R and every package: allow several minutes, and run Pixi commands one at a time.

## Adding packages

| You write | Conda package | From |
|---|---|---|
| `"dplyr"`, `"Rcpp"`, `"data.table"` | `r-dplyr`, `r-rcpp`, `r-data.table` | conda-forge |
| `"bioc::DESeq2"`, or `"DESeq2"` | `bioconductor-deseq2` | bioconda, added to the project's channels |
| `"conda::quarto"`, `"conda::gdal"` (not R packages) | `quarto`, `gdal` | conda-forge |
| `"github::user/repo@ref"` | built from source (experimental) | GitHub |

Add them in one call, `pixi_add(c("dplyr", "bioc::DESeq2"))`, so Pixi solves once. A version constraint follows the name (`"dplyr>=1.1"`); `feature =` adds to a feature rather than the default one. `pixi_scan(add = TRUE)` adds the packages the code uses that `pixi.toml` lacks.

When a package can't be added, go down this list and stop at the first that applies:

1. **The name.** `pixi_search("name")`. A Bioconductor package takes `bioc::`, a conda package that isn't an R package `conda::`.
2. **Not built for the project's R yet,** common after a new R release, and on bioconda, which lags behind conda-forge. rpix's error names the newest R it's built for. Pinning R changes the whole project, so ask, then add R with the package: `pixi_add(c("r-base=4.5", "bioc::DESeq2"))`.
3. **The platform.** bioconda has no Windows builds, so a project with `win-64` among its platforms can't have Bioconductor packages. Tell the user; don't drop the platform unasked.
4. **On CRAN, not on conda-forge:** Pixi can build it from CRAN's GitHub mirror, `pixi_add("github::cran/<pkg>")`, or `@1.2.3` for a version. Experimental: ask first.
5. **Only on GitHub:** `pixi_add("github::user/repo@ref")`, with the same caveat. It can't yet depend on packages that are themselves built from source, or on Bioconductor packages, and may fail to build if it needs a system library R doesn't bring along.
6. **None of these:** tell the user, and don't fall back to `install.packages()`. The lasting fix is a conda-forge recipe: `pixi exec rattler-build generate-recipe cran <pkg>`, submitted to conda-forge's staged-recipes.

**Bioconductor's annotation and data packages** (`org.Hs.eg.db`, `GO.db`, `TxDb.*`, `BSgenome.*`) download their data in an install script, which Pixi skips unless the checkout allows it. rpix then warns that the package isn't fully installed, and it won't load. Allowing it (`pixi config set --local run-post-link-scripts insecure`, then `pixi reinstall <conda-name>`) runs the package's own code with the user's permissions, so it's the user's call. The setting goes in `.pixi/config.toml`, which Pixi's `.gitignore` leaves committable: committed, it allows the scripts for everyone who clones, so that's the user's call too; uncommitted, every checkout and CI job needs it.

Names, versions, CLI equivalents, source builds and Bioconductor in detail: `references/packages.md`.

## When something's wrong

Diagnose before fixing:

```sh
pixi run Rscript -e 'rpix::pixi_sitrep()'
```

It reports on Pixi, the project, whether `pixi.lock` matches `pixi.toml`, whether R is the project's and activated, libraries and packages from outside the project, packages installed without Pixi, the `.Rprofile` block, logins, and in a package whether `pixi.toml` covers `DESCRIPTION`, each with its fix. Run like this, it describes the R that `pixi run` starts; for the user's IDE, ask them to run `rpix::pixi_sitrep()` in its console and share the output.

When it can't run, or for a first look:

1. **`pixi --version` fails:** Pixi isn't installed, or isn't on the `PATH` (it installs into `~/.pixi/bin`). Ask before installing it.
2. **"Could not find a Pixi project":** the working directory isn't in the project.
3. **`pixi run` fails before R starts:** read Pixi's error. Usually a package name, a package not built for this R or platform, a channel refusing access (the user logs in), or an `exclude-newer` date.
4. **`there is no package called 'x'`:** Is `x` in `pixi.toml`? (`pixi_scan()` lists what the code uses but `pixi.toml` lacks.) Is it one of R's recommended packages, which conda-forge's R leaves out (MASS, Matrix, lattice, survival, mgcv, nlme...)? Add those like any other. Was the code run with the project's R?
5. **R crashes loading a package:** an R or library from outside the environment. `R.home()` must be inside `.pixi/envs/`, and `.libPaths()` must not list a personal library.

Symptom by symptom, with rpix's messages: `references/troubleshooting.md`.

## Setting up, sharing, developing

- **New project, or a folder of R code:** `use_pixi(ide = "positron")` (or `"rstudio"`, `"vscode"`, `"emacs"`, `"neovim"`, `"zed"`), then `pixi_scan(add = TRUE)`. It adds R, rpix, `conda-ecosystem-user-package-isolation` (keeps the personal library out) and an `.Rprofile` block (activates the environment when an IDE starts R): keep all of them. `r_version =` and `date =` set R's version and a package date up front.
- **Sharing:** commit `pixi.toml` and `pixi.lock`; collaborators run `pixi install`, or just `pixi run R`. A new project lists only the platform it was made on: add the collaborators' with `pixi_add_platform()`.
- **Packages as of a date:** `use_pixi(date = )` for a new project, `pixi_set_date()` for an existing one.
- **Another version of R, or packages just for tests:** features and environments, in `references/environments.md`.
- **An R package:** `DESCRIPTION` stays the source of truth. `pixi_import_description()` brings its dependencies into `pixi.toml`, `use_pixi_check_matrix()` and `pixi_check_matrix()` test across R versions and minimum versions, and `use_pixi_github_action()` writes CI from the lock file. See `references/package-development.md`.
- **IDEs, renv, tasks, documents, CI for analyses, private channels:** `references/setup-and-sharing.md`.

## Gotchas

- In the environment's R, the project's `.Rprofile` reroutes `install.packages("x")` to `pixi_add()`, when rpix is installed there. `utils::install.packages()` bypasses it.
- `pixi add` pins what it adds (`>=1.1.4,<2`). Loosen a pin in `pixi.toml` if needed, then `pixi lock`.
- Read versions with `pixi list` or `pixi tree`, not by reading `pixi.lock`, which is large. Leave `.pixi/` out of searches.
- On a merge conflict in `pixi.lock`, resolve `pixi.toml`, take either side's lock, and run `pixi lock`. Never merge the lock by hand.
- Render Quarto and R Markdown with the environment's R: add `conda::quarto`, then `pixi run quarto render report.qmd`.
- Some rpix functions need a `pixi.toml` manifest rather than `pyproject.toml`: GitHub packages, dates, the `minimum` environment.
