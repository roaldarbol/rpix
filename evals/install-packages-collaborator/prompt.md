---
description: A package installed with install.packages() works for one person and not for a collaborator.
expected_outcome: >-
  Explains that install.packages() put ggplot2 where Pixi doesn't record it, so
  pixi.toml and pixi.lock don't have it. Has the user add it with
  pixi_add("ggplot2") or pixi add r-ggplot2, and commit pixi.toml and pixi.lock;
  the colleague pulls and runs pixi run (or pixi install). May point to
  pixi_sitrep() and pixi_scan(). No install.packages() for the colleague.
tags: [diagnosis, reproducibility]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

I installed ggplot2 with install.packages() and plot.R works fine for me. My colleague cloned the repo, ran `pixi run Rscript plot.R`, and gets

    Error in library(ggplot2) : there is no package called 'ggplot2'

How do we fix this properly?
