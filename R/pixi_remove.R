#' Remove packages
#'
#' @description
#' Remove packages from the Pixi manifest. Package names are translated like in
#' [pixi_add()]: `"dplyr"` removes `r-dplyr` and `"bioc::DESeq2"` removes
#' `bioconductor-deseq2`. `"DESeq2"` removes `bioconductor-deseq2` too, when
#' that's what the manifest has, as [pixi_add()] adds it.
#'
#' For more information, see <https://pixi.prefix.dev/latest/reference/cli/pixi/remove/>.
#'
#' @param packages Package names.
#' @param type Optional. In a package, also remove the packages from this
#'   field of `DESCRIPTION`, such as `"Imports"` or `"SystemRequirements"`,
#'   and packages from GitHub from `Remotes`.
#' @inheritParams pixi_add
#' @param dry_run If `TRUE`, show the Pixi command without running it.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the Pixi call (invisibly).
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' pixi_remove("tibble", path = project, dry_run = TRUE)
pixi_remove <- function(
  packages,
  feature = NULL,
  platform = NULL,
  type = NULL,
  path = NULL,
  dry_run = FALSE
) {
  if (!is.null(type)) {
    entries <- description_entries(packages, NULL, type, path)
    result <- pixi_remove(
      packages,
      feature = feature,
      platform = platform,
      path = path,
      dry_run = dry_run
    )
    remove_from_description(entries, dry_run = dry_run)
    return(invisible(result))
  }
  github <- packages[is_github(packages)]
  names <- vapply(github, function(p) parse_github(p)$name, character(1))
  others <- packages[!is_github(packages)]
  parsed <- if (length(others) > 0) {
    parse_packages(others)
  } else {
    data.frame(name = character(), constraint = character())
  }
  if (any(nzchar(parsed$constraint))) {
    cli::cli_abort(
      "{.fn pixi_remove} takes package names without version constraints."
    )
  }
  parsed$name <- with_bioconductor_names(parsed, path)
  result <- run_pixi(
    c("remove", parsed$name, unname(names), scope_args(feature, platform)),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
  if (!isTRUE(dry_run)) {
    install_changed_environment(feature, path = path)
  }
  invisible(result)
}

# The conda names of the packages, with bioconductor-<name> in place of
# r-<name> when the manifest has the former but not the latter, as pixi_add()
# adds a Bioconductor package without `bioc::`
with_bioconductor_names <- function(parsed, path = NULL) {
  manifest <- find_manifest(path)
  if (is.null(manifest)) {
    return(parsed$name)
  }
  lines <- readLines(manifest, warn = FALSE)
  has <- function(names) {
    vapply(
      names,
      function(name) {
        key <- paste0(
          '^\\s*"?',
          gsub(".", "\\.", name, fixed = TRUE),
          '"?\\s*='
        )
        any(grepl(key, lines))
      },
      logical(1),
      USE.NAMES = FALSE
    )
  }
  bioc <- sub("^r-", "bioconductor-", parsed$name)
  swap <- parsed$source == "cran" & !has(parsed$name) & has(bioc)
  names <- parsed$name
  names[swap] <- bioc[swap]
  names
}
