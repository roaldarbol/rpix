---
type: llm
---

PASS if the response explains that install.packages() installed ggplot2 without Pixi recording it in pixi.toml and pixi.lock (or into an R outside the project's environment), so a fresh clone doesn't get it, and the fix is to add it through Pixi (`pixi_add("ggplot2")` or `pixi add r-ggplot2`), commit pixi.toml and pixi.lock, and have the colleague pull and run it again with `pixi run` (or `pixi install`).

FAIL if it tells the colleague to run install.packages() too, suggests renv, or doesn't have ggplot2 recorded in pixi.toml and pixi.lock.
