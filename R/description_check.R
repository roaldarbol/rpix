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

# In a package's Pixi environment, notice when DESCRIPTION comes to need
# packages that pixi.toml doesn't have, e.g. after usethis::use_package() or
# an edit, and offer to add them (#255). After each top-level call, a task
# callback compares DESCRIPTION's modification time with the last one it saw,
# so nothing else happens until DESCRIPTION changes. Only in interactive
# sessions; options(rpix.watch_description = FALSE) turns it off.
watch_description <- function(root) {
  if (
    !is_interactive() ||
      isFALSE(getOption("rpix.watch_description")) ||
      !is_package(root)
  ) {
    return(invisible(FALSE))
  }
  if (watcher_name %in% getTaskCallbackNames()) {
    removeTaskCallback(watcher_name)
  }
  # A DESCRIPTION it can't read mustn't stop the activation
  watcher <- tryCatch(description_watcher(root), error = function(e) NULL)
  if (is.null(watcher)) {
    return(invisible(FALSE))
  }
  addTaskCallback(watcher, name = watcher_name)
  invisible(TRUE)
}

watcher_name <- "rpix:description"

# The task callback: TRUE keeps it registered
description_watcher <- function(root) {
  description <- file.path(root, "DESCRIPTION")
  seen <- file.mtime(description)
  state <- description_state(root)
  function(...) {
    tryCatch(
      {
        changed <- file.mtime(description)
        if (!is.na(changed) && !identical(changed, seen)) {
          seen <<- changed
          state <<- description_changed(root, state)
        }
      },
      error = function(e) NULL
    )
    invisible(TRUE)
  }
}

# What DESCRIPTION lists, and which of those pixi.toml lacks
description_state <- function(root) {
  deps <- description_dependencies(file.path(root, "DESCRIPTION"))
  check <- description_check(root)
  list(
    listed = setdiff(unique(deps$package), c("R", base_packages())),
    lacking = c(check$missing, check$missing_suggests)
  )
}

# Says what changed since `before`, and offers to add what's new to
# pixi.toml. Returns the state to compare the next change with.
description_changed <- function(root, before) {
  now <- description_state(root)
  new <- setdiff(now$lacking, before$lacking)
  if (length(new) > 0) {
    cli::cli_alert_info(
      "{.file DESCRIPTION} now needs {.pkg {new}}, which {cli::qty(length(new))}{?isn't/aren't} in {.file pixi.toml}."
    )
    question <- cli::format_inline(
      "Would you like to add {cli::qty(length(new))}{?it/them}?"
    )
    if (isTRUE(ask_yes_no(question))) {
      pixi_import_description(path = root)
      now <- description_state(root)
    } else {
      hint(
        "Add {cli::qty(length(new))}{?it/them} with {.code rpix::pixi_import_description()}."
      )
    }
  }
  # Removing one is for the user to decide: pixi.toml can need a package for
  # other reasons, e.g. as a development tool
  dropped <- setdiff(before$listed, now$listed)
  if (length(dropped) > 0) {
    remove <- paste0("rpix::pixi_remove(", deparse1(dropped), ")")
    cli::cli_alert_info(
      "{.file DESCRIPTION} no longer lists {.pkg {dropped}}. If nothing else in the project uses {cli::qty(length(dropped))}{?it/them}, remove {?it/them} with {.code {remove}}."
    )
  }
  now
}
