# pixi_switch() needs an environment of the project

    Code
      pixi_switch("r43", ide = "rstudio")
    Condition
      Error in `pixi_switch()`:
      ! There's no "r43" environment in the project.
      i Its environments are "default" and "r44".

# pixi_switch() installs the environment, and shows how to start it

    Code
      r <- pixi_switch("r44")
    Message
      i Start its R with `pixi run --environment r44 R`.

# pixi_switch() starts a new RStudio with the environment's R

    Code
      pixi_switch("r44", ide = "rstudio")
    Message
      v Started RStudio with the "r44" environment's R. Close this RStudio when you're done with it.

# pixi_switch() opens Positron's interpreter picker

    Code
      pixi_switch("r44", ide = "positron")
    Message
      i Pick the R labelled "(Pixi: r44)" in the interpreter picker.

# pixi_switch() points VS Code at the environment's R

    Code
      pixi_switch("r44", ide = "vscode")
    Message
      v Updated '.vscode/settings.json'.
      i Run Developer: Reload Window from the Command Palette to use it.

# pixi_switch() tells VS Code users on Windows to restart it

    Code
      pixi_switch("r44", ide = "vscode")
    Message
      i Close VS Code, and start it again from the environment with `pixi run --environment r44 code .`.

