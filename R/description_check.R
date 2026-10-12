# Compare a package's DESCRIPTION with the project's pixi.toml, for
# pixi_sitrep(): the hard dependencies the default environment doesn't
# declare, the Suggests pixi.toml doesn't have anywhere, and, when the
# running R is the project's, installed versions older than DESCRIPTION asks
# for. NULL for projects that aren't packages.
description_check <- function(root, in_project = FALSE) {
  manifest <- find_manifest(root)
  if (!is_package(root) || is.null(manifest)) {
    return(NULL)
  }
  deps <- description_dependencies(file.path(root, "DESCRIPTION"))
  deps <- deps[!deps$package %in% c("R", base_packages()), ]
  lines <- readLines(manifest, warn = FALSE)

  hard <- deps[deps$field != "Suggests", ]
  hard_names <- unique(hard$package)
  suggests <- setdiff(
    unique(deps$package[deps$field == "Suggests"]),
    hard_names
  )
  in_default <- declared_r_packages(lines, default = TRUE)
  anywhere <- declared_r_packages(lines, default = FALSE)

  list(
    missing = hard_names[!tolower(hard_names) %in% in_default],
    missing_suggests = suggests[!tolower(suggests) %in% anywhere],
    too_old = if (in_project) too_old(hard) else too_old(hard[0, ])
  )
}

# The R packages pixi.toml declares, as lowercase R names (r-cli and
# bioconductor-limma become cli and limma). With `default`, only the default
# feature's tables, which every environment that uses it gets.
declared_r_packages <- function(lines, default = TRUE) {
  headers <- grep("^\\s*\\[", lines)
  tables <- trimws(gsub("[][]", "", lines[headers]))
  pattern <- if (default) {
    "^(target\\.[^.]+\\.)?dependencies$"
  } else {
    "(^|\\.)dependencies$"
  }
  keys <- unlist(lapply(tables[grepl(pattern, tables)], function(table) {
    rows <- table_lines(lines, table)[-1]
    found <- regmatches(
      lines[rows],
      regexpr('^\\s*"?[A-Za-z0-9._-]+"?(?=\\s*=)', lines[rows], perl = TRUE)
    )
    gsub('[[:space:]"]', "", found)
  }))
  r <- keys[grepl("^(r|bioconductor)-", keys)]
  unique(tolower(sub("^(r|bioconductor)-", "", r)))
}

# The hard dependencies installed at a lower version than DESCRIPTION's
# minimum, in the running R
too_old <- function(hard) {
  minimum <- hard[startsWith(hard$constraint, ">="), ]
  rows <- lapply(seq_len(nrow(minimum)), function(i) {
    package <- minimum$package[i]
    # conda writes 1.2_3 for R's 1.2-3
    needs <- gsub("_", "-", sub("^>=", "", minimum$constraint[i]), fixed = TRUE)
    installed <- tryCatch(
      as.character(utils::packageVersion(package)),
      error = function(e) NA_character_
    )
    if (
      is.na(installed) || package_version(installed) >= package_version(needs)
    ) {
      return(NULL)
    }
    data.frame(package = package, installed = installed, needs = needs)
  })
  do.call(rbind, rows) %||%
    data.frame(
      package = character(),
      installed = character(),
      needs = character()
    )
}
