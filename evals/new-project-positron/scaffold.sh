#!/usr/bin/env bash
# A folder of R code and a Quarto report, without Pixi yet
set -euo pipefail

mkdir -p data
cat > analysis.R <<'EOF'
library(readr)
library(dplyr)
library(lme4)

plants <- read_csv("data/plants.csv")
fit <- lmer(height ~ treatment + (1 | block), data = plants)
saveRDS(fit, "fit.rds")
EOF

cat > report.qmd <<'EOF'
---
title: "Plant growth"
format: html
---

```{r}
library(ggplot2)
plants <- readr::read_csv("data/plants.csv")
ggplot(plants, aes(treatment, height)) + geom_boxplot()
```

```{r}
fit <- readRDS("fit.rds")
summary(fit)
```
EOF

cat > .gitignore <<'EOF'
.Rhistory
.RData
EOF
