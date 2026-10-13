---
type: llm
---

PASS if the response makes sure the environment that CI checks in has rcmdcheck and the package's Suggests (testthat and withr): for example by setting up `use_pixi_check_matrix()` first and checking in its environments (named, or picked by `use_pixi_github_action("check")` by default), or by adding rcmdcheck to the test feature and checking in the `test` environment.

FAIL if it checks in the default environment without adding the Suggests and rcmdcheck to it, or doesn't consider which environment CI checks in.
