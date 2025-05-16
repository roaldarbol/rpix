#' #' Create a new `pixi` project
#' #'
#' #' `init()` initializes a pixi.toml file and also prepares a .gitignore to prevent the
#' #' environment from being added to git.
#' #' 
#' #' @importFrom blogdown read_toml write_toml
#' #' @importFrom renv dependencies
#' #' 
#' #' @returns Doesn't return any objects.
#' 
#' init <- function(){
#'   if (pixi_installed() == TRUE){stop('pixi could not be found')}
#'   cmd <- paste0('pixi init')
#'   system(cmd)
#' }
#' 
#' init_r <- function(){
#'   config.toml <- list.files(pattern = "pixi.toml")
#' 
#'   # Read pixi.toml
#'   pixi.toml <- blogdown::read_toml(config.toml)
#' 
#'   pixi.toml$tasks <- list(rstudio = "open -a rstudio",
#'                           rproject = "open *.Rproj")
#' 
#'   pixi.toml$activation <- list(scripts = list("setup.sh"))
#'   blogdown::write_toml(pixi.toml, output = "test.toml")
#' 
#'   deps <- renv::dependencies()
#' }
