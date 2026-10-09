# secrets are hidden in commands, output and errors

    Code
      run_pixi(c("auth", "login", "x", "--token", "s3cr3t"), project = "none",
      dry_run = TRUE, secrets = "s3cr3t")
    Message
      i Would run: `pixi auth login x --token <hidden>`

