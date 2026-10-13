---
type: llm
---

PASS if the response has the user add dplyr from GitHub through rpix, as `pixi_add("github::tidyverse/dplyr")` (with or without `@main` or a commit), so Pixi builds it from source and pixi.toml and pixi.lock record it, and it says that building from source this way is experimental or asks the user to confirm before doing it.

FAIL if it installs the development version with remotes::install_github(), pak, devtools::install_github() or install.packages(), or tells the user to run the project's code (such as summarise.R) with a bare `Rscript` or `R` rather than through `pixi run`. Calling rpix's own functions from the user's usual R (e.g. `Rscript -e 'rpix::pixi_add(...)'` as a fallback when the environment has no rpix) is fine: they only drive Pixi, and don't run the project's code.
