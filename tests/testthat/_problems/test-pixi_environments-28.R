# Extracted from test-pixi_environments.R:28

# test -------------------------------------------------------------------------
local_recorded_pixi(list(
    environments_info = data.frame(
      name = c("default", "r44"),
      features = I(list("default", c("r44", "default"))),
      solve_group = c(NA, "main"),
      platforms = I(list(
        data.frame(name = "osx-64"),
        data.frame(name = c("osx-64", "linux-64"))
      ))
    )
  ))
