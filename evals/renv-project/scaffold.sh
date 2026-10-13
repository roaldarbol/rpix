#!/usr/bin/env bash
# An R project managed with renv, without Pixi
set -euo pipefail

cat > renv.lock <<'EOF'
{
  "R": {
    "Version": "4.5.1",
    "Repositories": [
      {
        "Name": "CRAN",
        "URL": "https://cloud.r-project.org"
      }
    ]
  },
  "Packages": {
    "readr": {
      "Package": "readr",
      "Version": "2.1.5",
      "Source": "Repository",
      "Repository": "CRAN"
    },
    "renv": {
      "Package": "renv",
      "Version": "1.1.5",
      "Source": "Repository",
      "Repository": "CRAN"
    }
  }
}
EOF

cat > .Rprofile <<'EOF'
source("renv/activate.R")
EOF

mkdir -p renv
cat > renv/activate.R <<'EOF'
# renv's bootstrap script, abridged for this example
local({
  version <- "1.1.5"
  # ...
})
EOF

cat > import.R <<'EOF'
library(readr)

survey <- read_csv("survey.csv")
EOF
