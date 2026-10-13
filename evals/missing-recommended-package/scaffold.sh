#!/usr/bin/env bash
# A Pixi project for R whose script uses MASS, which isn't in pixi.toml
set -euo pipefail

cat > pixi.toml <<'EOF'
[workspace]
authors = ["Sam Doe <sam@example.org>"]
channels = ["conda-forge"]
name = "growth-curves"
platforms = ["osx-arm64", "linux-64", "win-64"]
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
r-dplyr = ">=1.1.4,<2"
r-ggplot2 = ">=3.5.2,<4"
EOF

cat > .gitignore <<'EOF'
# pixi environments
.pixi/*
!.pixi/config.toml
EOF

cat > analysis.R <<'EOF'
library(MASS)
library(dplyr)
library(ggplot2)

growth <- read.csv("growth.csv")
fit <- rlm(weight ~ day * treatment, data = growth)
summary(fit)

growth |>
  mutate(fitted = fitted(fit)) |>
  ggplot(aes(day, weight, colour = treatment)) +
  geom_point() +
  geom_line(aes(y = fitted))
ggsave("growth.png")
EOF
