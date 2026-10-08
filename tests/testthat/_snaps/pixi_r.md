# pixi_r() turns errors into R errors

    Code
      pixi_r(function() stop("boom"), environment = "r44")
    Condition
      Error in `pixi_r()`:
      ! The function failed in the "r44" environment.
      x boom

