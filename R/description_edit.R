# Editing a package's DESCRIPTION, for pixi_add(type = ) and
# pixi_remove(type = ) (#256). Only the field it changes is rewritten, one
# entry per line as usethis writes them; the rest of the file stays as it is.

description_types <- c(
  "Imports",
  "Depends",
  "Suggests",
  "LinkingTo",
  "Enhances"
)

# The packages as DESCRIPTION names them, with their minimum versions: only a
# `>=` constraint goes into DESCRIPTION, as `(>= 1.1)`
description_entries <- function(
  packages,
  versions,
  type,
  path,
  call = parent.frame()
) {
  type <- check_description_type(type, call = call)
  root <- require_project(path, call = call)
  if (!is_package(root)) {
    cli::cli_abort(
      c(
        "{.arg type} is for packages, and there's no package in {.path {root}}.",
        "i" = "It adds the packages to a field of {.file DESCRIPTION}."
      ),
      call = call
    )
  }
  versions <- if (is.null(versions)) {
    rep(NA_character_, length(packages))
  } else {
    rep_len(versions, length(packages))
  }
  on_github <- is_github(packages)
  names <- character(length(packages))
  inline <- rep("", length(packages))
  names[on_github] <- vapply(
    packages[on_github],
    function(p) parse_github(p, call = call)$package,
    character(1)
  )
  if (any(!on_github)) {
    parsed <- parse_packages(packages[!on_github])
    conda <- parsed$input[parsed$source == "conda"]
    if (length(conda) > 0) {
      cli::cli_abort(
        c(
          "{.val {conda}} {cli::qty(length(conda))}{?isn't an R package/aren't R packages}, so {?it/they} can't go in {.file DESCRIPTION}.",
          "i" = "Add {cli::qty(length(conda))}{?it/them} without {.arg type}."
        ),
        call = call
      )
    }
    names[!on_github] <- package_r_names(parsed)
    inline[!on_github] <- parsed$constraint
  }
  constraint <- ifelse(is.na(versions), inline, versions)
  minimum <- ifelse(
    startsWith(constraint, ">="),
    # conda writes 1.2_3 for R's 1.2-3
    gsub("_", "-", trimws(sub("^>=", "", constraint)), fixed = TRUE),
    NA_character_
  )
  # GitHub packages go in Remotes too, as usethis::use_dev_package() adds
  # them, but not CRAN's mirror of a CRAN package
  repos <- sub("^github::", "", packages[on_github])
  repos <- repos[!startsWith(repos, "cran/")]
  list(
    file = file.path(root, "DESCRIPTION"),
    type = type,
    names = names,
    minimum = minimum,
    remotes = repos
  )
}

check_description_type <- function(type, call = parent.frame()) {
  if (
    !is.character(type) || length(type) != 1 || !type %in% description_types
  ) {
    cli::cli_abort(
      "{.arg type} must be one of {.or {.val {description_types}}}.",
      call = call
    )
  }
  type
}

# Add the entries to their field, or update the version of one that's there
add_to_description <- function(entries, dry_run = FALSE) {
  if (isTRUE(dry_run)) {
    cli::cli_alert_info(
      "Would add {.pkg {entries$names}} to {.field {entries$type}} in {.file DESCRIPTION}."
    )
    return(invisible(FALSE))
  }
  lines <- readLines(entries$file, warn = FALSE)
  rows <- dcf_field_rows(lines, entries$type)
  current <- dcf_field_entries(lines, rows, entries$type)
  for (i in seq_along(entries$names)) {
    entry <- entries$names[i]
    if (!is.na(entries$minimum[i])) {
      entry <- paste0(entry, " (>= ", entries$minimum[i], ")")
    }
    there <- dcf_entry_name(current) == entries$names[i]
    if (!any(there)) {
      current <- c(current, entry)
    } else if (!is.na(entries$minimum[i])) {
      current[there] <- entry
    }
  }
  lines <- dcf_set_field(lines, rows, entries$type, current)
  if (length(entries$remotes) > 0) {
    rows <- dcf_field_rows(lines, "Remotes")
    remotes <- dcf_field_entries(lines, rows, "Remotes")
    new <- setdiff(entries$remotes, remotes)
    lines <- dcf_set_field(lines, rows, "Remotes", c(remotes, new))
  }
  writeLines(lines, entries$file)
  cli::cli_alert_success(
    "Added {.pkg {entries$names}} to {.field {entries$type}} in {.file DESCRIPTION}."
  )
  if (length(entries$remotes) > 0) {
    cli::cli_alert_success(
      "Added {.val {entries$remotes}} to {.field Remotes}."
    )
  }
  invisible(TRUE)
}

# Remove the entries from their field, and the field if it's then empty
remove_from_description <- function(entries, dry_run = FALSE) {
  lines <- readLines(entries$file, warn = FALSE)
  rows <- dcf_field_rows(lines, entries$type)
  current <- dcf_field_entries(lines, rows, entries$type)
  listed <- intersect(entries$names, dcf_entry_name(current))
  if (length(listed) == 0) {
    cli::cli_alert_info(
      "{.field {entries$type}} in {.file DESCRIPTION} doesn't list {.pkg {entries$names}}."
    )
    return(invisible(FALSE))
  }
  if (isTRUE(dry_run)) {
    cli::cli_alert_info(
      "Would remove {.pkg {listed}} from {.field {entries$type}} in {.file DESCRIPTION}."
    )
    return(invisible(FALSE))
  }
  current <- current[!dcf_entry_name(current) %in% entries$names]
  lines <- dcf_set_field(lines, rows, entries$type, current)
  if (length(entries$remotes) > 0) {
    rows <- dcf_field_rows(lines, "Remotes")
    remotes <- dcf_field_entries(lines, rows, "Remotes")
    # With or without a ref
    keep <- !sub("@.*$", "", remotes) %in% sub("@.*$", "", entries$remotes)
    lines <- dcf_set_field(lines, rows, "Remotes", remotes[keep])
  }
  writeLines(lines, entries$file)
  cli::cli_alert_success(
    "Removed {.pkg {listed}} from {.field {entries$type}} in {.file DESCRIPTION}."
  )
  invisible(TRUE)
}

# The rows of a field: its first line, and the indented lines after it
dcf_field_rows <- function(lines, field) {
  start <- grep(paste0("^", field, ":"), lines)
  if (length(start) == 0) {
    return(integer())
  }
  end <- start[1]
  while (end < length(lines) && grepl("^[ \t]", lines[end + 1])) {
    end <- end + 1
  }
  start[1]:end
}

dcf_field_entries <- function(lines, rows, field) {
  if (length(rows) == 0) {
    return(character())
  }
  text <- sub(paste0("^", field, ":"), "", paste(lines[rows], collapse = " "))
  entries <- trimws(strsplit(text, ",")[[1]])
  gsub("[[:space:]]+", " ", entries[nzchar(entries)])
}

dcf_entry_name <- function(entries) {
  sub("[[:space:]]*\\(.*$", "", entries)
}

# Write the field in place of `rows`, at the end if it's new, or leave it out
# if it has no entries
dcf_set_field <- function(lines, rows, field, entries) {
  field_lines <- if (length(entries) > 0) {
    commas <- c(rep(",", length(entries) - 1), "")
    c(paste0(field, ":"), paste0("    ", entries, commas))
  }
  if (length(rows) == 0) {
    # Before any blank lines at the end
    last <- max(c(0, which(nzchar(trimws(lines)))))
    return(c(lines[seq_len(last)], field_lines, lines[-seq_len(last)]))
  }
  c(
    lines[seq_len(rows[1] - 1)],
    field_lines,
    lines[-seq_len(rows[length(rows)])]
  )
}
