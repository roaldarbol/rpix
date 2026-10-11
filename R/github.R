# R packages from GitHub, built by Pixi's R build backend, pixi-build-r.
# `pixi add` can't set a build backend yet
# (https://github.com/prefix-dev/pixi/issues/7213), so the dependency is
# written into pixi.toml, and Pixi installs it.

is_github <- function(packages) {
  grepl("^github::", packages, ignore.case = TRUE)
}

# "github::user/repo@ref" as a list with the repository, the ref (or NULL),
# and from the package's DESCRIPTION, its conda name and what pixi-build-r
# doesn't add to its build yet (see build_requirements())
parse_github <- function(package, call = parent.frame()) {
  pattern <- "^github::([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)(@(.+))?$"
  if (!grepl(pattern, package, ignore.case = TRUE)) {
    cli::cli_abort(
      c(
        "{.val {package}} isn't a GitHub package reference.",
        "i" = "Use {.code github::user/repo}, or {.code github::user/repo@ref} for a branch, tag or commit."
      ),
      call = call
    )
  }
  user <- sub(pattern, "\\1", package, ignore.case = TRUE)
  repo <- sub(pattern, "\\2", package, ignore.case = TRUE)
  ref <- sub(pattern, "\\4", package, ignore.case = TRUE)
  ref <- if (nzchar(ref)) ref else NULL
  description <- github_description(user, repo, ref, call = call)
  list(
    git = paste0("https://github.com/", user, "/", repo),
    ref = ref,
    # The package's name can differ from the repository's
    name = paste0("r-", tolower(description$Package)),
    requirements = build_requirements(description)
  )
}

# The package's DESCRIPTION, as a list of its fields
github_description <- function(user, repo, ref = NULL, call = parent.frame()) {
  url <- paste0(
    "https://raw.githubusercontent.com/",
    user,
    "/",
    repo,
    "/",
    ref %||% "HEAD",
    "/DESCRIPTION"
  )
  lines <- tryCatch(read_url(url), error = function(e) NULL)
  description <- if (!is.null(lines)) {
    as.list(read.dcf(textConnection(lines))[1, ])
  }
  if (is.null(description$Package)) {
    cli::cli_abort(
      c(
        "Couldn't read the R package in {.url https://github.com/{user}/{repo}}{if (!is.null(ref)) paste0(' at ', ref)}.",
        "i" = "It needs a {.file DESCRIPTION} file at the top of the repository."
      ),
      call = call
    )
  }
  description
}

read_url <- function(url) {
  connection <- url(url)
  on.exit(close(connection))
  # A missing file is an error, without R's own warning about it
  suppressWarnings(readLines(connection, warn = FALSE))
}

# GitHub packages with `versions` as their ref, e.g. "github::cran/praise"
# with "1.0.0" becomes "github::cran/praise@1.0.0"
with_github_refs <- function(packages, versions, call = parent.frame()) {
  if (length(versions) == 0) {
    return(packages)
  }
  given <- !is.na(versions) & nzchar(versions)
  ref <- sub("^==?", "", versions)
  range <- given & grepl("^[<>!~]|[,*|]", ref)
  if (any(range)) {
    cli::cli_abort(
      c(
        "A package from GitHub takes a branch, tag or commit, not a range like {.val {versions[range][1]}}.",
        "i" = "Pixi builds it from that point in its history."
      ),
      call = call
    )
  }
  both <- given & grepl("@", packages, fixed = TRUE)
  if (any(both)) {
    cli::cli_abort(
      "Give the branch, tag or commit of {.val {packages[both][1]}} either with {.code @ref} or in {.arg versions}, not both.",
      call = call
    )
  }
  packages[given] <- paste0(packages[given], "@", ref[given])
  packages
}

add_github_packages <- function(
  packages,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE,
  call = parent.frame()
) {
  manifest <- find_manifest(path)
  if (is.null(manifest) || basename(manifest) != "pixi.toml") {
    cli::cli_abort(
      "Packages from GitHub can only be added to a {.file pixi.toml} manifest.",
      call = call
    )
  }
  lines <- readLines(manifest, warn = FALSE)
  original <- lines
  r_base <- manifest_r_base(lines, feature)

  for (package in packages) {
    github <- parse_github(package, call = call)
    entry <- github_entry(github, r_base)
    added <- unique(unlist(github$requirements))
    if (length(added) > 0) {
      cli::cli_alert_info(
        "Adding {.pkg {added}} to the build of {.pkg {github$name}}, as {.code pixi-build-r} doesn't yet."
      )
    }
    if (isTRUE(dry_run)) {
      cli::cli_alert_info(
        "Would add to {.file pixi.toml}: {.code {entry}}"
      )
      next
    }
    lines <- set_dependency(
      lines,
      dependency_table(feature, platform),
      github$name,
      entry
    )
  }
  if (isTRUE(dry_run)) {
    return(invisible(NULL))
  }
  lines <- enable_preview(lines, "pixi-build")
  writeLines(lines, manifest)

  cli::cli_inform(
    c(
      "i" = "Pixi builds {cli::qty(length(packages))}{?it/them} from source with {.code pixi-build-r}, which can take a minute.",
      "i" = "Packages from GitHub are experimental: see {.url https://github.com/roaldarbol/rpix/issues/96}."
    )
  )
  tryCatch(
    run_pixi(
      if (is.null(feature)) "install" else "lock",
      path = dirname(manifest),
      echo = TRUE
    ),
    error = function(e) {
      writeLines(original, manifest)
      cli::cli_abort(
        c(
          "Pixi couldn't build {.pkg {packages}}, so {.file pixi.toml} is as it was.",
          "i" = "See Pixi's output above."
        ),
        parent = e,
        call = call
      )
    }
  )
  invisible(manifest)
}

# The inline package for a GitHub package, built with pixi-build-r. R is
# pinned for the build, as it otherwise builds for the newest R
# (https://github.com/prefix-dev/pixi/issues/7214).
github_entry <- function(github, r_base = NULL) {
  requirements <- github$requirements
  any_version <- function(packages) {
    stats::setNames(rep("*", length(packages)), packages)
  }
  tables <- list(
    "build-dependencies" = any_version(requirements$build),
    "host-dependencies" = c(
      if (!is.null(r_base)) c("r-base" = r_base),
      any_version(requirements$host)
    ),
    "run-dependencies" = any_version(requirements$run)
  )
  tables <- tables[lengths(tables) > 0]
  package <- ', package = { build.backend.name = "pixi-build-r"'
  if (length(tables) > 0) {
    package <- paste0(
      package,
      paste0(
        ", ",
        names(tables),
        " = ",
        vapply(tables, toml_table, character(1)),
        collapse = ""
      )
    )
  }
  package <- paste0(package, " }")
  paste0(
    github$name,
    ' = { git = "',
    github$git,
    '"',
    if (!is.null(github$ref)) paste0(', rev = "', github$ref, '"'),
    package,
    " }"
  )
}

# A named character vector as an inline TOML table of strings
toml_table <- function(values) {
  paste0(
    "{ ",
    paste0(names(values), ' = "', values, '"', collapse = ", "),
    " }"
  )
}

dependency_table <- function(feature = NULL, platform = NULL) {
  paste0(
    if (!is.null(feature)) paste0("feature.", feature, "."),
    if (!is.null(platform)) paste0("target.", platform, "."),
    "dependencies"
  )
}

# The lines of a TOML table, from its header to the next header
table_lines <- function(lines, table) {
  headers <- grep("^\\s*\\[", lines)
  start <- which(trimws(lines) == paste0("[", table, "]"))
  if (length(start) == 0) {
    return(NULL)
  }
  end <- c(headers[headers > start[1]], length(lines) + 1)[1] - 1
  seq(start[1], end)
}

# Add a dependency to a table, or replace it if it's there
set_dependency <- function(lines, table, name, entry) {
  rows <- table_lines(lines, table)
  if (is.null(rows)) {
    while (length(lines) > 0 && !nzchar(trimws(lines[length(lines)]))) {
      lines <- lines[-length(lines)]
    }
    return(c(lines, "", paste0("[", table, "]"), entry))
  }
  key <- paste0("^\\s*", gsub(".", "\\.", name, fixed = TRUE), "\\s*=")
  existing <- rows[grepl(key, lines[rows])]
  if (length(existing) > 0) {
    lines[existing[1]] <- entry
    return(lines)
  }
  # After the table's last non-empty line
  filled <- rows[nzchar(trimws(lines[rows]))]
  after <- filled[length(filled)]
  append(lines, entry, after = after)
}

# Turn on a preview feature of Pixi in [workspace]
enable_preview <- function(lines, feature) {
  rows <- table_lines(lines, "workspace") %||% table_lines(lines, "project")
  if (is.null(rows)) {
    return(c(paste0('[workspace]\npreview = ["', feature, '"]'), lines))
  }
  preview <- rows[grepl("^\\s*preview\\s*=", lines[rows])]
  if (length(preview) > 0) {
    line <- lines[preview[1]]
    if (!grepl(paste0('"', feature, '"'), line, fixed = TRUE)) {
      lines[preview[1]] <- sub(
        "\\[\\s*",
        paste0('["', feature, '", '),
        line
      )
      lines[preview[1]] <- sub(", \\]", "]", lines[preview[1]])
    }
    return(lines)
  }
  filled <- rows[nzchar(trimws(lines[rows]))]
  append(
    lines,
    paste0('preview = ["', feature, '"]'),
    after = filled[length(filled)]
  )
}

# The project's constraint on R, for the feature if it has its own
manifest_r_base <- function(lines, feature = NULL) {
  tables <- c(
    if (!is.null(feature)) dependency_table(feature),
    "dependencies"
  )
  for (table in tables) {
    rows <- table_lines(lines, table)
    found <- grep('^\\s*r-base\\s*=\\s*"', lines[rows], value = TRUE)
    if (length(found) > 0) {
      return(sub('^\\s*r-base\\s*=\\s*"([^"]*)".*$', "\\1", found[1]))
    }
  }
  NULL
}
