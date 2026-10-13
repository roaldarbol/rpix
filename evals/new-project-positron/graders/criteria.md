---
type: llm
---

PASS if the response sets the project up with rpix's `use_pixi()` for Positron (`use_pixi(ide = "positron")`, or `use_pixi()` and then `use_pixi_positron()`), has the packages the code uses added through Pixi (such as `pixi_scan(add = TRUE)` or `pixi_add()`), and says to commit pixi.toml and pixi.lock but not the environments in `.pixi/`.

FAIL if it sets up renv, installs packages with install.packages() or pak, or leaves pixi.lock out of what to commit.
