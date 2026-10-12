---
type: llm
---

PASS if the response has the user add both packages through Pixi, so that pixi.toml and pixi.lock record them: with rpix's pixi_add() (such as `pixi_add(c("dplyr", "bioc::DESeq2"))`, run in the project's R or with `pixi run Rscript -e`), or with the Pixi CLI using conda names (`r-dplyr`, and `bioconductor-deseq2` from the bioconda channel).

FAIL if it tells the user to install either package with install.packages(), BiocManager::install(), pak, remotes or renv, or to run R code with a bare `Rscript` or `R` rather than through `pixi run`.
