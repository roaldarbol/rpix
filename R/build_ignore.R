# Leave files out of a package's builds, as usethis::use_build_ignore() does.
# Projects that aren't packages are left alone. Returns the patterns added.
build_ignore <- function(root, files) {
  missing <- missing_build_ignores(root, files)
  if (length(missing) == 0) {
    return(invisible(character()))
  }
  file <- file.path(root, ".Rbuildignore")
  lines <- if (file.exists(file)) readLines(file, warn = FALSE)
  new <- paste0("^", gsub(".", "\\.", missing, fixed = TRUE), "$")
  writeLines(c(lines, new), file)
  cli::cli_alert_success("Added {.code {new}} to {.file .Rbuildignore}.")
  invisible(new)
}

# The files that a package's .Rbuildignore doesn't leave out. R matches its
# patterns against paths relative to the package, ignoring case.
missing_build_ignores <- function(root, files) {
  if (!is_package(root)) {
    return(character())
  }
  file <- file.path(root, ".Rbuildignore")
  patterns <- if (file.exists(file)) {
    readLines(file, warn = FALSE)
  } else {
    character()
  }
  patterns <- patterns[nzchar(patterns) & !startsWith(patterns, "#")]
  ignored <- function(path) {
    matches <- vapply(
      patterns,
      function(p) {
        isTRUE(tryCatch(
          suppressWarnings(grepl(p, path, perl = TRUE, ignore.case = TRUE)),
          error = function(e) FALSE
        ))
      },
      logical(1)
    )
    any(matches)
  }
  files[!vapply(files, ignored, logical(1), USE.NAMES = FALSE)]
}

# Pixi's files in a project
pixi_files <- function(root) {
  manifest <- find_manifest(root)
  c(
    ".pixi",
    if (is.null(manifest)) "pixi.toml" else basename(manifest),
    "pixi.lock"
  )
}

is_package <- function(root) {
  file <- file.path(root, "DESCRIPTION")
  file.exists(file) &&
    isTRUE(tryCatch(
      "Package" %in% colnames(read.dcf(file)),
      error = function(e) FALSE
    ))
}
