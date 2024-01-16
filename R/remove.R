

remove <- function(package_name){
  cmd <- paste0('pixi remove r-', package_name)
  system(cmd)
}
