#!/usr/bin/env bash
# A Pixi project for R that uses dplyr from conda-forge
set -euo pipefail

cat > pixi.toml <<'EOF'
[workspace]
authors = ["Sam Doe <sam@example.org>"]
channels = ["conda-forge"]
name = "field-survey"
platforms = ["osx-arm64", "linux-64"]
version = "0.1.0"

[tasks]
summarise = "Rscript summarise.R"

[dependencies]
r-base = ">=4.5.1,<4.6"
conda-ecosystem-user-package-isolation = ">=1.0,<2"
r-askpass = ">=1.2.1,<2"
r-cli = ">=3.6.5,<4"
r-jsonlite = ">=2.0.0,<3"
r-processx = ">=3.8.6,<4"
r-rlang = ">=1.1.6,<2"
r-dplyr = ">=1.1.4,<2"
r-readr = ">=2.1.5,<3"
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

cat > summarise.R <<'EOF'
library(dplyr)
library(readr)

sightings <- read_csv("sightings.csv")
sightings |>
  group_by(site, species) |>
  summarise(n = n(), mean_count = mean(count), .groups = "drop") |>
  write_csv("summary.csv")
EOF
