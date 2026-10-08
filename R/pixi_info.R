#' Information about a Pixi project
#'
#' @description
#' * `pixi_info()` returns what `pixi info` reports: the Pixi version and
#'   platform, the project, and its environments with their features,
#'   platforms, channels, tasks and location.
#' * `pixi_list()` lists the packages installed in an environment.
#' * `pixi_tree()` shows which packages depend on which.
#'
#' For more information, see <https://pixi.sh/latest/reference/cli/pixi/info/>,
#' <https://pixi.sh/latest/reference/cli/pixi/list/> and
#' <https://pixi.sh/latest/reference/cli/pixi/tree/>.
#'
#' @param environment Optional. The environment. Defaults to `default`.
#' @param explicit If `TRUE`, only list the packages in `pixi.toml`, not the
#'   ones they depend on.
#' @param packages Optional. Only show these packages, and what they depend
#'   on. Names are translated like in [pixi_add()].
#' @param invert If `TRUE`, show what depends on `packages` instead.
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
#' @returns
#' * `pixi_info()`: a list, as `pixi info --json` gives it.
#' * `pixi_list()`: a data frame with a row per package, and the columns
#'   `name`, `version`, `r_package` (the name of the R package, or `NA`),
#'   `explicit` (whether it's in `pixi.toml`), `channel` (its name, such as
#'   `conda-forge`), `kind` (`"conda"` or `"pypi"`) and `build`.
#' * `pixi_tree()`: the tree's lines, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_info()$environments_info$name
#' pixi_list(explicit = TRUE)
#' pixi_tree("dplyr")
#' }
pixi_info <- function(path = NULL) {
  info <- run_pixi("info", project = "optional", path = path, json = TRUE)
  class(info) <- "rpix_info"
  info
}

#' @rdname pixi_info
#' @export
pixi_list <- function(environment = NULL, explicit = FALSE, path = NULL) {
  args <- c(
    "list",
    if (!is.null(environment)) c("--environment", environment),
    if (explicit) "--explicit"
  )
  packages <- run_pixi(args, path = path, json = TRUE)

  columns <- c("name", "version", "build", "source", "kind", "is_explicit")
  if (length(packages) == 0) {
    packages <- as.data.frame(
      stats::setNames(rep(list(character()), length(columns)), columns)
    )
    packages$is_explicit <- logical()
  }
  packages <- packages[columns]
  names(packages) <- c(
    "name",
    "version",
    "build",
    "channel",
    "kind",
    "explicit"
  )

  packages$r_package <- r_package_names(
    packages$name,
    r_library(environment %||% "default", path)
  )
  # The channel's name, e.g. conda-forge, rather than its URL
  packages$channel <- basename(sub("/+$", "", packages$channel))
  packages <- packages[c(
    "name",
    "version",
    "r_package",
    "explicit",
    "channel",
    "kind",
    "build"
  )]
  rownames(packages) <- NULL
  new_rpix_df(
    packages,
    "rpix_packages",
    environment = environment %||% "default"
  )
}

#' @rdname pixi_info
#' @export
pixi_tree <- function(
  packages = NULL,
  environment = NULL,
  invert = FALSE,
  path = NULL
) {
  if (length(packages) > 0) {
    names <- parse_packages(packages)$name
    regex <- paste0(
      "^(",
      paste(gsub(".", "\\.", names, fixed = TRUE), collapse = "|"),
      ")$"
    )
  }
  args <- c(
    "tree",
    if (!is.null(environment)) c("--environment", environment),
    if (invert) "--invert",
    if (length(packages) > 0) regex
  )
  result <- run_pixi(args, path = path)
  lines <- strsplit(result$stdout, "\n", fixed = TRUE)[[1]]
  cat(lines, sep = "\n")
  invisible(lines)
}

#' R package names for conda package names
#'
#' Conda names are lowercase, so the R name is looked up in the environment's
#' library, where it's spelled as R spells it.
#' @param conda Conda package names.
#' @param library The environment's R library, or `NULL`.
#' @returns The R package names, or `NA` for packages that aren't R packages.
#' @noRd
r_package_names <- function(conda, library) {
  prefixes <- "^(r|bioconductor)-"
  is_r <- grepl(prefixes, conda) & !conda %in% c("r-base", "r-recommended")
  names <- ifelse(is_r, sub(prefixes, "", conda), NA_character_)

  installed <- if (!is.null(library)) list.files(library) else character()
  match <- match(tolower(names), tolower(installed))
  names[!is.na(match)] <- installed[match[!is.na(match)]]
  names
}

# The R library of an environment, or NULL if Pixi doesn't know it
r_library <- function(environment, path) {
  info <- tryCatch(pixi_info(path), error = function(e) NULL)
  envs <- info$environments_info
  prefix <- envs$prefix[envs$name == environment]
  if (length(prefix) == 0) {
    return(NULL)
  }
  file.path(prefix, "lib", "R", "library")
}
