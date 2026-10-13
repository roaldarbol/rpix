# Setting up, sharing and running projects

Read this when creating a project or moving one to Pixi, setting up an IDE, sharing or reproducing a project, using packages as of a date, saving tasks, rendering documents, setting up CI for an analysis, or using private channels. The guides behind it: [Get started](https://roald-arboel.com/rpix/articles/getting-started.md), [Using rpix with an IDE](https://roald-arboel.com/rpix/articles/ide.md), [Coming from renv](https://roald-arboel.com/rpix/articles/coming-from-renv.md), [Sharing and reproducibility](https://roald-arboel.com/rpix/articles/reproducibility.md), [Private channels](https://roald-arboel.com/rpix/articles/private-channels.md).

## A new project

- `use_pixi()`, from any R with rpix, in the project folder: creates `pixi.toml` if there isn't one, adds R with rpix's dependencies and `conda-ecosystem-user-package-isolation`, installs rpix into the environment, and writes the `.Rprofile` block that activates the environment when an IDE starts R directly. In a package, it adds Pixi's files to `.Rbuildignore`. `ide =` sets up IDEs, `r_version =` picks R (by default the newest R its packages are built for), `date =` sets a package date before anything is added.
- Then `pixi_scan(add = TRUE)` adds the packages the code uses, and `pixi_add_platform()` the collaborators' platforms.
- With no R that has rpix: rpix installs from R-universe into the user's usual R, with `install.packages("rpix", repos = c("https://roaldarbol.r-universe.dev", "https://cloud.r-project.org"))`. That changes the user's own R rather than the project, so ask first. Without rpix at all, Pixi alone does: `pixi init`, `pixi add r-base conda-ecosystem-user-package-isolation`, then `pixi add r-<name>`.
- Without Pixi: `rpix::install_pixi()`, or the installer at <https://pixi.prefix.dev/latest/installation/>. Both add Pixi to the shell's startup files, so ask first.
- A template for new projects: <https://github.com/roaldarbol/r-template>.

## IDEs

| IDE | Set up | Every day | Another environment |
|---|---|---|---|
| Positron | `use_pixi_positron()`: turns on Pixi discovery in `.vscode/settings.json` | Pick "R (Pixi: default)" once in the interpreter picker | Pick its "(Pixi: name)" R, or `pixi_switch()` |
| RStudio | `use_pixi_rstudio()`: an `rstudio` task, and an `.Rproj` | `pixi run rstudio`. RStudio picks its R when it starts, so opening the `.Rproj` directly gives the wrong R | `pixi_switch("name")` starts a new RStudio |
| VS Code | `use_pixi_vscode()`: languageserver, and the R extension pointed at the environment's R | Open the folder; on Windows start it with `pixi run code .` | `pixi_switch("name")`, then Reload Window |

In the IDE's console, `R.home()` should be inside `.pixi/envs/`. When another R opens the project, the `.Rprofile` block says "This R isn't from the project's Pixi environment". If Positron doesn't list the R, run "Interpreter: Discover All Interpreters".

## From renv

```sh
pixi init
Rscript --no-init-file -e 'rpix::pixi_import_renv(); rpix::use_pixi()'
```

`--no-init-file` keeps renv from starting, so this runs in the usual R, where rpix is installed. `pixi_import_renv()` adds the packages in `renv.lock` that nothing else there needs, at least at their locked versions (`versions = "exact"` for those versions, where conda-forge has them), with the lock file's R. Packages from GitHub are added too, built from source at the commit `renv.lock` records, and it offers to build CRAN packages that aren't on conda-forge; both are experimental, so ask the user first (an older rpix lists them instead). It lists what it still can't add (packages in a subfolder of a repository, other sources, packages on neither conda-forge nor bioconda that can't be built; see `packages.md`), and removes `source("renv/activate.R")` from `.Rprofile`. `renv.lock` and `renv/` stay; delete them only when the user says so.

## Sharing and reproducing

- Commit `pixi.toml`, `pixi.lock` and the `.gitattributes` that `pixi init` writes. Its `.gitignore` leaves out `.pixi/` except `.pixi/config.toml`, the project's local Pixi settings.
- To recreate the environment, `pixi install`, or just `pixi run R`. If `pixi.toml` changed since the lock was written, both update the lock first. `pixi install --frozen` installs the lock as it is; `--locked` stops if the lock is out of date, which is what CI wants. `pixi lock --check` reports whether it's up to date.
- `pixi.lock` covers the platforms in `pixi.toml`, and a new project lists only its own. Add others with `pixi_add_platform(c("linux-64", "osx-arm64", "osx-64", "win-64"))`. Every package then has to exist for each of them; bioconda has no Windows builds.
- The setting that allows install scripts is in `.pixi/config.toml`. Don't commit it unless the user decides to: it would allow the scripts for everyone who clones (see `packages.md`).

## Packages as of a date

- `use_pixi(date = "2025-06-01")` when creating a project; `pixi_set_date("2025-06-01")` later; a duration, `pixi_set_date("7d")`, leaves out releases from the last week; `pixi_set_date(NULL)` removes it. It sets `exclude-newer` in `pixi.toml`.
- `pixi_set_date()` fails, leaving `pixi.toml` as it was, when the project pins versions newer than the date, as `pixi_add()` does for what it adds. Setting the date when creating the project avoids that.
- Only packages that were on conda-forge then are available. The date applies to Pixi's build backend too, so source builds fail with a date before the backend version Pixi needs (with Pixi 0.81, before 2026-08-18; prefix-dev/pixi#7240): use a later date, or a duration.

## Tasks, scripts and documents

- `pixi_add_task("analysis", "Rscript analysis.R", description = "Run the analysis")`; `depends_on =` chains tasks. Run with `pixi run analysis` or `pixi_run("analysis")`; list with `pixi_tasks()`. Tasks run in the environment, so they use its R.
- Quarto and R Markdown: `pixi_add("conda::quarto")`, plus rmarkdown or knitr if the documents need them, then `pixi run quarto render report.qmd`.
- CI for an analysis: `use_pixi_github_action("task", task = "report")` runs a task on GitHub Actions with the locked environment.

## Private channels and company networks

- `pixi_add_channel("https://repo.prefix.dev/my-channel")`, then `pixi_add()` as usual.
- A 401 or 403 means Pixi needs credentials. The user logs in, once per host, in their own interactive R: `rpix::pixi_auth_login("repo.prefix.dev")`, or with `method = "password"`, `"conda-token"` or `"s3"`. It asks for the secret without showing it, and fails outside an interactive session; don't run it for them, and never ask for the secret. `pixi_auth_status()` lists the hosts, without secrets.
- In CI, setup-pixi's `auth-host` and `auth-token` (or `auth-username` and `auth-password`, or `auth-conda-token`), from repository secrets.
- Behind a company network: `pixi config set tls-root-certs system` for an inspecting proxy's certificates, the `https_proxy` and `http_proxy` variables, or mirrors in Pixi's configuration (<https://pixi.prefix.dev/latest/reference/pixi_configuration/>).
