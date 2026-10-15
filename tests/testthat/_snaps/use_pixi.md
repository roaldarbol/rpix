# use_pixi() leaves Pixi's files out of a package's builds

    Code
      use_pixi(path = dir, install_rpix = FALSE)
    Message
      v Added `^\.pixi$`, `^pixi\.toml$`, and `^pixi\.lock$` to '.Rbuildignore'.
      v Turned on Pixi's activation cache in '.pixi/config.toml', so R starts faster through Pixi.
      v Set up '<dir>' for R.
      i Start R from the project's environment, e.g. with `pixi run R`, or set up your IDE with `use_pixi(ide = ...)`.

