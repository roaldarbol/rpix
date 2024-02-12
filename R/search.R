#' Search for dependency
#' 
#' Search a package, output will list the latest version of the package.
#'
#' @param package_name Package name to be added.
#' @export
search <- function(package_name=NULL){
  if (!missing(package_name)){
    cmd <- paste0('pixi search r-', package_name)
    system(cmd)
  }
}
