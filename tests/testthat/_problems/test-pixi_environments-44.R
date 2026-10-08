# Extracted from test-pixi_environments.R:44

# test -------------------------------------------------------------------------
local_recorded_pixi(list(
    environments_info = data.frame(
      name = "default",
      features = I(list("default")),
      platforms = I(list(data.frame(name = "osx-64")))
    )
  ))
