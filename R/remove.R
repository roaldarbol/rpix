#' Remove dependencies

#' @description
#' `remove()` will add dependencies to the pixi.toml.
#' It will only remove if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#' 
#' @param package_names Package name(s) to be removed.
#' @returns Doesn't return any objects.
#' @export remove
#' @examples
#' \dontrun{
#' remove("tibble")
#' }

remove <- function(package_names){
  cmd <- paste0('pixi remove r-', package_names)
  system(cmd)
}