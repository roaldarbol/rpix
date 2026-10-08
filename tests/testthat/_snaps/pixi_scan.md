# pixi_scan() compares the code's packages with pixi.toml

    Code
      result <- pixi_scan()
    Message
      i The code uses 7 packages.
      ! Not in 'pixi.toml': DESeq2 and ggplot2.
        Add them with `pixi_scan(add = TRUE)`.
      i Never used in the code: r-tibble.

# pixi_scan() can add the missing packages

    Code
      pixi_scan(add = TRUE)
    Message
      i The code uses 7 packages.
      ! Not in 'pixi.toml': DESeq2 and ggplot2.
      i Never used in the code: r-tibble.
      ! Not on conda-forge or bioconda, so not added: DESeq2.

# pixi_scan() says when pixi.toml has everything

    Code
      result <- pixi_scan()
    Message
      i The code uses 1 package.
      v 'pixi.toml' has all of them.

