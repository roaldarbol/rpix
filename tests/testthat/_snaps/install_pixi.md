# install_pixi() leaves an installed Pixi alone

    Code
      path <- install_pixi()
    Message
      v Pixi is installed already, at '/usr/local/bin/pixi'.
      i Update it with `pixi self-update` in a terminal, or reinstall it with `install_pixi(force = TRUE)`.

# install_pixi() asks, then runs Pixi's installer

    Code
      path <- install_pixi()
    Message
      i Pixi's official installer will:
        * put Pixi in '/home/me/.pixi/bin'
        * add it to your shell's `PATH`, so `pixi` works in a terminal
      v Installed pixi 0.81.0 at '/home/me/.pixi/bin/pixi'.
      i Open a new terminal to use `pixi` there.

# install_pixi() stops if the answer is no, or something fails

    Code
      install_pixi()
    Message
      i Pixi's official installer will:
        * put Pixi in '/home/me/.pixi/bin'
        * add it to your shell's `PATH`, so `pixi` works in a terminal
    Condition
      Error:
      ! Couldn't download Pixi's installer from <https://pixi.sh/install.sh>.
      i Check your internet connection, or install Pixi as <https://pixi.prefix.dev/latest/installation/> describes.

---

    Code
      install_pixi()
    Message
      i Pixi's official installer will:
        * put Pixi in '/home/me/.pixi/bin'
        * add it to your shell's `PATH`, so `pixi` works in a terminal
    Condition
      Error:
      ! Pixi's installer failed, with exit status 1.
      i See its output above, or install Pixi as <https://pixi.prefix.dev/latest/installation/> describes.

