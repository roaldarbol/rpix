# use_pixi() says when conda-forge has no R packages for the R asked for

    Code
      use_pixi(r_version = "4.6", path = dir)
    Condition
      Error in `use_pixi()`:
      ! conda-forge has no R packages for R 4.6 yet; R 4.5 is the newest you can use.
      i Use it with `use_pixi(r_version = "4.5")`.
      Caused by error:
      ! pixi failed

# use_pixi() leaves Pixi's files out of a package's builds

    Code
      use_pixi(path = dir, install_rpix = FALSE)
    Message
      v Added `^\.pixi$`, `^pixi\.toml$`, and `^pixi\.lock$` to '.Rbuildignore'.
      i Adding r-cli with R, so Pixi picks an R that conda-forge has R packages for, then removing it.
      v Turned on Pixi's activation cache in '.pixi/config.toml', so R starts faster through Pixi.
      v Set up '<dir>' for R.
      i Start R from the project's environment, e.g. with `pixi run R`, or set up your IDE with `use_pixi(ide = ...)`.

