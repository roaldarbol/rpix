---
description: CI for an R package developed in a Pixi project.
expected_outcome: >-
  Uses rpix's use_pixi_github_action("check", ...), so CI installs the
  environments exactly as pixi.lock records them, rather than an r-lib workflow
  with setup-r-dependencies. Checks in an environment with rcmdcheck and the
  Suggests: the test environment after pixi_add("rcmdcheck", feature = "test"),
  or environments from use_pixi_check_matrix(). Says to commit the workflow
  with pixi.toml and pixi.lock.
tags: [package-dev, ci]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Skill]
append_system_prompt: Shell commands can't run in this session. Tell the user exactly what to run, in order.
---

Please set up GitHub Actions for this package: R CMD check on Linux, macOS and Windows, on every push and pull request.
