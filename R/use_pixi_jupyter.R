#' Use Jupyter notebooks with the project's R
#'
#' @description
#' **Experimental.** This may change, see
#' <https://github.com/roaldarbol/rpix/issues/184>.
#'
#' Set the project up for Jupyter notebooks, so they run with the R of the
#' project's environments. It installs what it adds below into those
#' environments.
#'
#' * It adds a `jupyter` environment with JupyterLab, of its own, so the
#'   environments with R don't get Python and JupyterLab.
#' * It adds IRkernel (`r-irkernel`) to each environment with R, and, where an
#'   environment has Python, `ipykernel`.
#' * It writes a kernel for each of those environments into the project, in
#'   `.jupyter/kernels/`, named e.g. "R (Pixi: default)" or "R (Pixi: r44)".
#'   A kernel starts its environment's R with `pixi run --environment`, so
#'   Pixi activates the environment, also on Windows. The kernels have no
#'   paths of this computer in them, so commit them with the project.
#' * It adds a `jupyter` task that starts JupyterLab with those kernels:
#'   `pixi_run("jupyter")`, or `pixi run jupyter` in a terminal.
#'
#' rpix doesn't use the `ir` kernel that conda-forge's IRkernel brings, as a
#' kernel of that name in your own Jupyter folder, e.g. from
#' `IRkernel::installspec()`, would be used instead.
#'
#' Run it again after adding an environment, to add that environment's
#' kernel.
#'
#' @inheritParams pixi_add
#' @returns The path to the project's manifest, invisibly.
#' @export
#' @examples
#' \dontrun{
#' # Needs Pixi, and adds JupyterLab and IRkernel to the project
#' use_pixi_jupyter()
#' pixi_run("jupyter")
#' }
use_pixi_jupyter <- function(path = NULL) {
  root <- require_project(path)
  cli::cli_alert_info(
    "Jupyter notebooks with the project's R are experimental: see {.url https://github.com/roaldarbol/rpix/issues/184}."
  )
  envs <- pixi_info(root)$environments_info
  envs <- envs[envs$name != "jupyter", ]
  dependencies <- lapply(envs$dependencies, unlist)
  with_r <- vapply(dependencies, function(d) "r-base" %in% d, logical(1))
  with_python <- vapply(dependencies, function(d) "python" %in% d, logical(1))
  if (!any(with_r)) {
    cli::cli_abort(c(
      "No environment of the project has R.",
      "i" = "Add it with {.code rpix::use_pixi()}."
    ))
  }

  # The kernels' packages, in the feature each environment gets its packages
  # from: the default one, or else its first
  manifest <- find_manifest(root)
  for (i in which(with_r | with_python)) {
    features <- unlist(envs$features[[i]])
    feature <- if ("default" %in% features) NULL else features[1]
    packages <- c(
      if (with_r[i]) "r-irkernel",
      if (with_python[i]) "ipykernel"
    )
    lines <- readLines(manifest, warn = FALSE)
    missing <- packages[!feature_has(lines, feature, packages)]
    if (length(missing) > 0) {
      run_pixi(
        c("add", "--no-install", missing, scope_args(feature, NULL)),
        path = root,
        echo = TRUE
      )
    }
  }

  add_jupyter_environment(root)

  kernels <- c(
    stats::setNames(rep("R", sum(with_r)), envs$name[with_r]),
    stats::setNames(rep("Python", sum(with_python)), envs$name[with_python])
  )
  for (i in seq_along(kernels)) {
    write_kernel(root, names(kernels)[i], kernels[[i]])
  }
  cli::cli_alert_success(
    "Wrote {cli::qty(length(kernels))}the kernel{?s} {.val {kernel_names(kernels)}} in {.path .jupyter/kernels}."
  )
  hint(
    "Start JupyterLab with {.code rpix::pixi_run(\"jupyter\")}, and pick a kernel such as {.val R (Pixi: default)}."
  )
  invisible(manifest)
}

# JupyterLab in an environment of its own, and a task that starts it with
# the project's kernels
add_jupyter_environment <- function(root) {
  manifest <- find_manifest(root)
  lines <- readLines(manifest, warn = FALSE)
  if (!feature_has(lines, "jupyter", "jupyterlab")) {
    run_pixi(
      c("add", "--feature", "jupyter", "--no-install", "jupyterlab"),
      path = root
    )
  }
  if (feature_unused("jupyter", root)) {
    run_pixi(
      c(
        "workspace",
        "environment",
        "add",
        "jupyter",
        "--feature",
        "jupyter",
        "--no-default-feature"
      ),
      path = root
    )
    # Pins JupyterLab, which Pixi leaves at * until an environment uses it
    run_pixi(
      c("upgrade", "--feature", "jupyter", "--no-install"),
      path = root
    )
  }
  run_pixi(
    c("task", "remove", "jupyter", "--feature", "jupyter"),
    path = root
  )
  run_pixi(
    c(
      "task",
      "add",
      "jupyter",
      "jupyter lab",
      "--feature",
      "jupyter",
      "--env",
      "JUPYTER_PATH=$PIXI_PROJECT_ROOT/.jupyter",
      "--description",
      "Start JupyterLab with the project's kernels"
    ),
    path = root,
    echo = TRUE
  )
}

# Whether a feature's dependencies have each of the packages
feature_has <- function(lines, feature, packages) {
  rows <- table_lines(lines, dependency_table(feature))
  vapply(
    packages,
    function(package) {
      pattern <- paste0(
        '^\\s*"?',
        gsub(".", "\\.", package, fixed = TRUE),
        '"?\\s*='
      )
      any(grepl(pattern, lines[rows]))
    },
    logical(1),
    USE.NAMES = FALSE
  )
}

kernel_names <- function(kernels) {
  paste0(kernels, " (Pixi: ", names(kernels), ")")
}

# A kernel that starts the environment's R, or Python, through pixi run
write_kernel <- function(root, environment, language) {
  name <- paste0("pixi-", environment, if (language == "Python") "-python")
  folder <- file.path(root, ".jupyter", "kernels", name)
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  run <- c("pixi", "run", "--environment", environment)
  argv <- if (language == "R") {
    c(
      run,
      "R",
      "--slave",
      "-e",
      "IRkernel::main()",
      "--args",
      "{connection_file}"
    )
  } else {
    c(run, "python", "-m", "ipykernel_launcher", "-f", "{connection_file}")
  }
  spec <- list(
    argv = argv,
    display_name = paste0(language, " (Pixi: ", environment, ")"),
    language = tolower(language)
  )
  jsonlite::write_json(
    spec,
    file.path(folder, "kernel.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )
  invisible(folder)
}
