# install.packages() adds packages with Pixi

    Code
      install_with_pixi(c("dplyr", "DESeq2"), root = "/p")
    Message
      i Adding dplyr and DESeq2 with Pixi, so they're recorded in 'pixi.toml'.

# install.packages() explains what Pixi can't do

    Code
      install_with_pixi("notonconda", root = "/p")
    Condition
      Error:
      ! notonconda isn't on conda-forge or bioconda, so Pixi can't add it.
      i To install outside Pixi, so it isn't recorded in 'pixi.toml', use `utils::install.packages()`.
      i Turn this off with `options(rpix.install_packages = FALSE)`.
    Code
      install_with_pixi("dplyr", lib = "/lib", repos = "https://cran.r-project.org",
        root = "/p")
    Condition
      Error:
      ! In a Pixi environment, `install.packages()` adds packages with Pixi, which can't use `lib` and `repos`.
      i To install outside Pixi, so it isn't recorded in 'pixi.toml', use `utils::install.packages()`.
    Code
      install_with_pixi("~/dplyr_1.1.4.tar.gz", root = "/p")
    Condition
      Error:
      ! In a Pixi environment, `install.packages()` adds packages with Pixi, which can't use package files.
      i To install outside Pixi, so it isn't recorded in 'pixi.toml', use `utils::install.packages()`.

