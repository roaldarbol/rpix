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

# sets the editors up with languageserver and direnv

    Code
      file <- setup(p$root)
    Message
      v Set '.envrc' to activate the "default" environment.
      i Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
      i In Emacs, install the envrc package and turn on `(envrc-global-mode)`. ESS and languageserver then use the project's R.

---

    Code
      file <- setup(p$root)
    Message
      v Set '.envrc' to activate the "default" environment.
      i Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
      i Start Neovim from a shell with direnv's hook, or load direnv with a plugin such as direnv.vim. R.nvim and languageserver then use the project's R.

---

    Code
      file <- setup(p$root)
    Message
      v Set '.envrc' to activate the "default" environment.
      i Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
      i Zed loads direnv itself. With its R extension, languageserver uses the project's R, and so does R in Zed's terminal.

# adds only what's missing, and sets direnv up once

    Code
      use_pixi_emacs(p$root)
    Message
      v Set '.envrc' to activate the "default" environment.
      i Install direnv with `pixi global install direnv`, and hook it into your shell (<https://direnv.net/docs/hook.html>). Then run `direnv allow` in the project.
      i In Emacs, install the envrc package and turn on `(envrc-global-mode)`. ESS and languageserver then use the project's R.
    Code
      use_pixi_neovim(p$root)
    Message
      i Start Neovim from a shell with direnv's hook, or load direnv with a plugin such as direnv.vim. R.nvim and languageserver then use the project's R.

