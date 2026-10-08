# parse_github() explains bad references and missing packages

    Code
      parse_github("github::emo")
    Condition
      Error:
      ! "github::emo" isn't a GitHub package reference.
      i Use `github::user/repo`, or `github::user/repo@ref` for a branch, tag or commit.
    Code
      parse_github("github::hadley/nope")
    Condition
      Error:
      ! Couldn't read the R package in <https://github.com/hadley/nope>.
      i It needs a 'DESCRIPTION' file at the top of the repository.
    Code
      parse_github("github::hadley/nope@dev")
    Condition
      Error:
      ! Couldn't read the R package in <https://github.com/hadley/nope> at dev.
      i It needs a 'DESCRIPTION' file at the top of the repository.

# pixi_add() adds GitHub packages to pixi.toml, and Pixi installs them

    Code
      pixi_add(c("dplyr", "github::hadley/emo"), path = calls$dir)
    Message
      i Pixi builds it from source with `pixi-build-r`, which can take a minute.

# pixi_add() puts pixi.toml back if Pixi can't build the package

    Code
      pixi_add("github::hadley/emo", path = calls$dir)
    Message
      i Pixi builds it from source with `pixi-build-r`, which can take a minute.
    Condition
      Error in `pixi_add()`:
      ! Pixi couldn't build github::hadley/emo, so 'pixi.toml' is as it was.
      i See Pixi's output above.
      Caused by error in `run_pixi()`:
      ! build failed

# pixi_add() shows what it would add to pixi.toml

    Code
      pixi_add("github::hadley/emo", path = calls$dir, dry_run = TRUE)
    Message
      i Would add to 'pixi.toml': `r-emo = { git = "https://github.com/hadley/emo", package = { build.backend.name = "pixi-build-r", host-dependencies = { r-base = "4.5.*" } } }`

# versions gives a GitHub package's branch, tag or commit

    Code
      with_github_refs("github::cran/praise", ">=1.0")
    Condition
      Error:
      ! A package from GitHub takes a branch, tag or commit, not a range like ">=1.0".
      i Pixi builds it from that point in its history.
    Code
      with_github_refs("github::cran/praise@1.0.0", "1.0.0")
    Condition
      Error:
      ! Give the branch, tag or commit of "github::cran/praise@1.0.0" either with `@ref` or in `versions`, not both.

