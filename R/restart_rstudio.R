#' Restart RStudio with Pixi
#' 
#' To ensure that RStudio uses the correct version of R and avoid errors when loading libraries, use this command to restart RStudio.
#'
#' @export
#'
restart_rstudio_with_pixi <- function() {
  os <- Sys.info()['sysname']
  
  # For MacOS
  if (os == "Darwin"){
    prefix_cmd <- "osascript -e 'tell app \"Terminal\" to do script \""
    wd <- getwd()
    cmd_cd <- paste("cd", wd)
    cmd_close_rstudio <- "pkill -x RStudio"
    cmd_open_rstudio <- "pixi run open -a rstudio"
    cmd_close_terminal <- "exit"
    cmds <- paste(
      cmd_cd, 
      cmd_close_rstudio, 
      cmd_open_rstudio,
      cmd_close_terminal,
      sep = "; ")
    cmd <- paste0(prefix_cmd, cmds, "\"'")
  }
  
  # Execute command
  system(cmd)
}