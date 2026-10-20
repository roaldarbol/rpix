# pixi_update() shows what would change and asks first

    Code
      pixi_update()
    Message
      In the "default" environment (osx-64):
      * cli: 3.6.4 > 3.6.6
      * and 2 packages that these depend on

# pixi_upgrade(r = TRUE) says what upgrading R means

    Code
      pixi_upgrade(r = TRUE)
    Message
      In the "default" environment (osx-64):
      * R: 4.4.3 > 4.5.3
      * cli: 3.6.6 (a new build)
      ! This upgrades R, so every R package changes to a build for the new R.

# in the running R's environment, it says to restart, and leaves Windows' to later

    Code
      pixi_upgrade()
    Message
      i Leaving R as it is. To upgrade it too, use `rpix::pixi_upgrade(r = TRUE)`.
      ! 'pixi.lock' has the new versions, but the "default" environment doesn't yet: on Windows, Pixi can't replace the files of packages that this R has loaded.
      i Close R, then install it with `pixi install` in a terminal in the project, or with `rpix::pixi_install()` from R outside the project's environment, such as your usual R.

