#!/usr/bin/env bash
# A Pixi project for R in git, whose plot.R uses ggplot2, which pixi.toml lacks
set -euo pipefail

cat > pixi.toml <<'EOF'
[workspace]
authors = ["Sam Doe <sam@example.org>"]
channels = ["conda-forge"]
name = "bird-counts"
platforms = ["osx-arm64", "linux-64", "win-64"]
version = "0.1.0"

[tasks]
plot = "Rscript plot.R"

[dependencies]
r-base = ">=4.5.1,<4.6"
conda-ecosystem-user-package-isolation = ">=1.0,<2"
r-askpass = ">=1.2.1,<2"
r-cli = ">=3.6.5,<4"
r-jsonlite = ">=2.0.0,<3"
r-processx = ">=3.8.6,<4"
r-rlang = ">=1.1.6,<2"
r-readr = ">=2.1.5,<3"
EOF

cat > .gitignore <<'EOF'
# pixi environments
.pixi/*
!.pixi/config.toml
EOF

cat > .gitattributes <<'EOF'
# SCM syntax highlighting & preventing 3-way merges
pixi.lock merge=binary linguist-language=YAML linguist-generated=true -diff
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

cat > plot.R <<'EOF'
library(readr)
library(ggplot2)

counts <- read_csv("counts.csv")
ggplot(counts, aes(year, count, colour = species)) +
  geom_line()
ggsave("counts.png", width = 7, height = 4)
EOF

git init -q
git add -A
git -c user.name="Sam Doe" -c user.email="sam@example.org" commit -q -m "Plot bird counts"
