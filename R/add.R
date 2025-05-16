#' Add dependencies

#' @description
#' `add()` will add dependencies to the pixi.toml.
#' 
#' For more information, see https://pixi.sh/latest/reference/cli/pixi/add/.
#' 
#' It will only add if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#' 
#' @param packages Package name(s) to be added.
#' @param versions Optional. Version constraints for all packages.
#' @param channel Optional. Defaults to conda-forge, but other conda channels can be specified.
#' @param dry_run Should the command be executed? If TRUE, the final pixi command will be shown but not executed. FALSE (default) executes the command.
#' @returns Doesn't return any objects.
#' @export add
#' @examples
#' \dontrun{
#' add("tibble")
#' }

add <- function(packages, versions=NULL, channel=NULL, dry_run = FALSE){
  
  # Prepend r-
  prepended_names <- paste0("r-", packages)
  
  # Append version constraints
  if (!is.null(versions)){
    # Clean up versions - add = if missing and version doesn't start with =, <, >, ~, etc.
    cleaned_versions <- stringr::str_replace(versions, "^(?![=<>~^])", "=")
    
    prepended_names <- paste0("r-", packages, cleaned_versions)
    prepended_names <- paste0("\"", prepended_names, "\"")
  }
  
  # Collapse into single line
  cmd <- paste0(prepended_names, collapse = " ")
  
  # Append channel if present
  if (!is.null(channel)){
    cmd <- paste(cmd, "--channel", channel)
  }
  
  # Prepend pixi add
  cmd <- paste('pixi add', cmd)
  
  # Dry-run or run
  cli::cli_alert_info("The resulting pixi command is:")
  cli::cli_code(cmd)
  
  if (isFALSE(dry_run)){
    system(cmd)
  }
}