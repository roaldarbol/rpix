#' Remove dependencies

#' @description
#' `remove()` will remove dependencies from the pixi.toml.
#' 
#' For more information, see https://pixi.sh/latest/reference/cli/pixi/remove/
#' 
#' @param packages Package name(s) to be removed.
#' @param dry_run Just show command or also run.
#' @returns Doesn't return any objects.
#' @export remove
#' @examples
#' \dontrun{
#' remove("tibble")
#' }

remove <- function(packages, dry_run = FALSE){
  # Prepend r-
  prepended_names <- paste0("r-", packages)
  
  # Collapse into single line
  cmd <- paste0(prepended_names, collapse = " ")
  
  # Prepend pixi remove
  cmd <- paste('pixi remove', cmd)
  
  # Dry-run or run
  cli::cli_alert_info("The resulting pixi command is:")
  cli::cli_code(cmd)
  
  if (isFALSE(dry_run)){
    system(cmd)
  }
}