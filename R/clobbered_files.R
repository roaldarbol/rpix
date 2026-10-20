# Files that more than one package in an environment installs, for
# pixi_sitrep() (#176). Whichever package was installed last wins, and nothing
# warns: e.g. on Windows, Strawberry Perl's old MinGW runtime over
# conda-forge's, so compiled R packages can't load (#175, #177). Read from
# each package's record in conda-meta, so it needs neither Pixi nor R.

# A data frame with a row per file that matters: the environment, the file,
# the package whose copy is there (NA if none matches), its build, and the
# packages whose copies lost
clobbered_files <- function(project) {
  envs <- list.dirs(
    file.path(project, ".pixi", "envs"),
    full.names = TRUE,
    recursive = FALSE
  )
  rows <- lapply(envs, clobbered_in)
  rows <- do.call(rbind, rows[lengths(rows) > 0])
  rows %||% clobbered_frame()
}

clobbered_frame <- function(
  environment = character(),
  path = character(),
  winner = character(),
  build = character(),
  losers = character()
) {
  data.frame(
    environment = environment,
    path = path,
    winner = winner,
    build = build,
    losers = losers,
    stringsAsFactors = FALSE
  )
}

clobbered_in <- function(prefix) {
  records <- list.files(
    file.path(prefix, "conda-meta"),
    pattern = "[.]json$",
    full.names = TRUE
  )
  files <- do.call(rbind, lapply(records, record_files))
  if (is.null(files)) {
    return(NULL)
  }
  files <- files[matters(files$path), ]
  shared <- files[files$path %in% files$path[duplicated(files$path)], ]
  rows <- lapply(split(shared, shared$path), function(owners) {
    file <- file.path(prefix, owners$path[1])
    won <- if (file.exists(file)) {
      actual <- cli::hash_file_sha256(file)
      !is.na(owners$sha256) & tolower(owners$sha256) == tolower(actual)
    } else {
      rep(FALSE, nrow(owners))
    }
    clobbered_frame(
      environment = basename(prefix),
      path = owners$path[1],
      winner = if (any(won)) owners$package[won][1] else NA_character_,
      build = if (any(won)) owners$build[won][1] else NA_character_,
      losers = paste(owners$package[!won], collapse = ", ")
    )
  })
  renamed <- clobber_renamed(prefix)
  do.call(rbind, c(rows, list(renamed)))
}

# The files a package's record lists, with their checksums
record_files <- function(file) {
  record <- tryCatch(jsonlite::read_json(file), error = function(e) NULL)
  paths <- record$paths_data$paths
  if (length(paths) == 0) {
    return(NULL)
  }
  data.frame(
    package = record$name %||% NA_character_,
    build = record$build %||% NA_character_,
    path = vapply(paths, function(p) p[["_path"]] %||% NA_character_, ""),
    sha256 = vapply(paths, function(p) p[["sha256"]] %||% NA_character_, ""),
    stringsAsFactors = FALSE
  )
}

# Shared libraries and executables, where the wrong copy breaks something.
# Licences and documentation overlap often, and harmlessly.
matters <- function(path) {
  grepl("^(Library/bin|bin|Scripts)/[^/]+$", path) |
    grepl("^(Library/)?lib/[^/]+[.](so([.][0-9]+)*|dylib|dll)$", path) |
    grepl("^(lib|Lib)/R/library/[^/]+/libs/", path)
}

# Files rattler renamed because another package has them too
# (`<file>__clobber-from-<package>`)
clobber_renamed <- function(prefix) {
  folders <- file.path(prefix, c("bin", "lib", "Library/bin", "Scripts"))
  found <- unlist(lapply(folders, function(folder) {
    list.files(folder, pattern = "__clobber-from-", full.names = TRUE)
  }))
  if (length(found) == 0) {
    return(NULL)
  }
  relative <- substring(found, nchar(prefix) + 2)
  clobbered_frame(
    environment = basename(prefix),
    path = sub("__clobber-from-.*$", "", relative),
    winner = NA_character_,
    build = NA_character_,
    losers = sub("^.*__clobber-from-", "", relative)
  )
}

# Strawberry Perl's MinGW runtime, which conda-forge's perl puts over
# conda-forge's own on Windows (#177; conda-forge/perl-feedstock#89)
strawberry_runtime <- function(clobbered) {
  clobbered[
    !is.na(clobbered$winner) &
      clobbered$winner == "perl" &
      grepl("strawberry", clobbered$build) &
      grepl(
        "(libstdc\\+\\+|libgcc_s|libwinpthread)[^/]*[.]dll$",
        clobbered$path
      ),
  ]
}

# For pixi_sitrep()
show_clobbered <- function(clobbered) {
  n <- nrow(clobbered)
  shown <- utils::head(clobbered, 10)
  lines <- ifelse(
    is.na(shown$winner),
    paste0(
      "{.file ",
      shown$path,
      "} in {.val ",
      shown$environment,
      "}: ",
      shown$losers,
      "'s copy was set aside"
    ),
    paste0(
      "{.file ",
      shown$path,
      "} in {.val ",
      shown$environment,
      "}: ",
      shown$winner,
      "'s copy, over ",
      shown$losers,
      "'s"
    )
  )
  packages <- unique(stats::na.omit(c(
    shown$winner,
    unlist(strsplit(shown$losers, ", "))
  )))
  tree <- paste0("rpix::pixi_tree(\"", packages[1], "\", invert = TRUE)")
  cli::cli_alert_warning(
    "{n} file{?s} {?is/are} installed by more than one package. Only one copy can be there, so the other package may not work."
  )
  cli::cli_bullets(c(
    stats::setNames(lines, rep("*", length(lines))),
    if (n > 10) c(" " = "And {n - 10} more."),
    " " = "To see what brings a package in, e.g. {packages[1]}, run {.code {tree}}."
  ))

  strawberry <- strawberry_runtime(clobbered)
  if (nrow(strawberry) > 0) {
    environments <- unique(strawberry$environment)
    cli::cli_alert_danger(
      "In {.val {environments}}, Strawberry Perl's MinGW runtime is there in place of conda-forge's, so compiled R packages can fail to load on Windows, with {.emph The specified procedure could not be found}."
    )
    hint(
      "Find what brings perl in with {.code rpix::pixi_tree(\"perl\", invert = TRUE)}, and drop it, or move it to an environment without R. See {.url https://github.com/conda-forge/perl-feedstock/issues/89}."
    )
  }
  invisible(clobbered)
}
