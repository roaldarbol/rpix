---
type: llm
---

PASS if the response adds janitor the renv way, such as `renv::install("janitor")` (or install.packages() in the renv library) followed by `renv::snapshot()` so renv.lock records it, without bringing Pixi into the project.

FAIL if it suggests Pixi, rpix or a pixi.toml, or moving the project away from renv, when the user didn't ask for that.
