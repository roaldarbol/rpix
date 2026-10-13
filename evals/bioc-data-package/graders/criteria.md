---
type: llm
---

PASS if the response adds org.Hs.eg.db through Pixi (`pixi_add("bioc::org.Hs.eg.db")`, `pixi_add("org.Hs.eg.db")`, or `bioconductor-org.hs.eg.db` from bioconda), and explains that the package downloads its data in an install (post-link) script that Pixi skips unless the project allows such scripts, and leaves allowing them to the user, saying that it runs the package's own code.

FAIL if it installs the package with BiocManager::install() or install.packages(), or tells the user to allow install scripts (`run-post-link-scripts`) without saying what that allows, or doesn't mention the install script at all.
