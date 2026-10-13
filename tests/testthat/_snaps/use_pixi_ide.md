# makes the environment's R Positron's default, or leaves it out

    Code
      use_pixi_positron(p$root)
    Message
      v Updated '.vscode/settings.json'.
      i Positron (2026.10 or later) now starts the project's R when you open the project; restart it if it's open. If you've picked another R in this project before, pick "R (Pixi: default)" once.

---

    Code
      use_pixi_positron(q$root, default_r = FALSE)
    Message
      v Updated '.vscode/settings.json'.
      i In Positron, pick "R (Pixi: default)" in the interpreter picker. Positron remembers it for the project. If it isn't listed, run Interpreter: Discover All Interpreters from the Command Palette.

