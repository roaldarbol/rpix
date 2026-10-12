---
description: Setting up an existing folder of R code and a Quarto report as a Pixi project, for Positron.
expected_outcome: >-
  Sets the project up with rpix::use_pixi(ide = "positron"), from an R with
  rpix (installing rpix from R-universe into the user's own R first if needed);
  adds what the code uses through Pixi, e.g. pixi_scan(add = TRUE); adds Quarto
  through Pixi (conda::quarto) and renders with pixi run quarto render; says to
  commit pixi.toml and pixi.lock, not the environments in .pixi/, and to pick
  "R (Pixi: default)" in Positron. May add the lab's platforms.
tags: [setup]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

I'd like this analysis to be reproducible for the rest of my lab, with Pixi. I work in Positron. Can you set it up?
