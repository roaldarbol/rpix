# use_pixi_github_action() writes a check workflow from the template

    Code
      file <- use_pixi_github_action("check", c("r44", "minimum"))
    Message
      v Wrote '.github/workflows/pixi-check.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

# use_pixi_github_action() runs only where the project has platforms

    Code
      use_pixi_github_action("check")
    Message
      i Not on "macos-latest" and "windows-latest": the project doesn't have "osx-arm64" and "win-64". Add them with `pixi_add_platform()`.
      v Wrote '.github/workflows/pixi-check.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

---

    Code
      use_pixi_github_action("check")
    Condition
      Error in `use_pixi_github_action()`:
      ! The project has none of the platforms GitHub runs: "linux-64", "osx-arm64", and "win-64".
      i Add one with `pixi_add_platform("linux-64")`.

# use_pixi_github_action() says what the environment lacks

    Code
      use_pixi_github_action("pkgdown")
    Message
      ! The workflow needs pkgdown and conda::pandoc, which aren't in 'pixi.toml'. Add them, e.g. with `pixi_add()`.
      v Wrote '.github/workflows/pixi-pkgdown.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

# use_pixi_github_action() doesn't replace a workflow unless asked

    Code
      use_pixi_github_action("check")
    Condition
      Error in `use_pixi_github_action()`:
      ! '.github/workflows/pixi-check.yaml' is there already.
      i Replace it with `overwrite = TRUE`.

