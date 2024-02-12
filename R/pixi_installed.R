#' Check pixi installation
#'
#'Tests whether pixi is installed on the system
#' @returns Doesn't return any objects.
pixi_installed <- function(silent=FALSE){
  # cmd <- "pixi --version"
  pixi_installed <- system('pixi --version', ignore.stdout = TRUE, ignore.stderr = TRUE) == 0
  # if (silent==TRUE){
  #   cmd <- paste0("if ! command -v pixi &> /dev/null; then echo 'pixi could not be found'; fi")
  # } else {
  #   cmd <- paste0("if ! command -v pixi &> /dev/null; then echo 'pixi could not be found'; else pixi --version; fi")
  # }
  # system(cmd)
  return(pixi_installed)
}
