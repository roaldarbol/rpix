# Contributing to rpix

Thanks for helping out! Questions and ideas are welcome in [GitHub Discussions](https://github.com/roaldarbol/rpix/discussions), and bugs in the [issues](https://github.com/roaldarbol/rpix/issues).

## Setting up

rpix is developed in its own Pixi environment, defined in `pixi.toml`: R, rpix's dependencies, and the tools for developing it (devtools, roxygen2, testthat, covr, pkgdown, quarto and air). None of these are rpix's dependencies; users only get what's in `DESCRIPTION`'s `Imports`.

1. [Install Pixi](https://pixi.sh/latest/installation/).
2. Clone the repository. Pixi installs the environment the first time you run a task.

## Tasks

Run these in a terminal in the repository:

| Task | Does |
|---|---|
| `pixi run document` | Regenerates `man/` and `NAMESPACE` from the roxygen comments |
| `pixi run test` | Runs the tests |
| `pixi run check` | Runs `R CMD check` |
| `pixi run coverage` | Measures test coverage, and opens a report of uncovered lines |
| `pixi run format` | Formats the code with [air](https://posit-dev.github.io/air/) |
| `pixi run readme` | Renders `README.md` from `README.qmd` |
| `pixi run site` | Builds the pkgdown site |
| `pixi run preview` | Builds the site and serves it at <http://127.0.0.1:8000> |

## In an IDE

- **Positron:** the repository turns on Positron's Pixi discovery in `.vscode/settings.json`. Pick **R (Pixi: default)** in the interpreter picker, and use `devtools::load_all()` and friends, or their shortcuts (Cmd/Ctrl+Shift+L, T, D), as usual.
- **RStudio or VS Code:** see [Using rpix with an IDE](https://roald-arboel.com/rpix/articles/ide.html).

## Pull requests

- **Every new or changed line is covered by tests.** Codecov checks this on each pull request; `pixi run coverage` shows what isn't covered.
- **Code is formatted with air,** which is checked on each pull request. Run `pixi run format`, or comment `/style` on the pull request.
- **`man/` is generated.** Edit the roxygen comments and run `pixi run document`, or comment `/document` on the pull request.
- **`NEWS.md` is written for users,** in the [tidyverse style](https://style.tidyverse.org/news.html). Add a bullet under `# rpix (development version)` for each user-facing change.
- **Pull request titles are [Conventional Commits](https://www.conventionalcommits.org/),** e.g. `feat: add pixi_sitrep()` or `fix: ...`.
