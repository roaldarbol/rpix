#' Create a new `pixi` project
#'
#' `init()` initializes a pixi.toml file and also prepares a .gitignore to prevent the
#' environment from being added to git.
#' @returns Doesn't return any objects.

init <- function(){
  if (pixi_installed() == TRUE){stop('pixi could not be found')}
  cmd <- paste0('pixi init')
  system(cmd)
}
