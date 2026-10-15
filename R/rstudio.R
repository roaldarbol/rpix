# RStudio's addins (inst/rstudio/addins.dcf) and its New Project template
# (inst/rstudio/templates/project/rpix.dcf). RStudio calls these by name, so
# they aren't exported. The project is the working directory, as in an
# RStudio project.

# Add packages: those in the selection, or those asked for
addin_add_packages <- function() {
  text <- rstudio_selection()
  if (!nzchar(trimws(text))) {
    text <- ask_dialog(
      "Add packages",
      "Packages to add to the project, e.g. dplyr, tidyr:"
    )
  }
  packages <- text_packages(text %||% "")
  if (length(packages) == 0) {
    cli::cli_alert_info("No packages to add.")
    return(invisible())
  }
  pixi_add(packages)
}

# Add what the active file uses and pixi.toml lacks
addin_add_file_packages <- function() {
  file <- rstudio_active_file()
  if (is.null(file)) {
    cli::cli_alert_info("Save the file first, so rpix can read it.")
    return(invisible())
  }
  root <- require_project(dirname(file))
  missing <- missing_packages(root, scan_file(file))
  if (length(missing) == 0) {
    cli::cli_alert_success(
      "{.file pixi.toml} has all the packages {.file {basename(file)}} uses."
    )
    return(invisible())
  }
  add_missing_packages(root, missing)
}

# Start RStudio with an environment's R: the only one, or one picked
addin_open_with_pixi_r <- function() {
  root <- require_project(NULL)
  environments <- pixi_environments(root)$name
  # Already there, with nothing else to switch to
  running <- pixi_r_location(r_home())
  if (
    length(environments) == 1 &&
      !is.null(running) &&
      same_path(running$root, root)
  ) {
    cli::cli_alert_success(
      "This RStudio already runs the project's Pixi R ({.val {running$name}})."
    )
    return(invisible())
  }
  environment <- if (length(environments) == 1) environments
  pixi_switch(environment, ide = "rstudio")
}

addin_sitrep <- function() {
  pixi_sitrep()
}

addin_install <- function() {
  pixi_install()
}

addin_open_manifest <- function() {
  utils::file.edit(find_manifest(require_project(NULL)))
}

# Run a task, picked from the project's
addin_run_task <- function() {
  tasks <- pixi_tasks()
  if (nrow(tasks) == 0) {
    cli::cli_alert_info(
      "The project has no tasks. Add one with {.code pixi_add_task()}."
    )
    return(invisible())
  }
  names <- unique(tasks$name)
  choice <- ask_choice("Which task do you want to run?", names)
  if (is.na(choice)) {
    return(invisible())
  }
  pixi_run(names[choice])
}

# RStudio's New Project template: a project set up with use_pixi() for
# RStudio, with the R version picked in the dialog, and a git repository if
# asked for (RStudio hides its own checkbox for templates). RStudio then
# opens it in the R it's set up with; the .Rprofile block says how to move to
# the environment's R.
rstudio_new_project <- function(path, r_version = "4.5", git = FALSE, ...) {
  # RStudio runs renv::init() after the template if its New Project dialog's
  # "Use renv with this project" was last ticked, without showing it
  if (isTRUE(rstudio_preference("new_proj_use_renv"))) {
    cli::cli_alert_warning(
      "RStudio will also set up renv in this project ({.strong Use renv with this project} in its New Project dialog), which clashes with Pixi. For next time, turn it off with {.code rstudioapi::writeRStudioPreference(\"new_proj_use_renv\", FALSE)}, or create one project with it unticked: RStudio only saves it when a project is created. rpix says how to remove renv when the project opens."
    )
  }
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  use_pixi(r_version = r_version, ide = "rstudio", path = path)
  if (isTRUE(as.logical(git))) {
    git_init(path)
  }
  invisible(path)
}

# Make the folder a git repository. Pixi's .gitignore and .gitattributes are
# there already.
git_init <- function(path) {
  git <- git_binary()
  if (!nzchar(git)) {
    cli::cli_alert_warning(
      "Git isn't installed, so the project isn't a git repository."
    )
    return(invisible(FALSE))
  }
  processx::run(git, c("init", "--quiet"), wd = path)
  cli::cli_alert_success("Made {.path {path}} a git repository.")
  invisible(TRUE)
}

git_binary <- function() {
  Sys.which("git")
}

# The packages in some text: R code that uses them, or names separated by
# commas or spaces
text_packages <- function(text) {
  if (grepl("[(:]", text)) {
    return(code_packages(strsplit(text, "\n", fixed = TRUE)[[1]]))
  }
  names <- strsplit(trimws(text), "[,[:space:]]+")[[1]]
  names <- gsub("^[\"'`]+|[\"'`]+$", "", names)
  unique(names[nzchar(names)])
}

# One of RStudio's API functions, which RStudio defines in its own
# environment; rstudioapi wraps them. NULL outside RStudio.
rstudio_api <- function(name) {
  if (!"tools:rstudio" %in% search()) {
    return(NULL)
  }
  get0(
    paste0(".rs.api.", name),
    envir = as.environment("tools:rstudio"),
    mode = "function",
    inherits = FALSE
  )
}

# One of RStudio's preferences, or NULL outside RStudio
rstudio_preference <- function(name) {
  read <- rstudio_api("readRStudioPreference")
  if (is.null(read)) NULL else read(name, NULL)
}

# The text selected in RStudio's editor, or ""
rstudio_selection <- function() {
  context <- rstudio_api("getSourceEditorContext")
  if (is.null(context)) {
    return("")
  }
  context()$selection[[1]]$text %||% ""
}

# The path of the file open in RStudio's editor, or NULL if it isn't saved
rstudio_active_file <- function() {
  context <- rstudio_api("getSourceEditorContext")
  path <- if (!is.null(context)) context()$path
  if (is.null(path) || !nzchar(path)) NULL else path
}

# Ask for some text, in RStudio's dialog or the console. NULL if cancelled.
ask_dialog <- function(title, message) {
  prompt <- rstudio_api("showPrompt")
  if (!is.null(prompt)) {
    return(prompt(title, message, ""))
  }
  if (!is_interactive()) {
    return(NULL)
  }
  ask_text(paste0(message, " "))
}
