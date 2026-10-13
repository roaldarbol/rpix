# Evals for the rpix skill

Cases for [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals): each runs a realistic request in a scaffolded project, with the plugin and without it, and grades the reply. Run them from the repository root:

```sh
claude plugin eval . --scaffold
```

`--scaffold` runs each case's `scaffold.sh`, which writes the project the request is about. Every run is a real model call on your account: 8 cases × 3 runs × 2 arms. While iterating on one case, `--case <name> --runs 1 --ablation none`.

The agent gets read-only tools and is told it can't run commands, so the cases grade what it tells the user to run, not the result of running it.

| Case | Request | A correct agent |
|---|---|---|
| `add-cran-and-bioc` | Add DESeq2 and dplyr | `pixi_add(c("dplyr", "bioc::DESeq2"))`, or `r-dplyr` and `bioconductor-deseq2` from bioconda; never `install.packages()` or BiocManager |
| `add-github-package` | Switch to dplyr's development version | `pixi_add("github::tidyverse/dplyr")`, built from source; flags it as experimental |
| `missing-recommended-package` | "there is no package called 'MASS'" | Explains conda-forge's R lacks the recommended packages; `pixi_add("MASS")` |
| `ci-for-package` | R CMD check on GitHub Actions | `use_pixi_github_action("check", ...)` in an environment with rcmdcheck and the Suggests; commits `pixi.lock` |
| `bioc-data-package` | Add org.Hs.eg.db | Adds it through Pixi; explains the skipped install script, and leaves allowing it to the user |
| `install-packages-collaborator` | Works for me after `install.packages()`, not for my colleague | `pixi_add("ggplot2")`, commit `pixi.toml` and `pixi.lock` |
| `new-project-positron` | Make this analysis reproducible with Pixi, in Positron | `use_pixi(ide = "positron")`, `pixi_scan(add = TRUE)`, Quarto through Pixi, commit the manifest and lock |
| `renv-project` | Add janitor, in an renv project | Uses renv; the skill doesn't load |

Each positive case also reports whether the skill fired (`skill-used`), which a two-arm run shows as an indicator rather than a score.
