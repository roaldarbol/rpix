#' Use Python alongside R, for reticulate
#'
#' @description
#' **Experimental.** This may change, see
#' <https://github.com/roaldarbol/rpix/issues/108>.
#'
#' Add Python to the project's environment, and point reticulate at it, so
#' Python and its packages are in the same environment and `pixi.lock` as R
#' and its packages. It installs what it adds below into that environment.
#'
#' * It adds `python` (at `python_version`, if given), `r-reticulate`, and
#'   for Python 3.15 or later `libpython`: conda-forge has Python's shared
#'   library, which reticulate loads, apart from Python since 3.15.
#' * It sets `RETICULATE_PYTHON` to the environment's Python, in
#'   `pixi.toml`'s `[activation.env]`, so R started with `pixi run` uses it,
#'   and so does R started by an IDE, through the project's `.Rprofile`
#'   ([pixi_activate()]). Without it, reticulate uses a Python of its own.
#' * It adds `micromamba`, and points `RETICULATE_CONDA` to it: reticulate
#'   activates a conda environment again with a conda program before it uses
#'   its Python, and a Pixi project doesn't have one
#'   (<https://github.com/rstudio/reticulate/issues/1650>).
#'
#' Add Python packages with [pixi_add()]: `pixi_add("conda::numpy")` from
#' conda-forge, or `pixi_add("pypi::pydytuesday")` from PyPI. reticulate's
#' `py_require()` doesn't install into the project's Python.
#'
#' Restart R afterwards, so reticulate finds the environment's Python. The
#' Windows settings are written only if the project has `win-64`: if you add
#' it later, run `use_pixi_python()` again.
#'
#' @param python_version Optional. The Python version, such as `"3.13"`.
#'   Defaults to the newest one that solves with the project.
#' @inheritParams pixi_add
#' @returns The path to the project's manifest, invisibly.
#' @export
#' @examples
#' \dontrun{
#' # Needs Pixi, and adds Python to the project
#' use_pixi_python()
#' pixi_add(c("conda::numpy", "pypi::pydytuesday"))
#' }
use_pixi_python <- function(python_version = NULL, path = NULL) {
  root <- require_project(path)
  cli::cli_alert_info(
    "Python in the project is experimental: see {.url https://github.com/roaldarbol/rpix/issues/108}."
  )
  python <- if (is.null(python_version)) {
    "python"
  } else {
    paste0("python=", python_version)
  }
  add_missing(c(python, "r-reticulate", "micromamba"), root)
  # Python 3.15 and later keep the shared library apart
  version <- installed_python_version(root)
  if (!is.na(version) && version >= "3.15") {
    add_missing("libpython", root)
  }

  manifest <- find_manifest(root)
  lines <- readLines(manifest, warn = FALSE)
  # Pixi warns about tables for platforms the project doesn't have
  windows <- "win-64" %in% project_platforms(root)
  writeLines(set_python_activation(lines, manifest, windows), manifest)
  cli::cli_alert_success(
    "Set {.envvar RETICULATE_PYTHON} and {.envvar RETICULATE_CONDA} in {.file {basename(manifest)}}, so reticulate uses the environment's Python."
  )
  hint(
    "Restart R, then add Python packages with e.g. {.code rpix::pixi_add(\"conda::numpy\")}, or {.code rpix::pixi_add(\"pypi::pydytuesday\")} from PyPI."
  )
  invisible(manifest)
}

# The environment's Python version, or NA
installed_python_version <- function(root) {
  packages <- tryCatch(pixi_list(path = root), error = function(e) NULL)
  version <- packages$version[packages$name == "python"]
  if (length(version) == 0) {
    return(package_version(NA_character_, strict = FALSE))
  }
  package_version(version[1], strict = FALSE)
}

# reticulate's settings, in [activation.env]. On Windows, Pixi doesn't expand
# $CONDA_PREFIX, and Python and micromamba are elsewhere.
set_python_activation <- function(lines, manifest, windows = TRUE) {
  prefix <- if (basename(manifest) == "pyproject.toml") "tool.pixi." else ""
  entries <- list(
    "activation.env" = c(
      RETICULATE_PYTHON = "$CONDA_PREFIX/bin/python",
      RETICULATE_CONDA = "$CONDA_PREFIX/bin/micromamba"
    ),
    "target.win-64.activation.env" = c(
      RETICULATE_PYTHON = "%CONDA_PREFIX%\\\\python.exe",
      RETICULATE_CONDA = "%CONDA_PREFIX%\\\\Library\\\\bin\\\\micromamba.exe"
    )
  )
  if (!windows) {
    entries <- entries[1]
  }
  for (table in names(entries)) {
    for (name in names(entries[[table]])) {
      lines <- set_dependency(
        lines,
        paste0(prefix, table),
        name,
        paste0(name, ' = "', entries[[table]][[name]], '"')
      )
    }
  }
  lines
}
