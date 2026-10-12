#' Use packages as they were on a date
#'
#' @description
#' Make Pixi leave out every package published after a date, with the
#' project's `exclude-newer` setting. The project then gets packages as they
#' were on that day, like a snapshot of a package repository: useful to rerun
#' an old analysis with the versions it was written for, or to check that a
#' package still works with what users had a year ago. `pixi_set_date()` sets
#' it, and updates `pixi.lock` to match.
#'
#' A duration, such as `"7d"`, leaves out packages published in the last week
#' instead, e.g. to stay clear of a release that turns out to be broken or
#' compromised. `pixi_set_date(NULL)` removes the setting; packages stay as
#' they are until you update them with [pixi_update()].
#'
#' Only packages that were on conda-forge (or the project's other channels) at
#' the time are available, even if they were on CRAN then.
#'
#' @details
#' `pixi_add()` pins the versions it adds, so an existing project's pins may
#' be newer than an earlier date. Pixi then can't solve the project, and
#' `pixi.toml` is left as it was. Setting the date when you create the
#' project, with `use_pixi(date = )`, avoids that.
#'
#' The date applies to Pixi's build backend too, so packages built from source
#' (`pixi_add("github::...")`) need a date after the backend's release, or a
#' duration.
#'
#' See <https://pixi.prefix.dev/latest/reference/pixi_manifest/#exclude-newer-optional>.
#'
#' @param date A date, such as `"2025-06-01"` or `Sys.Date() - 365`, a
#'   timestamp (`"2025-06-01T12:00:00Z"`), or a duration, such as `"7d"`.
#'   `NULL` removes the setting.
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
#' @returns The previous setting, or `NULL`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' pixi_set_date("2025-06-01")
#' pixi_set_date("7d")
#' pixi_set_date(NULL)
#' }
pixi_set_date <- function(date, path = NULL) {
  value <- exclude_newer_value(date)
  manifest <- require_pixi_toml(path)
  lines <- readLines(manifest, warn = FALSE)
  previous <- manifest_exclude_newer(lines)
  writeLines(set_exclude_newer(lines, value), manifest)

  if (is.null(value)) {
    cli::cli_alert_success(
      "Removed the date from {.file pixi.toml}. Get newer packages with {.code pixi_update()}."
    )
    return(invisible(previous))
  }
  cli::cli_alert_success(
    "Set {.code exclude-newer = \"{value}\"} in {.file pixi.toml}."
  )
  tryCatch(
    run_pixi("update", path = dirname(manifest), echo = TRUE),
    error = function(e) {
      writeLines(lines, manifest)
      cli::cli_abort(
        c(
          "Pixi couldn't solve the project with packages as of {.val {value}}, so {.file pixi.toml} is as it was.",
          "i" = "The project may pin versions newer than that, e.g. ones {.code pixi_add()} added. See Pixi's output above.",
          "i" = "Setting the date when you create a project, with {.code use_pixi(date = \"{value}\")}, avoids that."
        ),
        parent = e,
        call = NULL
      )
    }
  )
  invisible(previous)
}

# A date, timestamp or duration as Pixi's exclude-newer takes it
exclude_newer_value <- function(date, call = parent.frame()) {
  if (is.null(date)) {
    return(NULL)
  }
  if (inherits(date, "Date")) {
    return(format(date, "%Y-%m-%d"))
  }
  valid <- is.character(date) &&
    length(date) == 1 &&
    !is.na(date) &&
    (is_iso_date(date) ||
      grepl("^\\d{4}-\\d{2}-\\d{2}T\\S+$", date, perl = TRUE) ||
      grepl("^(\\d+\\s*[a-z]+\\s*)+$", date, ignore.case = TRUE, perl = TRUE))
  if (!valid) {
    cli::cli_abort(
      c(
        "{.arg date} must be a date, a timestamp or a duration.",
        "i" = "For example {.val 2025-06-01}, {.val 2025-06-01T12:00:00Z} or {.val 7d}."
      ),
      call = call
    )
  }
  date
}

is_iso_date <- function(text) {
  grepl("^\\d{4}-\\d{2}-\\d{2}$", text, perl = TRUE) &&
    !is.na(as.Date(text, format = "%Y-%m-%d", optional = TRUE))
}

# The workspace's exclude-newer, or NULL
manifest_exclude_newer <- function(lines) {
  rows <- workspace_rows(lines)
  found <- grep('^\\s*exclude-newer\\s*=\\s*"', lines[rows], value = TRUE)
  if (length(found) == 0) {
    return(NULL)
  }
  sub('^\\s*exclude-newer\\s*=\\s*"([^"]*)".*$', "\\1", found[1])
}

# Set the workspace's exclude-newer, or remove it with NULL
set_exclude_newer <- function(lines, value) {
  rows <- workspace_rows(lines)
  existing <- rows[grepl("^\\s*exclude-newer\\s*=", lines[rows])]
  if (is.null(value)) {
    return(if (length(existing)) lines[-existing] else lines)
  }
  line <- paste0('exclude-newer = "', value, '"')
  if (length(existing)) {
    lines[existing[1]] <- line
    return(lines)
  }
  if (is.null(rows)) {
    return(c("[workspace]", line, lines))
  }
  filled <- rows[nzchar(trimws(lines[rows]))]
  append(lines, line, after = filled[length(filled)])
}

workspace_rows <- function(lines) {
  table_lines(lines, "workspace") %||% table_lines(lines, "project")
}

# Whether exclude-newer is a date or timestamp, rather than a duration
is_absolute_date <- function(value) {
  !is.null(value) && grepl("^\\d{4}-\\d{2}-\\d{2}", value, perl = TRUE)
}

require_pixi_toml <- function(path, call = parent.frame()) {
  manifest <- find_manifest(path)
  if (is.null(manifest) || basename(manifest) != "pixi.toml") {
    cli::cli_abort(
      "This needs a Pixi project with a {.file pixi.toml} manifest.",
      call = call
    )
  }
  manifest
}
