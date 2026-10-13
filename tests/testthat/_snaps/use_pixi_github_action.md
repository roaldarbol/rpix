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
      i Using the environment "default", which has what the workflow needs.
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
      ! "default" lacks pkgdown and conda::pandoc, which the workflow needs. Add them with `pixi_add(c("pkgdown", "conda::pandoc"))`.
      v Wrote '.github/workflows/pixi-pkgdown.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

# use_pixi_github_action() checks in the environments that can

    Code
      use_pixi_github_action("check")
    Message
      i Using the environments "r44" and "r45", which have what the workflow needs.
      v Added `^\.github$` to '.Rbuildignore'.
      v Wrote '.github/workflows/pixi-check.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

---

    Code
      use_pixi_github_action("check", c("r44", "minimum"), overwrite = TRUE)
    Message
      ! "minimum" lacks withr, which the workflow needs. Add it with `pixi_add("withr", feature = "minimum")`.
      v Wrote '.github/workflows/pixi-check.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

# use_pixi_github_action() stops if no environment can check

    Code
      use_pixi_github_action("check")
    Condition
      Error in `use_pixi_github_action()`:
      ! No environment has what `R CMD check` needs.
      i Add environments that do with `use_pixi_check_matrix()`, or add what "test" lacks with `pixi_add("rcmdcheck", feature = "test")`.

# use_pixi_github_action() uses the first environment that has what it needs

    Code
      use_pixi_github_action("test-coverage")
    Message
      i Using the environment "test", which has what the workflow needs.
      v Added `^\.github$` to '.Rbuildignore'.
      v Wrote '.github/workflows/pixi-test-coverage.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

---

    Code
      use_pixi_github_action("pkgdown", "docs")
    Message
      ! "docs" lacks bioc::limma, which the workflow needs. Add it with `pixi_add("bioc::limma", feature = "docs")`.
      v Wrote '.github/workflows/pixi-pkgdown.yaml'. Commit it with 'pixi.toml' and 'pixi.lock'.

# use_pixi_github_action() stops at environments the project doesn't have

    Code
      use_pixi_github_action("check", "r44")
    Condition
      Error in `use_pixi_github_action()`:
      ! The project has no environment "r44".
      i Its environments are "default".

# use_pixi_github_action() doesn't replace a workflow unless asked

    Code
      use_pixi_github_action("check")
    Condition
      Error in `use_pixi_github_action()`:
      ! '.github/workflows/pixi-check.yaml' is there already.
      i Replace it with `overwrite = TRUE`.

