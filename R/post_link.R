# Some conda packages finish installing in a post-link script, e.g.
# bioconda's Bioconductor data packages, which download their data there.
# Pixi only runs these scripts when the project allows it, and otherwise
# installs the package without them, with a warning.

# After Pixi has installed packages: if it skipped their install scripts,
# offer to allow them in this project and to install those packages again, or
# say how to.
check_post_link <- function(result, path = NULL, environment = NULL) {
  skipped <- skipped_post_link(
    paste(c(result$stdout, result$stderr), collapse = "\n")
  )
  if (is.null(skipped)) {
    return(invisible(FALSE))
  }
  # Plural when Pixi didn't say which
  n <- if (length(skipped) > 0) length(skipped) else 2
  what <- if (length(skipped) > 0) {
    cli::format_inline("{.pkg {skipped}} {cli::qty(n)}{?isn't/aren't}")
  } else {
    "Some packages aren't"
  }
  reinstall <- c(
    "reinstall",
    skipped,
    if (!is.null(environment)) c("--environment", environment)
  )
  allow <- c("config", "set", "--local", "run-post-link-scripts", "insecure")
  context <- c(
    "i" = "Bioconductor's annotation and data packages, for example, download their data that way. The scripts run with your permissions, so Pixi only runs them in projects that allow it."
  )

  if (is_interactive()) {
    cli::cli_alert_warning(
      "{what} fully installed: Pixi didn't run {cli::qty(n)}{?its/their} install script{?s}."
    )
    cli::cli_bullets(context)
    question <- cli::format_inline(
      "Allow install scripts in this project, and install {cli::qty(n)}{?it/them} again?"
    )
    if (isTRUE(ask_yes_no(question))) {
      run_pixi(allow, path = path)
      cli::cli_alert_success(
        "Allowed install scripts in this project, in {.file .pixi/config.toml}."
      )
      run_pixi(reinstall, path = path, echo = TRUE)
      cli::cli_alert_info(
        "{.file .pixi/config.toml} isn't shared with the project, so others need to allow them too, e.g. when {.fn pixi_install} asks."
      )
      return(invisible(TRUE))
    }
  }
  cli::cli_warn(
    c(
      "{what} fully installed: Pixi didn't run {cli::qty(n)}{?its/their} install script{?s}.",
      context,
      "i" = "To run {cli::qty(n)}{?it/them}, allow install scripts in this project with {.code {format_command(allow)}}, then run {.code {format_command(reinstall)}}."
    ),
    class = "rpix_warning_post_link"
  )
  invisible(FALSE)
}

# The packages whose install scripts Pixi skipped, from its output: it lists
# them as e.g. "bin/.bioconductor-org.hs.eg.db-pre-unlink.sh". NULL if it
# skipped none, and an empty vector if it didn't say which.
skipped_post_link <- function(output) {
  output <- strip_ansi(output)
  if (!grepl("Skipped running the post-link scripts", output, fixed = TRUE)) {
    return(NULL)
  }
  scripts <- regmatches(
    output,
    gregexpr(
      "[/\\\\]\\.[A-Za-z0-9._+-]+-(post-link|pre-unlink|pre-link)\\.(sh|bat)",
      output
    )
  )[[1]]
  names <- sub("^[/\\\\]\\.", "", scripts)
  unique(sub("-(post-link|pre-unlink|pre-link)\\.(sh|bat)$", "", names))
}
