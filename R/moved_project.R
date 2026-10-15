# A moved or copied project (#217). Pixi's activation cache records the
# project's paths, but isn't keyed on its location, so Pixi then activates the
# old location. And conda environments can't be moved: an environment's
# bin/R hard-codes where R was installed.

# Remove the project's cached activations of another location: it's only a
# cache. TRUE if there were any.
remove_stale_activation_cache <- function(root, quiet = FALSE) {
  files <- list.files(
    file.path(root, ".pixi", "activation-env-v0"),
    pattern = "[.]json$",
    full.names = TRUE
  )
  stale <- files[vapply(files, stale_activation, logical(1), root = root)]
  if (length(stale) == 0) {
    return(FALSE)
  }
  unlink(stale)
  if (!quiet) {
    cli::cli_inform(stale_cache_bullet)
  }
  TRUE
}

stale_cache_bullet <- c(
  "!" = "The project was moved or copied, so rpix removed Pixi's activation cache, which had its old location."
)

# Whether a cached activation is of another location
stale_activation <- function(file, root) {
  vars <- tryCatch(
    jsonlite::read_json(file)$environment_variables,
    error = function(e) NULL
  )
  recorded <- vars$PIXI_WORKSPACE_ROOT %||% vars$PIXI_PROJECT_ROOT
  is.character(recorded) && !same_path(recorded, root)
}

# The project's environments that were installed elsewhere, named, with the
# project they were installed in
moved_environments <- function(root) {
  envs <- list.dirs(file.path(root, ".pixi", "envs"), recursive = FALSE)
  installed_in <- vapply(envs, installed_project, character(1))
  moved <- vapply(
    installed_in,
    function(project) !is.na(project) && !same_path(project, root),
    logical(1)
  )
  stats::setNames(installed_in[moved], basename(envs[moved]))
}

# The project an environment's R was installed in, from its bin/R, or NA.
# Windows' R finds its own location instead.
installed_project <- function(env) {
  script <- file.path(env, "bin", "R")
  if (!file.exists(script)) {
    return(NA_character_)
  }
  lines <- readLines(script, warn = FALSE)
  pattern <- "^R_HOME_DIR=[\"']?([^\"']+)[\"']?$"
  home <- sub(pattern, "\\1", grep(pattern, lines, value = TRUE)[1])
  location <- if (!is.na(home)) pixi_r_location(home)
  location$root %||% NA_character_
}

moved_environments_bullets <- function(moved) {
  n <- length(moved)
  envs <- names(moved)
  old <- unique(unname(moved))
  cli_escape(c(
    "!" = cli::format_inline(
      "{cli::qty(n)}The {.val {envs}} environment{?s} {?was/were} installed in {.path {old}}, and Pixi's environments can't be moved, so {cli::qty(n)}{?its/their} R still points there."
    ),
    "i" = cli::format_inline(
      "Reinstall {cli::qty(n)}{?it/them} with {.code pixi clean} and {.code pixi install --all} in a terminal, in the project."
    )
  ))
}

# Fix and explain what moving or copying the project broke, as cli bullets:
# removes the stale activation cache, and names the moved environments
moved_project <- function(root) {
  cache <- remove_stale_activation_cache(root, quiet = TRUE)
  moved <- moved_environments(root)
  c(
    if (cache) stale_cache_bullet,
    if (length(moved) > 0) moved_environments_bullets(moved)
  )
}
