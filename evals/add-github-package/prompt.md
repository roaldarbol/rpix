---
description: An R package from GitHub, which Pixi has to build from source.
expected_outcome: >-
  Uses pixi_add("github::tidyverse/dplyr"), optionally with @main or a commit,
  which replaces the conda-forge r-dplyr entry. Says it's built from source by
  Pixi's R build backend (experimental), that pixi.lock records the commit, and
  checks with the user before building. No remotes, pak or devtools installs.
tags: [packages, source-build]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

A bug in dplyr that breaks summarise.R is fixed on its main branch on GitHub (tidyverse/dplyr), but there's no release with the fix yet. Can you switch this project to the development version?
