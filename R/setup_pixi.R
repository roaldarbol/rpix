#' Setup pixi environment safely
#'
#' @description
#' `setup_pixi()` provides a complete pixi setup for R projects. It checks for
#' pixi availability, initializes a pixi project if needed, and configures R
#' to use pixi-managed packages. The function prioritizes safety and uses
#' .libPaths() instead of environment variables to avoid shared library conflicts.
#'
#' @details
#' The function performs the following steps:
#' \enumerate{
#'   \item Checks if pixi is available in PATH (adds it if not found)
#'   \item Checks for pixi.toml in project root (runs `pixi init` if not found)
#'   \item Configures R to use the pixi library as the primary package source
#'   \item Optionally adds the configuration to .Rprofile for persistence
#' }
#' 
#' Instead of setting environment variables (which can cause shared library 
#' conflicts), this function modifies .libPaths() to prioritize the pixi library.
#'
#' @param add_to_rprofile Logical. If TRUE, adds the pixi library configuration
#'   to .Rprofile for persistence across sessions. Default is FALSE.
#' @param global Logical. If TRUE and `add_to_rprofile = TRUE`, adds to global
#'   ~/.Rprofile instead of project-local .Rprofile. Default is FALSE.
#' @param init_if_missing Logical. If TRUE, runs `pixi init` if pixi.toml is not
#'   found. Default is TRUE.
#'
#' @returns Invisibly returns a list with the status of each setup step.
#' 
#' @import cli
#' @importFrom utils install.packages
#'
#' @examples
#' \dontrun{
#' # Basic setup - just configure for current session
#' setup_pixi()
#' 
#' # Full setup - add to .Rprofile for persistence
#' setup_pixi(add_to_rprofile = TRUE)
#' 
#' # Setup without auto-initializing pixi project
#' setup_pixi(init_if_missing = FALSE)
#' }
#'
#' @seealso [pixi_to_path()], [.libPaths()]
#' @export
setup_pixi <- function(add_to_rprofile = TRUE, global = FALSE, init_if_missing = TRUE) {
  
  cli::cli_h1("Setting up pixi for R")
  
  # Status tracking
  status <- list(
    pixi_in_path = FALSE,
    pixi_project_exists = FALSE,
    pixi_env_exists = FALSE,
    library_configured = FALSE,
    rprofile_updated = FALSE
  )
  
  # Step 1: Ensure pixi is in PATH
  cli::cli_h1("Step 1: Checking pixi availability")
  pixi_to_path()
  
  # Verify pixi is now available
  pixi_check <- system("pixi --version", ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (pixi_check == 0) {
    status$pixi_in_path <- TRUE
    cli::cli_alert_success("pixi is available")
  } else {
    cli::cli_alert_danger("pixi is still not available after setup")
    cli::cli_alert_info("You may need to restart your terminal or manually add pixi to PATH")
    return(invisible(status))
  }
  
  # Step 2: Check for pixi.toml and initialize if needed
  cli::cli_h1("Step 2: Checking pixi project")
  
  if (file.exists("pixi.toml")) {
    status$pixi_project_exists <- TRUE
    cli::cli_alert_success("pixi.toml found")
  } else {
    cli::cli_alert_warning("pixi.toml not found")
    
    if (init_if_missing) {
      cli::cli_alert_info("Initializing pixi project...")
      init_result <- system("pixi init", ignore.stdout = FALSE, ignore.stderr = FALSE)
      cli::cli_alert_info("Adding base R packages")
      paste0(R.version$major, ".", R.version$minor)
      base_cmd <- paste0("pixi add \"r-base=", R.version$major, ".", R.version$minor, "\"")
      base_results <- system(base_cmd, ignore.stdout = FALSE, ignore.stderr = FALSE)
      
      if (init_result == 0 && file.exists("pixi.toml")) {
        status$pixi_project_exists <- TRUE
        cli::cli_alert_success("pixi project initialized")
      } else {
        cli::cli_alert_danger("Failed to initialize pixi project")
        return(invisible(status))
      }
    } else {
      cli::cli_alert_info("Skipping pixi init (init_if_missing = FALSE)")
      cli::cli_alert_info("Run 'pixi init' manually to create a pixi project")
      return(invisible(status))
    }
  }
  
  # Step 3: Check if pixi environment exists
  cli::cli_h1("Step 3: Checking pixi environment")
  
  project_root <- getwd()
  pixi_r_libs <- file.path(project_root, ".pixi", "envs", "default", "lib", "R", "library")
  
  if (dir.exists(pixi_r_libs)) {
    status$pixi_env_exists <- TRUE
    cli::cli_alert_success("Pixi environment found at: {.path {pixi_r_libs}}")
  } else {
    cli::cli_alert_warning("Pixi environment not found")
    
    # We can still set up the library paths for when the environment is created
    cli::cli_alert_info("Creating library at: {.path {pixi_r_libs}}")
    dir.create(pixi_r_libs, recursive = TRUE)
  }
  
  # Step 4: Configure R library paths
  cli::cli_h1("Step 4: Configuring R library paths")
  
  # Get current library paths
  current_libpaths <- .libPaths()
  
  # Remove pixi path if already present to avoid duplicates
  current_libpaths <- current_libpaths[current_libpaths != pixi_r_libs]
  
  # Add pixi library as first entry
  new_libpaths <- c(pixi_r_libs, current_libpaths)
  # new_libpaths <- c(pixi_r_libs)
  .libPaths(new_libpaths)
  # if (length(.libPaths()) > 1){
  #   .libPaths(.libPaths()[1])
  # }
  
  status$library_configured <- TRUE
  cli::cli_alert_success("Configured .libPaths() to prioritize pixi library")
  cli::cli_alert_info("Current .libPaths():")
  current_paths <- .libPaths()
  for (i in seq_along(current_paths)) {
    cli::cli_alert_info("  {i}. {.path {current_paths[i]}}")
  }
  
  # Install {rpix} into the pixi library
  cli::cli_alert_info("Installing {rpix} to project")
  utils::install.packages("rpix", 
                   repos = "https://roaldarbol.r-universe.dev", 
                   lib = pixi_r_libs)
  
  # Step 5: Add to .Rprofile if requested
  if (add_to_rprofile) {
    cli::cli_h1("Step 5: Updating .Rprofile")
    
    file <- if (global) "~/.Rprofile" else ".Rprofile"
    
    # Check if pixi setup already exists
    if (file.exists(file)) {
      existing_content <- readLines(file, warn = FALSE)
      already_there <- any(grepl("# Pixi R library setup", existing_content, fixed = TRUE))
      
      if (already_there) {
        cli::cli_alert_info("Pixi setup already exists in {.path {file}}")
        status$rprofile_updated <- TRUE
      } else {
        add_to_rprofile_file(file, project_root)
        status$rprofile_updated <- TRUE
      }
    } else {
      add_to_rprofile_file(file, project_root)
      status$rprofile_updated <- TRUE
    }
  }
  
  # Final summary
  cli::cli_h1("Setup Summary")
  cli::cli_alert_success("Pixi setup completed successfully!")
  cli::cli_alert_info("Next steps:")
  cli::cli_bullets(c("*" = "1. Add R packages: {.code pixi add r-dplyr r-ggplot2}",
                     "*" = "2. Restart R to ensure all changes take effect"))
  
  invisible(status)
}

#' Helper function to add pixi setup to .Rprofile
#' @param file Path to .Rprofile file
#' @param project_root Project root directory
#' @noRd
add_to_rprofile_file <- function(file, project_root) {
  # Create safer .Rprofile code that checks for existence and handles errors
  to_add <- paste0('
# Pixi R library setup
local({
  # First ensure pixi is in PATH
  tryCatch({
    # Check if pixi directory is already in PATH
    os <- Sys.info()[["sysname"]]
    
    if (os == "Windows") {
      pixi_path <- file.path(Sys.getenv("USERPROFILE"), ".pixi", "bin")
      separator <- ";"
    } else {  # macOS and Linux
      pixi_path <- "~/.pixi/bin"
      separator <- ":"
    }
    
    # Expand the tilde for comparison on Unix systems
    expanded_pixi_path <- if (os != "Windows") path.expand(pixi_path) else pixi_path
    
    # Get current PATH and check if pixi path is present
    current_path <- Sys.getenv("PATH")
    path_components <- strsplit(current_path, separator, fixed = TRUE)[[1]]
    
    pixi_in_path <- if (os == "Windows") {
      pixi_path %in% path_components
    } else {
      pixi_path %in% path_components || expanded_pixi_path %in% path_components
    }
    
    # Add pixi to PATH if not found
    if (!pixi_in_path) {
      new_path <- paste(current_path, pixi_path, sep = separator)
      Sys.setenv(PATH = new_path)
    }
  }, error = function(e) invisible(NULL))
  
  # Only run library setup in projects with pixi.toml
  if (file.exists("pixi.toml")) {
    tryCatch({
      project_root <- "', project_root, '"
      pixi_r_libs <- file.path(project_root, ".pixi", "envs", "default", "lib", "R", "library")
      
      # Only use pixi library if it exists
      if (dir.exists(pixi_r_libs)) {
        # Get current library paths
        current_libpaths <- .libPaths()
        
        # Remove pixi path if already present to avoid duplicates
        current_libpaths <- current_libpaths[current_libpaths != pixi_r_libs]
        
        # Add pixi library as first entry
        new_libpaths <- c(pixi_r_libs, current_libpaths)
        # new_libpaths <- c(pixi_r_libs)
        .libPaths(new_libpaths)
        message("Using pixi R library: ", pixi_r_libs)
      }
    }, error = function(e) {
      # Silently handle errors to avoid breaking R startup
      invisible(NULL)
    })
  }
})
')
  
  cat(to_add, file = file, append = TRUE)
  cli::cli_alert_success("Added pixi setup to {.path {file}}")
}

#' Reset R library configuration
#'
#' @description
#' `reset_r_libraries()` resets R's library configuration to default settings,
#' removing any pixi-specific configurations. This is useful for troubleshooting
#' or when you want to stop using pixi-managed packages.
#'
#' @param remove_from_rprofile Logical. If TRUE, attempts to remove pixi setup
#'   from .Rprofile files. Default is FALSE.
#' @param global Logical. If TRUE and `remove_from_rprofile = TRUE`, removes from
#'   global ~/.Rprofile. Default is FALSE.
#'
#' @examples
#' \dontrun{
#' # Reset library paths to default
#' reset_r_libraries()
#' 
#' # Reset and clean .Rprofile
#' reset_r_libraries(remove_from_rprofile = TRUE)
#' }
#'
#' @export
reset_r_libraries <- function(remove_from_rprofile = FALSE, global = FALSE) {
  cli::cli_alert_info("Resetting R library configuration")
  
  # Reset .libPaths() to default
  # The default is typically c(user_library, system_library)
  default_libs <- c(
    .Library.site,  # Site library
    .Library        # System library
  )
  
  # Add user library if it exists and isn't already included
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (user_lib != "" && dir.exists(user_lib) && !user_lib %in% default_libs) {
    default_libs <- c(user_lib, default_libs)
  }
  
  .libPaths(default_libs)
  
  cli::cli_alert_success("Reset .libPaths() to default")
  cli::cli_alert_info("Current .libPaths():")
  current_paths <- .libPaths()
  for (i in seq_along(current_paths)) {
    cli::cli_alert_info("  {i}. {.path {current_paths[i]}}")
  }
  
  # Remove from .Rprofile if requested
  if (remove_from_rprofile) {
    remove_from_rprofile_file(global)
  }
  
  cli::cli_alert_info("Library configuration reset complete")
  cli::cli_alert_warning("Restart R for changes to fully take effect")
  
  invisible(NULL)
}

#' Helper function to remove pixi setup from .Rprofile
#' @param global Whether to remove from global .Rprofile
#' @noRd
remove_from_rprofile_file <- function(global = FALSE) {
  file <- if (global) "~/.Rprofile" else ".Rprofile"
  
  if (!file.exists(file)) {
    cli::cli_alert_info("No .Rprofile file found at {.path {file}}")
    return(invisible(NULL))
  }
  
  content <- readLines(file, warn = FALSE)
  
  # Find start and end of pixi block
  start_idx <- which(grepl("# Pixi R library setup", content, fixed = TRUE))
  
  if (length(start_idx) == 0) {
    cli::cli_alert_info("No pixi setup found in {.path {file}}")
    return(invisible(NULL))
  }
  
  # Find the end of the local block
  end_idx <- start_idx
  brace_count <- 0
  in_local <- FALSE
  
  for (i in start_idx:length(content)) {
    line <- content[i]
    
    if (grepl("local\\s*\\(\\s*\\{", line)) {
      in_local <- TRUE
      brace_count <- 1
    } else if (in_local) {
      # Count braces
      brace_count <- brace_count + lengths(regmatches(line, gregexpr("\\{", line)))
      brace_count <- brace_count - lengths(regmatches(line, gregexpr("\\}", line)))
      
      if (brace_count == 0) {
        end_idx <- i
        break
      }
    }
  }
  
  # Remove the pixi block
  if (end_idx >= start_idx) {
    new_content <- content[-(start_idx:end_idx)]
    writeLines(new_content, file)
    cli::cli_alert_success("Removed pixi setup from {.path {file}}")
  } else {
    cli::cli_alert_warning("Could not find end of pixi block in {.path {file}}")
  }
  
  invisible(NULL)
}