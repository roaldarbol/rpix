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
      ! In a Pixi environment, `install.packages()` adds packages with Pixi, which can't use `lib` and `repos`.
      i Give package names, e.g. `install.packages("dplyr")`.
      i For a package that isn't on conda-forge, Pixi can build it from source: `pixi_add("github::user/repo")`.
    Code
      install_with_pixi("~/dplyr_1.1.4.tar.gz", root = "/p")
    Condition
      Error:
      ! In a Pixi environment, `install.packages()` adds packages with Pixi, which can't use package files.
      i Give package names, e.g. `install.packages("dplyr")`.
      i For a package that isn't on conda-forge, Pixi can build it from source: `pixi_add("github::user/repo")`.

