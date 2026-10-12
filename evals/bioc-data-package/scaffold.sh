#!/usr/bin/env bash
# A Pixi project for R with Bioconductor packages from bioconda
set -euo pipefail

cat > pixi.toml <<'EOF'
[workspace]
authors = ["Sam Doe <sam@example.org>"]
channels = ["conda-forge", "bioconda"]
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
bioconductor-deseq2 = { version = ">=1.48.1,<2", channel = "bioconda" }
bioconductor-annotationdbi = { version = ">=1.70.0,<2", channel = "bioconda" }
EOF

cat > .gitignore <<'EOF'
# pixi environments
.pixi/*
!.pixi/config.toml
EOF

cat > annotate.R <<'EOF'
library(AnnotationDbi)
library(org.Hs.eg.db)

results <- readr::read_csv("results/deseq2.csv")
results$symbol <- mapIds(
  org.Hs.eg.db,
  keys = results$ensembl_id,
  keytype = "ENSEMBL",
  column = "SYMBOL"
)
readr::write_csv(results, "results/deseq2-annotated.csv")
EOF
