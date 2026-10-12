---
description: A CRAN and a Bioconductor package in a Pixi project, the most common request and the most common mistake.
expected_outcome: >-
  Adds both through Pixi in one go, e.g. pixi_add(c("dplyr", "bioc::DESeq2"))
  run with the project's R (pixi run Rscript -e ...), or the Pixi CLI with
  r-dplyr and bioconductor-deseq2 from bioconda. No install.packages(),
  BiocManager, pak or renv; no bare Rscript.
tags: [packages, bioconductor]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

I want to do the differential expression in analysis.R with DESeq2, and clean up the sample sheet with dplyr. Can you add both to the project?
