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
      i Packages from GitHub are experimental: see <https://github.com/roaldarbol/rpix/issues/96>.
      ~ Building hadley/emo with `pixi-build-r`, which can take a minute...
      v Built hadley/emo from source [time]
      

# pixi_add() adds what builds on Windows need, in projects for Windows

    Code
      pixi_add("github::hadley/emo", path = calls$dir)
    Message
      i On Windows, rpix adds MSYS2's build tools, and MinGW's compilers in place of `pixi-build-r`'s, until `pixi-build-r` does this itself.
      i Packages from GitHub are experimental: see <https://github.com/roaldarbol/rpix/issues/96>.
      ~ Building hadley/emo with `pixi-build-r`, which can take a minute...
      v Built hadley/emo from source [time]
      

# pixi_add() says what it adds to a GitHub package's build

    Code
      pixi_add("github::me/javan", path = calls$dir)
    Message
      i Adding openjdk to the build of r-javan, as `pixi-build-r` doesn't yet.
      i Packages from GitHub are experimental: see <https://github.com/roaldarbol/rpix/issues/96>.
      ~ Building me/javan with `pixi-build-r`, which can take a minute...
      v Built me/javan from source [time]
      

# pixi_add() refuses a GitHub package when the project's date hides pixi-build-r 0.2

    Code
      pixi_add("github::me/rusty", path = calls$dir)
    Condition
      Error in `pixi_add()`:
      ! The project uses packages as of "2026-09-01", which hides the `pixi-build-r` that builds packages from GitHub.
      i `exclude-newer` applies to Pixi's build backend too, and `pixi-build-r` 0.2.0 came out on 2026-10-14. Use a later date, e.g. with `pixi_set_date()`.

# pixi_add() explains a failed build in a project with a date

    Code
      pixi_add("github::hadley/emo", path = calls$dir)
    Message
      i Packages from GitHub are experimental: see <https://github.com/roaldarbol/rpix/issues/96>.
      ~ Building hadley/emo with `pixi-build-r`, which can take a minute...
      x Building hadley/emo with `pixi-build-r`, which can take a minute... [time]
      
    Output
      build failed
    Condition
      Error in `pixi_add()`:
      ! Pixi couldn't build github::hadley/emo, so 'pixi.toml' is as it was.
      i See Pixi's output above.
      i The project's `exclude-newer = "7d"` applies to Pixi's build backend too, and may hide `pixi-build-r` 0.2.0, from 2026-10-14. See `?rpix::pixi_set_date()`.
      Caused by error:
      ! `pixi install` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() puts pixi.toml back if Pixi can't build the package

    Code
      pixi_add("github::hadley/emo", path = calls$dir)
    Message
      i Packages from GitHub are experimental: see <https://github.com/roaldarbol/rpix/issues/96>.
      ~ Building hadley/emo with `pixi-build-r`, which can take a minute...
      x Building hadley/emo with `pixi-build-r`, which can take a minute... [time]
      
    Output
      build failed
    Condition
      Error in `pixi_add()`:
      ! Pixi couldn't build github::hadley/emo, so 'pixi.toml' is as it was.
      i See Pixi's output above.
      Caused by error:
      ! `pixi install` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() shows what it would add to pixi.toml

    Code
      pixi_add("github::hadley/emo", path = calls$dir, dry_run = TRUE)
    Message
      i Would add to 'pixi.toml': `r-emo = { git = "https://github.com/hadley/emo", package = { build.backend.name = "pixi-build-r", build.backend.version = ">=0.2", host-dependencies = { r-base = "4.5.*" } } }`

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

