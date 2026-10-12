---
type: llm
---

PASS if the response sets CI up with rpix's `use_pixi_github_action("check", ...)` (or otherwise a workflow that installs the project's environments from pixi.lock with prefix-dev's setup-pixi), and tells the user to commit the workflow together with pixi.toml and pixi.lock.

FAIL if its main setup installs R and the dependencies with r-lib's setup-r and setup-r-dependencies (from CRAN, ignoring pixi.lock), or it never mentions committing pixi.lock.
