#' Add dependency / install package

#' Adds dependencies to the pixi.toml.
#' It will only add if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#'
#' @returns Doesn't return any objects.

add <- function(package_name){
  cmd <- paste0('pixi add r-', package_name)
  system(cmd)
}
