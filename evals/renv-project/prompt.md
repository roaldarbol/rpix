---
description: A near miss. An R project managed with renv, without Pixi, where the skill shouldn't load.
expected_outcome: >-
  Adds janitor the renv way, renv::install("janitor") then renv::snapshot(), and
  doesn't bring Pixi or rpix into it. The rpix skill isn't invoked.
tags: [negative]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

Can you add the janitor package to this project? I want to use clean_names() in import.R.
