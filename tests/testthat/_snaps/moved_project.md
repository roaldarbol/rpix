# removes the activation cache of another location, and says so

    Code
      remove_stale_activation_cache(root)
    Message
      ! The project was moved or copied, so rpix removed Pixi's activation cache, which had its old location.
    Output
      [1] TRUE

# says to reinstall moved environments

    Code
      cli::cli_bullets(moved_environments_bullets(c(default = "/old/project")))
    Message
      ! The "default" environment was installed in '/old/project', and Pixi's
        environments can't be moved, so its R still points there.
      i Reinstall it with `pixi clean` and `pixi install --all` in a terminal, in the
        project.
    Code
      cli::cli_bullets(moved_environments_bullets(c(default = "/old/project", test = "/old/project")))
    Message
      ! The "default" and "test" environments were installed in '/old/project', and
        Pixi's environments can't be moved, so their R still points there.
      i Reinstall them with `pixi clean` and `pixi install --all` in a terminal, in
        the project.

