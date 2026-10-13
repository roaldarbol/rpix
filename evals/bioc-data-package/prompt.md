---
description: A Bioconductor annotation package, whose data comes from an install script that Pixi skips by default.
expected_outcome: >-
  Adds it through Pixi, pixi_add("bioc::org.Hs.eg.db") or
  bioconductor-org.hs.eg.db from bioconda. Explains that its data is downloaded
  by a post-link script, which Pixi only runs where run-post-link-scripts is
  allowed, that allowing it runs the package's code, and leaves that decision,
  and whether to commit .pixi/config.toml, to the user. No BiocManager.
tags: [packages, bioconductor, security]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

Add org.Hs.eg.db to the project, so annotate.R can map the Ensembl IDs to gene symbols.
