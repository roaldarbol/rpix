---
description: The "there is no package called 'MASS'" error, as conda-forge's R comes without R's recommended packages.
expected_outcome: >-
  Explains that conda-forge's r-base leaves out the recommended packages, and
  adds MASS through Pixi: pixi_add("MASS") or pixi add r-mass. May suggest
  pixi_scan() for anything else missing. No install.packages(), no system R.
tags: [diagnosis]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

`pixi run Rscript analysis.R` stops straight away with

    Error in library(MASS) : there is no package called 'MASS'

I thought MASS came with R? How do I fix this?
