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
#' @param package Package name to search for. Will be automatically prefixed 
#'   with "r-" for R packages. If missing, returns the search path like base R's search().
#' @param channel Optional. Defaults to conda-forge, but other conda channels 
#'   can be specified to search in specific repositories.
#' @param dry_run Should the command be executed? If TRUE, the final pixi command 
#'   will be shown but not executed. FALSE (default) executes the command.
#' @returns When `package` is provided: doesn't return objects, displays search 
#'   results in console. When `package` is missing: returns character vector of 
#'   search path (like base R's search()).
#' @export search
#' @examples
#' \dontrun{
#' # Search for available versions of tibble
#' search("tibble")
#' 
#' # Search in a specific channel
#' search("numpy", channel = "conda-forge")
#' 
#' # Just show the command without running it
#' search("dplyr", dry_run = TRUE)
#' 
#' # Get search path (like base R)
#' search()
#' }

search <- function(package, channel = NULL, dry_run = FALSE){
  
  # If no package is provided, delegate to base R's search()
  if (missing(package)) {
    return(base::search())
  }
  
  # Ensure only one package is provided
  if (length(package) > 1) {
    cli::cli_abort("search() can only take a single package name. You provided {length(package)} packages.")
  }
  
  # Prepend r- to the package name
  prepended_name <- paste0("r-", package)
  
  # Start building the command
  cmd <- paste("pixi search", prepended_name)
  
  # Append channel if present
  if (!is.null(channel)){
    cmd <- paste(cmd, "--channel", channel)
  }
  
  # Show the command
  cli::cli_alert_info("The resulting pixi command is:")
  cli::cli_code(cmd)
  
  # Execute or dry-run
  if (isFALSE(dry_run)){
    system(cmd)
  }
}