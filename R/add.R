#' Add dependencies

#' @description
#' `add()` will add dependencies to the pixi.toml.
#' It will only add if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#' 
#' @param package_names Package name(s) to be added.
#' @returns Doesn't return any objects.
#' @export add
#' @examples
#' \dontrun{
#' add("tibble")
#' }

add <- function(package_names){
  cmd <- paste0('pixi add r-', package_names)
  system(cmd)
}
