#' Set up a Pixi project for R
#'
#' @description
#' Create a Pixi project in the working directory if there isn't one, add R to
#' it, and install rpix into its environment.
#'
#' It also adds conda-forge's `conda-ecosystem-user-package-isolation`, which
#' keeps your personal R library out of the environment's R. Otherwise
#' conda-forge's R loads packages installed for your usual R first.
#'
#' It can be run from any R. Afterwards, work in R started by Pixi: run
#' `pixi run R` in a terminal, or use an IDE set up with `ide` (see
#' <https://roald-arboel.com/rpix/articles/ide.html>). Each Pixi environment
#' has its own R and package library, so rpix doesn't point a running R at a
#' Pixi library: packages built for a different R can crash it.
#'
#' It also adds a block to the project's `.Rprofile` that calls
#' [pixi_activate()], so the environment is activated when an IDE starts its
#' R directly. Projects set up with rpix 0.3.0 or earlier have a "Pixi R
#' library setup" block in their `.Rprofile` instead, which pointed a running
#' R at the Pixi library. It's removed.
#'
#' In a package, it adds `.pixi`, `pixi.toml` and `pixi.lock` to
#' `.Rbuildignore`, so they stay out of the package's builds.
#'
#' @param r_version Optional. The R version to add, such as `"4.5"`. Defaults
#'   to the newest one that the packages `use_pixi()` adds are built for on
#'   conda-forge.
#' @param ide Optional. IDEs to set the project up for: any of `"rstudio"`,
#'   `"positron"` and `"vscode"`. See [use_pixi_rstudio()],
#'   [use_pixi_positron()] and [use_pixi_vscode()].
#' @param init_if_missing If `TRUE`, create a Pixi project if there isn't one.
#' @param install_rpix If `TRUE`, install rpix into the project's environment.
#'   Its dependencies come from conda-forge, and rpix itself from R-universe
#'   until it's on conda-forge.
#' @param path The folder to set up. Defaults to the working directory.
#' @returns The path to the project's manifest, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi()
#' use_pixi(r_version = "4.5", ide = "positron")
#' }
use_pixi <- function(
  r_version = NULL,
  ide = NULL,
  init_if_missing = TRUE,
  install_rpix = TRUE,
  path = NULL
) {
  if (!is.null(ide)) {
    ide <- match.arg(ide, c("rstudio", "positron", "vscode"), several.ok = TRUE)
  }
  pixi_binary()
  dir <- normalizePath(path %||% getwd(), winslash = "/", mustWork = FALSE)

  manifest <- find_manifest(dir)
  if (is.null(manifest)) {
    if (!init_if_missing) {
      cli::cli_abort(c(
        "There's no Pixi project in {.path {dir}}.",
        "i" = "Create one with {.code use_pixi()} or {.code pixi init}."
      ))
    }
    run_pixi(c("init", dir), project = "none", echo = TRUE)
    manifest <- find_manifest(dir)
  }
  path <- dirname(manifest)
  build_ignore(path, pixi_files(path))

  r_base <- if (is.null(r_version)) "r-base" else paste0("r-base=", r_version)
  # conda-forge's R puts the user library of a regular R install first on
  # .libPaths() (https://github.com/conda-forge/r-base-feedstock/issues/37).
  # This package's activation script points R_LIBS_USER at nothing instead.
  isolation <- "conda-ecosystem-user-package-isolation"
  # Added together with R, so Pixi picks the newest R they're all built for.
  # A new R comes out on conda-forge before its packages are rebuilt for it.
  packages <- c(
    r_base,
    isolation,
    if (install_rpix) rpix_dependencies(),
    if ("vscode" %in% ide) "r-languageserver"
  )
  run_pixi(c("add", packages), path = path, echo = TRUE)

  if (install_rpix) {
    # From inside the environment's R, so rpix is installed for that R. Its
    # dependencies are already there, from conda-forge.
    install <- paste0(
      "utils::install.packages('rpix', repos = 'https://roaldarbol.r-universe.dev', ",
      "lib = .Library, dependencies = FALSE, type = 'source')"
    )
    run_pixi(c("run", "Rscript", "-e", install), path = path, echo = TRUE)
  }

  remove_legacy_rprofile(file.path(path, ".Rprofile"))
  warn_legacy_rprofile(file.path(home_dir(), ".Rprofile"))
  add_rprofile_block(file.path(path, ".Rprofile"))

  setup_ide <- list(
    rstudio = use_pixi_rstudio,
    positron = use_pixi_positron,
    vscode = use_pixi_vscode
  )
  for (i in ide) {
    setup_ide[[i]](path)
  }

  cli::cli_alert_success("Set up {.path {path}} for R.")
  if (is.null(ide)) {
    cli::cli_alert_info(
      "Start R from the project's environment, e.g. with {.code pixi run R}, or set up your IDE with {.code use_pixi(ide = ...)}."
    )
  }
  invisible(manifest)
}

# rpix's own dependencies, as conda packages. Reads rpix's DESCRIPTION through
# its namespace path, which also works under devtools::load_all().
rpix_dependencies <- function(imports = rpix_imports()) {
  imports <- trimws(strsplit(imports, ",", fixed = TRUE)[[1]])
  imports <- sub("[[:space:]]*\\(.*$", "", imports)
  parse_packages(imports)$name
}

rpix_imports <- function() {
  path <- getNamespaceInfo("rpix", "path")
  unname(read.dcf(file.path(path, "DESCRIPTION"), fields = "Imports")[1, 1])
}

# The block use_pixi() adds to the project's .Rprofile
rprofile_block <- c(
  "# >>> rpix >>>",
  "# Activates the project's Pixi environment when an IDE starts R directly.",
  "# See https://roald-arboel.com/rpix/articles/how-rpix-works.html",
  "local({",
  "  # In the environment's R, drop the personal library before any package",
  "  # loads: it has packages built for another R, which can crash this one",
  "  home <- normalizePath(R.home(), winslash = \"/\")",
  "  if (grepl(\"/[.]pixi/envs/[^/]+/lib/R$\", home)) {",
  "    personal <- strsplit(Sys.getenv(\"R_LIBS_USER\"), .Platform$path.sep)[[1]]",
  "    personal <- normalizePath(personal, winslash = \"/\", mustWork = FALSE)",
  "    personal <- personal[!grepl(\"/[.]pixi/\", personal)]",
  "    .libPaths(setdiff(.libPaths(), personal))",
  "  }",
  "  if (requireNamespace(\"rpix\", quietly = TRUE) &&",
  "      \"pixi_activate\" %in% getNamespaceExports(\"rpix\")) {",
  "    rpix::pixi_activate()",
  "  }",
  "})",
  "# <<< rpix <<<"
)

#' Add rpix's block to `.Rprofile`, or update it if it's there
#' @noRd
add_rprofile_block <- function(file) {
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  start <- match(rprofile_block[1], lines)
  end <- match(rprofile_block[length(rprofile_block)], lines)

  if (!is.na(start) && !is.na(end) && end > start) {
    lines <- c(
      lines[seq_len(start - 1)],
      rprofile_block,
      lines[-seq_len(end)]
    )
  } else {
    lines <- c(lines, if (length(lines) > 0) "", rprofile_block)
  }
  writeLines(lines, file)
  invisible(file)
}

legacy_marker <- "# Pixi R library setup"

#' Remove the `.Rprofile` block written by rpix 0.3.0 and earlier
#'
#' It pointed the running R at the Pixi library. Finds the `local({...})`
#' block after the marker comment by counting braces.
#' @returns `TRUE` if a block was removed, invisibly.
#' @noRd
remove_legacy_rprofile <- function(file) {
  if (!file.exists(file)) {
    return(invisible(FALSE))
  }
  lines <- readLines(file, warn = FALSE)
  start <- which(lines == legacy_marker)
  if (length(start) == 0) {
    return(invisible(FALSE))
  }
  start <- start[1]

  depth <- 0
  end <- NA
  for (i in seq(start + 1, length(lines))) {
    depth <- depth + count_char(lines[i], "{") - count_char(lines[i], "}")
    if (depth == 0 && grepl("}", lines[i], fixed = TRUE)) {
      end <- i
      break
    }
  }
  if (is.na(end)) {
    cli::cli_warn(
      "Found the old Pixi setup in {.path {file}}, but couldn't find where it ends. Remove it by hand."
    )
    return(invisible(FALSE))
  }

  writeLines(lines[-(start:end)], file)
  cli::cli_alert_success(
    "Removed the old Pixi library setup from {.path {file}}."
  )
  invisible(TRUE)
}

# rpix doesn't edit the global .Rprofile, but the old block there affects every
# project
warn_legacy_rprofile <- function(file) {
  if (file.exists(file) && legacy_marker %in% readLines(file, warn = FALSE)) {
    cli::cli_warn(c(
      "{.path {file}} still has the Pixi library setup from rpix 0.3.0 or earlier.",
      "i" = "It can crash R, so remove the {.code {legacy_marker}} block."
    ))
  }
}

count_char <- function(x, char) {
  lengths(regmatches(x, gregexpr(char, x, fixed = TRUE)))
}
