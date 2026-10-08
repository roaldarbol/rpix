#' Set up a Pixi project for R
#'
#' @description
#' Create a Pixi project in the working directory if there isn't one, add R to
#' it, and install rpix into its environment.
#'
#' It also keeps your personal R library out of the environment's R, by
#' pointing `R_LIBS_USER` at `.pixi/r-libs/` in `pixi.toml`. Otherwise
#' conda-forge's R loads packages installed for your usual R first.
#'
#' It can be run from any R. Afterwards, work in R started by Pixi: run
#' `pixi run R` in a terminal, or point your IDE at the environment's R (see
#' <https://roald-arboel.com/rpix/articles/ide.html>). Each Pixi environment
#' has its own R and package library, so rpix doesn't point a running R at a
#' Pixi library: packages built for a different R can crash it.
#'
#' Projects set up with rpix 0.3.0 or earlier have a "Pixi R library setup"
#' block in their `.Rprofile`, which did exactly that. It's removed.
#'
#' @param r_version Optional. The R version to add, such as `"4.5"`. Defaults
#'   to the latest on conda-forge.
#' @param init_if_missing If `TRUE`, create a Pixi project if there isn't one.
#' @param install_rpix If `TRUE`, install rpix into the project's environment.
#'   Its dependencies come from conda-forge, and rpix itself from R-universe
#'   until it's on conda-forge.
#' @returns The path to the project's manifest, invisibly.
#' @export
#' @examples
#' \dontrun{
#' setup_pixi()
#' setup_pixi(r_version = "4.5")
#' }
setup_pixi <- function(
  r_version = NULL,
  init_if_missing = TRUE,
  install_rpix = TRUE
) {
  pixi_binary()
  dir <- getwd()

  manifest <- find_manifest(dir)
  if (is.null(manifest)) {
    if (!init_if_missing) {
      cli::cli_abort(c(
        "There's no Pixi project in {.path {dir}}.",
        "i" = "Create one with {.code setup_pixi()} or {.code pixi init}."
      ))
    }
    run_pixi(c("init", dir), project = "none", echo = TRUE)
    manifest <- find_manifest(dir)
  }
  path <- dirname(manifest)

  r_base <- if (is.null(r_version)) "r-base" else paste0("r-base=", r_version)
  packages <- c(r_base, if (install_rpix) rpix_dependencies())
  run_pixi(c("add", packages), path = path, echo = TRUE)

  # conda-forge's R puts the user library of a regular R install first on
  # .libPaths() (https://github.com/conda-forge/r-base-feedstock/issues/37).
  # Point it at a folder inside the project instead. Windows only expands
  # %VAR% here, and Pixi warns about a Windows target in a project without a
  # Windows platform, so that entry is only added when there is one.
  run_pixi(
    c(
      "workspace",
      "activation",
      "env",
      "set",
      paste0("R_LIBS_USER=", r_libs_user$unix)
    ),
    path = path,
    echo = TRUE
  )
  if (any(startsWith(project_platforms(path), "win"))) {
    run_pixi(
      c(
        "workspace",
        "activation",
        "env",
        "set",
        "--target",
        "win",
        paste0("R_LIBS_USER=", r_libs_user$windows)
      ),
      path = path,
      echo = TRUE
    )
  }

  if (install_rpix) {
    # From inside the environment's R, so rpix is installed for that R. Its
    # dependencies are already there, from conda-forge.
    install <- paste0(
      "install.packages('rpix', repos = 'https://roaldarbol.r-universe.dev', ",
      "lib = .Library, dependencies = FALSE, type = 'source')"
    )
    run_pixi(c("run", "Rscript", "-e", install), path = path, echo = TRUE)
  }

  remove_legacy_rprofile(file.path(path, ".Rprofile"))
  warn_legacy_rprofile(file.path(home_dir(), ".Rprofile"))

  cli::cli_alert_success("Set up {.path {path}} for R.")
  cli::cli_alert_info(
    "Start R from the project's environment, e.g. with {.code pixi run R}, or point your IDE at it: {.url https://roald-arboel.com/rpix/articles/ide.html}."
  )
  invisible(manifest)
}

r_libs_user <- list(
  unix = "$PIXI_PROJECT_ROOT/.pixi/r-libs/$PIXI_ENVIRONMENT_NAME",
  windows = "%PIXI_PROJECT_ROOT%\\.pixi\\r-libs\\%PIXI_ENVIRONMENT_NAME%"
)

# Platforms of the project's default environment
project_platforms <- function(path) {
  info <- run_pixi("info", path = path, json = TRUE)
  envs <- info$environments_info
  envs$platforms[[which(envs$name == "default")]]$name
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
