# says once that PIXI_WORKSPACE_ROOT points elsewhere

    Code
      invisible(find_manifest())
    Message
      ! `PIXI_WORKSPACE_ROOT` points to '<original>', so using the working directory's project, '<copy>'.
      i If the project was copied or moved, check it with `pixi_sitrep()`.
      This message is displayed once per session.

# offers to install Pixi in an interactive session

    Code
      pixi <- pixi_binary()
    Message
      ! rpix needs Pixi, which isn't installed.

# secrets are hidden in commands, output and errors

    Code
      run_pixi(c("auth", "login", "x", "--token", "s3cr3t"), project = "none",
      dry_run = TRUE, secrets = "s3cr3t")
    Message
      i Would run: `pixi auth login x --token <hidden>`

# errors from a channel that refused access suggest logging in

    Code
      abort_pixi_failure("pixi add r-x", result, echoed = TRUE, call = NULL)
    Condition
      Error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.
      i "127.0.0.1:8765" refused access (401), so Pixi probably needs credentials for it.
      i Log in with `pixi_auth_login("127.0.0.1:8765")`, and see `pixi_auth_login()` for other ways to log in.

