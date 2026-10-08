# pixi_add() explains packages that aren't built for the project's R

    Code
      pixi_add(c("languageserver", "praise"))
    Condition
      Error in `pixi_add()`:
      ! r-praise isn't built for the project's version of R yet.
      i conda-forge builds packages for a new version of R some time after it's out.
      i Use R 4.5, the newest it's built for: `pixi_add(c("r-base=4.5", "languageserver", "praise"))`.
      Caused by error:
      ! pixi failed

# pixi_add() offers to build CRAN packages that aren't on conda-forge

    Code
      pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1"))
    Message
      ! fortunes isn't on conda-forge.

# pixi_add() says how to build them when it can't ask, or the answer is no

    Code
      pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1"))
    Condition
      Error in `pixi_add()`:
      ! fortunes and cowsay aren't on conda-forge.
      i Pixi can build them from CRAN's source: `pixi_add(c("github::cran/fortunes@1.5-4", "github::cran/cowsay"))`.

---

    Code
      pixi_add(c("fortunes", "cowsay>=1"))
    Message
      ! fortunes and cowsay aren't on conda-forge.
      i A version range doesn't apply to a build from source, so cowsay would be the latest version. Use `==` for a particular one.
    Condition
      Error in `pixi_add()`:
      ! Didn't add fortunes and cowsay.
      i Pixi can build them from CRAN's source: `pixi_add(c("github::cran/fortunes", "github::cran/cowsay"))`.

