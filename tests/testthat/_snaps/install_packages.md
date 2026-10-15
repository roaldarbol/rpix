# install.packages() adds packages with Pixi

    Code
      install_with_pixi(c("dplyr", "DESeq2"), root = "/p")
    Message
      i Adding dplyr and DESeq2 with Pixi, so they're recorded in 'pixi.toml'.

# install.packages() explains what Pixi can't do

    Code
      install_with_pixi("dplyr", lib = "/lib", repos = "https://cran.r-project.org",
        root = "/p")
    Condition
      Error:
      ! In a Pixi environment, `install.packages()` adds packages with Pixi, which can't use `lib`.
      i Give package names, e.g. `install.packages("dplyr")`.
      i For a package that isn't on conda-forge, Pixi can build it from source: `pixi_add("github::user/repo")`.

# install.packages() takes packages from conda-forge, not `repos`

    Code
      install_with_pixi(c("later", "rstudioapi"), repos = "https://cran.r-project.org/",
      root = "/p")
    Message
      i Pixi takes packages from conda-forge and bioconda, not `repos`.
      i Adding later and rstudioapi with Pixi, so they're recorded in 'pixi.toml'.

# install.packages() leaves package files to utils

    Code
      install_with_pixi("/ext/sess", repos = NULL, type = "source", root = "/p")
    Message
      i Installing '/ext/sess' with `utils::install.packages()`, as Pixi can't add package files. 'pixi.toml' doesn't record it.

