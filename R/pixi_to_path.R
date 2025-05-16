#' Add pixi to PATH
#'
#' @description
#' `pixi_to_path()` checks if pixi's installation directory is in the current PATH
#' and adds it if not found. The function automatically detects the operating system
#' and uses the appropriate default installation path for each platform.
#'
#' @details
#' The function checks if the pixi binary directory is already present in the PATH
#' environment variable. If not found, it appends the default installation directory:
#' \itemize{
#'   \item **macOS/Linux**: `~/.pixi/bin`
#'   \item **Windows**: `%USERPROFILE%\\.pixi\\bin`
#' }
#' 
#' This modification only affects the current R session.
#'
#' @return Invisibly returns `NULL`. The function is called for its side effects
#'   of modifying the PATH environment variable.
#'
#' @examples
#' \dontrun{
#' # Check if pixi is available and add to PATH if needed
#' pixi_to_path()
#' 
#' # Verify pixi is now available
#' system("pixi --version")
#' }
#'
#' @seealso [Sys.setenv()], [Sys.getenv()], [Sys.info()]
#' @export
pixi_to_path <- function(){
  # Check operating system
  os <- Sys.info()[["sysname"]]
  cli::cli_alert_info("Checking for pixi on {os}")
  
  # Set up paths based on OS
  if (os == "Windows") {
    pixi_path <- file.path(Sys.getenv("USERPROFILE"), ".pixi", "bin")
    separator <- ";"
  } else {  # macOS and Linux
    pixi_path <- "~/.pixi/bin"
    separator <- ":"
  }
  
  # Expand the tilde for comparison on Unix systems
  expanded_pixi_path <- if (os != "Windows") path.expand(pixi_path) else pixi_path
  
  # Get current PATH and split into components
  current_path <- Sys.getenv("PATH")
  path_components <- strsplit(current_path, separator, fixed = TRUE)[[1]]
  
  # Check if pixi path is already in PATH
  # Compare both unexpanded and expanded paths for Unix systems
  pixi_in_path <- if (os == "Windows") {
    pixi_path %in% path_components
  } else {
    pixi_path %in% path_components || expanded_pixi_path %in% path_components
  }
  
  if (pixi_in_path) {
    cli::cli_alert_success("pixi directory already in PATH")
  } else {
    cli::cli_alert_warning("pixi directory not found in PATH")
    cli::cli_alert_info("Adding {.path {pixi_path}} to PATH")
    
    # Add pixi path to the end of PATH
    new_path <- paste(current_path, pixi_path, sep = separator)
    Sys.setenv(PATH = new_path)
    
    cli::cli_alert_success("pixi path added successfully")
  }
  
  invisible(NULL)
}