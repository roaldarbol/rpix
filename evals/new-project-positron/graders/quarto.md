---
type: llm
weight: 0.5
---

PASS if the response makes report.qmd render with the project's environment: Quarto added through Pixi (`pixi_add("conda::quarto")` or `pixi add quarto`) and the report rendered with `pixi run quarto render report.qmd` or a Pixi task (tasks run in the project's environment, so e.g. `pixi task add report "quarto render report.qmd"` then `pixi run report` is a PASS), or the knitr/rmarkdown packages added through Pixi with rendering through `pixi run`.

FAIL if it ignores report.qmd, or renders it with a Quarto or R from outside the project's environment.
