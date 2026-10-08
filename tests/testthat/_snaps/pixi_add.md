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

