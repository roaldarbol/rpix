#!/usr/bin/env bash
# A Pixi project for R, as rpix::use_pixi() sets one up, with an analysis script
set -euo pipefail

cat > pixi.toml <<'EOF'
[workspace]
authors = ["Sam Doe <sam@example.org>"]
channels = ["conda-forge"]
name = "tumour-rnaseq"
platforms = ["osx-arm64", "linux-64"]
version = "0.1.0"

[tasks]

[dependencies]
r-base = ">=4.5.1,<4.6"
conda-ecosystem-user-package-isolation = ">=1.0,<2"
r-askpass = ">=1.2.1,<2"
r-cli = ">=3.6.5,<4"
r-jsonlite = ">=2.0.0,<3"
r-processx = ">=3.8.6,<4"
r-rlang = ">=1.1.6,<2"
r-readr = ">=2.1.5,<3"
r-ggplot2 = ">=3.5.2,<4"
EOF

cat > .gitignore <<'EOF'
# pixi environments
.pixi/*
!.pixi/config.toml
EOF

cat > .Rprofile <<'EOF'
# >>> rpix >>>
# Activates the project's Pixi environment when an IDE starts R directly.
# See https://roald-arboel.com/rpix/articles/how-rpix-works.html
local({
  # In the environment's R, drop the personal library before any package
  # loads: it has packages built for another R, which can crash this one
  home <- normalizePath(R.home(), winslash = "/")
  if (grepl("/[.]pixi/envs/[^/]+/lib/R$", home)) {
    personal <- strsplit(Sys.getenv("R_LIBS_USER"), .Platform$path.sep)[[1]]
    personal <- normalizePath(personal, winslash = "/", mustWork = FALSE)
    personal <- personal[!grepl("/[.]pixi/", personal)]
    .libPaths(setdiff(.libPaths(), personal))
  }
  if (requireNamespace("rpix", quietly = TRUE) &&
      "pixi_activate" %in% getNamespaceExports("rpix")) {
    rpix::pixi_activate()
  }
})
# <<< rpix <<<
EOF

mkdir -p data
cat > analysis.R <<'EOF'
library(readr)
library(ggplot2)

counts <- read_csv("data/counts.csv")
samples <- read_csv("data/samples.csv")

# TODO: tidy the sample sheet with dplyr
# TODO: differential expression with DESeq2 (treated vs control)
EOF
