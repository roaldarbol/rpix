# pixi_install() takes locked or frozen, not both

    Code
      pixi_install(locked = TRUE, frozen = TRUE)
    Condition
      Error in `pixi_install()`:
      ! Use `locked` or `frozen`, not both.
      i `locked` fails if 'pixi.lock' is out of date; `frozen` doesn't check.

