# pixi_install() takes locked or frozen, not both

    Code
      pixi_install(locked = TRUE, frozen = TRUE)
    Condition
      Error in `pixi_install()`:
      ! Use `locked` or `frozen`, not both.
      i `locked` fails if 'pixi.lock' is out of date; `frozen` doesn't check.

# pixi_add_environment(r_version = ) installs it, and says what it didn't copy

    Code
      pixi_add_environment("r44", r_version = "4.4", path = root)
    Message
      i Adding the "r44" environment, with R 4.4 and the project's 2 packages.
      v Added the "r44" environment, with R 4.4.
      i Not copied, as it's built from source: r-mypkg. Add it to the environment with `rpix::pixi_add(..., feature = "r44")`.
        Switch to it with `rpix::pixi_switch("r44")`.

