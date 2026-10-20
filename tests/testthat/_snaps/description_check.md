# the watcher offers to add what DESCRIPTION comes to need

    Code
      watcher()
    Message
      i 'DESCRIPTION' now needs rlang, which isn't in 'pixi.toml'.

# the watcher says how to add them when the answer is no

    Code
      watcher()
    Message
      i 'DESCRIPTION' now needs rlang and praise, which aren't in 'pixi.toml'.
        Add them with `rpix::pixi_import_description()`.

# the watcher says when DESCRIPTION drops a package

    Code
      watcher()
    Message
      i 'DESCRIPTION' no longer lists cli. If nothing else in the project uses it, remove it with `rpix::pixi_remove("cli")`.

