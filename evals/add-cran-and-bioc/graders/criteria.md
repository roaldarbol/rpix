---
type: llm
---

PASS if the response has the user add both packages through Pixi, so that pixi.toml and pixi.lock record them: with rpix's pixi_add() (such as `pixi_add(c("dplyr", "bioc::DESeq2"))`, run in the project's R or with `pixi run Rscript -e`), or with the Pixi CLI using conda names (`r-dplyr`, and `bioconductor-deseq2` from the bioconda channel).

FAIL if it tells the user to install either package with install.packages(), BiocManager::install(), pak, remotes or renv, or to run the project's code (such as analysis.R) with a bare `Rscript` or `R` rather than through `pixi run`. Calling rpix's own functions from the user's usual R (e.g. `Rscript -e 'rpix::pixi_add(...)'` as a fallback when the environment has no rpix) is fine: they only drive Pixi, and don't run the project's code.
