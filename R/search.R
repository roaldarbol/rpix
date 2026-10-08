#' Search for package versions and dependencies

#' @description
#' `search()` searches for available versions of a conda package and displays
#' their dependencies. This is useful for exploring what versions are available
#' before adding a package to your pixi project. The search shows version
#' information and dependency requirements for each version found.
#'
#' When called without arguments, it behaves like base R's `search()` function
#' and returns the current search path.
#'
#' @param package Package name to search for. It's translated like in [add()],
#'   so `"dplyr"` searches for `r-dplyr`, `"bioc::DESeq2"` for
#'   `bioconductor-deseq2` on bioconda, and `"conda::gdal"` for `gdal`. If
#'   missing, returns the search path like base R's search().
#' @param channel Optional. Defaults to conda-forge, but other conda channels
#'   can be specified to search in specific repositories.
#' @param dry_run Should the command be executed? If TRUE, the final pixi command
#'   will be shown but not executed. FALSE (default) executes the command.
#' @returns When `package` is provided: doesn't return objects, displays search
#'   results in console. When `package` is missing: returns character vector of
#'   search path (like base R's search()).
#' @import cli
#' @export search
#' @examples
#' \dontrun{
#' # Search for available versions of tibble
#' search("tibble")
#'
#' # Search in a specific channel
#' search("conda::numpy", channel = "conda-forge")
#'
#' # Just show the command without running it
#' search("dplyr", dry_run = TRUE)
#'
#' # Get search path (like base R)
#' search()
#' }

search <- function(package, channel = NULL, dry_run = FALSE) {
  # If no package is provided, delegate to base R's search()
  if (missing(package)) {
    return(base::search())
  }

  if (length(package) > 1) {
    cli::cli_abort(
      "{.fn search} can only take a single package name. You provided {length(package)} packages."
    )
  }

  parsed <- parse_packages(package)
  channel <- channel %||% stats::na.omit(parsed$channel)

  args <- c("search", parsed$name)
  if (length(channel) > 0) {
    args <- c(args, "--channel", channel)
  }

  # Use the project's channels when inside a project, conda-forge otherwise
  run_pixi(args, project = "optional", echo = TRUE, dry_run = dry_run)
}
