#' Add/remove dependencies

#' @description
#' `add()` will add dependencies to the pixi.toml.
#' It will only add if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#' 
#' @param package_names Package name(s) to be added/removed.
#' @returns Doesn't return any objects.
#' \dontrun{
#' add("tibble")
#' }
#' @export add
#' @export remove

add <- function(package_names){
  cmd <- paste0('pixi add r-', package_names)
  system(cmd)
}

remove <- function(package_names){
  cmd <- paste0('pixi remove r-', package_names)
  system(cmd)
}
