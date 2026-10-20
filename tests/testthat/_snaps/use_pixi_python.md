# use_pixi_python() adds Python and points reticulate at it

    Code
      use_pixi_python(path = calls$root)
    Message
      i Python in the project is experimental: see <https://github.com/roaldarbol/rpix/issues/108>.
      v Set `RETICULATE_PYTHON` and `RETICULATE_CONDA` in 'pixi.toml', so reticulate uses the environment's Python.
        Restart R, then add Python packages with e.g.
        `rpix::pixi_add("conda::numpy")`, or `rpix::pixi_add("pypi::humanize")` from
        PyPI.

---

    Code
      cat(readLines(file.path(calls$root, "pixi.toml")), sep = "\n")
    Output
      [workspace]
      
      [dependencies]
      r-base = "4.5.*"
      
      [activation.env]
      RETICULATE_PYTHON = "$CONDA_PREFIX/bin/python"
      RETICULATE_CONDA = "$CONDA_PREFIX/bin/micromamba"
      
      [target.win-64.activation.env]
      RETICULATE_PYTHON = "%CONDA_PREFIX%\\python.exe"
      RETICULATE_CONDA = "%CONDA_PREFIX%\\Library\\bin\\micromamba.exe"

