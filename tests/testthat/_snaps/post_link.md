# check_post_link() offers to allow them, and installs the packages again

    Code
      out <- check_post_link(list(stderr = skipped_output), environment = "test")
    Message
      ! bioconductor-org.hs.eg.db isn't fully installed: Pixi didn't run its install script.
      i Bioconductor's annotation and data packages, for example, download their data
        that way. The scripts run with your permissions, so Pixi only runs them in
        projects that allow it.
      v Allowed install scripts in this project, in '.pixi/config.toml'.
      i '.pixi/config.toml' isn't shared with the project, so others need to allow them too, e.g. when `pixi_install()` asks.

# check_post_link() says how to run them when it can't ask, or the answer is no

    Code
      check_post_link(list(stderr = skipped_output))
    Condition
      Warning:
      bioconductor-org.hs.eg.db isn't fully installed: Pixi didn't run its install script.
      i Bioconductor's annotation and data packages, for example, download their data that way. The scripts run with your permissions, so Pixi only runs them in projects that allow it.
      i To run it, allow install scripts in this project with `pixi config set --local run-post-link-scripts insecure`, then run `pixi reinstall bioconductor-org.hs.eg.db`.

---

    Code
      check_post_link(list(stdout = "WARN Skipped running the post-link scripts"))
    Condition
      Warning:
      Some packages aren't fully installed: Pixi didn't run their install scripts.
      i Bioconductor's annotation and data packages, for example, download their data that way. The scripts run with your permissions, so Pixi only runs them in projects that allow it.
      i To run them, allow install scripts in this project with `pixi config set --local run-post-link-scripts insecure`, then run `pixi reinstall`.

