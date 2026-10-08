# Print methods for what rpix returns. The results stay data frames (or a
# list), with a class in front for printing; the methods fall back to the
# default when columns have been dropped.

new_rpix_df <- function(x, class, ...) {
  attributes(x) <- c(attributes(x), list(...))
  class(x) <- c(class, "data.frame")
  x
}

#' @export
print.rpix_tasks <- function(x, ...) {
  if (!has_columns(x, c("name", "command", "description", "feature"))) {
    return(NextMethod())
  }
  cli::cat_line(cli::rule(left = "Tasks"))
  if (nrow(x) == 0) {
    cli::cat_line(cli::col_grey("No tasks."))
    return(invisible(x))
  }

  groups <- split(seq_len(nrow(x)), factor(x$feature, unique(x$feature)))
  na <- which(is.na(x$feature))
  if (length(na) > 0) {
    groups <- c(groups, list(na))
  }
  width <- max(nchar(x$name))
  for (rows in groups) {
    if (length(groups) > 1) {
      feature <- x$feature[rows[1]]
      cli::cat_line()
      cli::cat_line(
        if (is.na(feature)) {
          paste(
            cli::style_bold(unlist(x$environments[rows[1]])),
            "environment"
          )
        } else {
          paste(cli::style_bold(feature), "feature")
        },
        if (!is.na(feature) && has_columns(x, "environments")) {
          cli::col_grey(
            " (",
            paste(unlist(x$environments[rows[1]]), collapse = ", "),
            ")"
          )
        }
      )
    }
    for (i in rows) {
      text <- if (is.na(x$description[i])) {
        cli::col_grey(x$command[i] %|NA|% "")
      } else {
        x$description[i]
      }
      extras <- c(
        list_item(x, "args", i, "args: "),
        list_item(x, "depends_on", i, "after: ")
      )
      cat_labelled(
        x$name[i],
        trimws(paste0(
          text,
          if (length(extras) > 0) {
            cli::col_grey(paste0(" (", paste(extras, collapse = "; "), ")"))
          }
        )),
        width,
        cli::style_bold
      )
    }
  }
  invisible(x)
}

#' @export
print.rpix_environments <- function(x, ...) {
  if (!has_columns(x, c("name", "features", "solve_group"))) {
    return(NextMethod())
  }
  cli::cat_line(cli::rule(left = "Environments"))
  width <- max(nchar(x$name), 0)
  for (i in seq_len(nrow(x))) {
    cat_labelled(
      x$name[i],
      environment_line(x, i),
      width,
      cli::style_bold
    )
  }
  invisible(x)
}

#' @export
print.rpix_packages <- function(x, n = NULL, ...) {
  columns <- c("name", "version", "r_package", "explicit", "channel")
  if (!has_columns(x, columns)) {
    return(NextMethod())
  }
  environment <- attr(x, "environment") %||% "default"
  cli::cat_line(cli::rule(
    left = paste0(
      cli::style_bold(environment),
      " environment: ",
      nrow(x),
      " package",
      if (nrow(x) != 1) "s",
      ", ",
      sum(x$explicit),
      " in pixi.toml"
    )
  ))
  if (nrow(x) == 0) {
    return(invisible(x))
  }

  n <- n %||% if (nrow(x) > 30) 20 else nrow(x)
  shown <- x[seq_len(min(n, nrow(x))), columns]
  colours <- cli::num_ansi_colors() > 1
  table <- data.frame(
    Package = shown$name,
    Version = shown$version,
    `R package` = shown$r_package %|NA|% "",
    Channel = shown$channel,
    check.names = FALSE
  )
  lines <- format_table(table)
  bold <- c(FALSE, shown$explicit)
  if (colours) {
    lines[bold] <- cli::style_bold(lines[bold])
  } else {
    lines <- paste0(ifelse(bold, "* ", "  "), lines)
  }
  lines[1] <- cli::col_grey(lines[1])
  cli::cat_line(lines)

  if (nrow(x) > n) {
    cli::cat_line(cli::col_grey(
      "... and ",
      nrow(x) - n,
      " more. See them all with `print(x, n = Inf)`."
    ))
  }
  cli::cat_line(cli::col_grey(
    if (colours) "Packages in pixi.toml are in bold." else "* in pixi.toml"
  ))
  invisible(x)
}

#' @export
print.rpix_info <- function(x, ...) {
  cli::cat_line(cli::rule(left = "Pixi"))
  key_values(c(
    Version = x$version,
    Platform = x$platform,
    Cache = x$cache_dir
  ))

  project <- x$project_info
  if (!is.null(project)) {
    cli::cat_line()
    cli::cat_line(cli::rule(left = "Project"))
    key_values(c(Name = project$name, Manifest = project$manifest_path))
  }

  envs <- x$environments_info
  for (i in seq_len(NROW(envs))) {
    platforms <- envs$platforms[[i]]
    if (is.data.frame(platforms)) {
      platforms <- platforms$name
    }
    cli::cat_line()
    cli::cat_line(cli::rule(
      left = paste(cli::style_bold(envs$name[i]), "environment")
    ))
    key_values(c(
      Features = collapse(envs$features[[i]]),
      `Solve group` = if (!is.na(envs$solve_group[i] %||% NA)) {
        envs$solve_group[i]
      },
      Dependencies = collapse(envs$dependencies[[i]]),
      `PyPI dependencies` = collapse(envs$pypi_dependencies[[i]]),
      Tasks = collapse(sort(unlist(envs$tasks[[i]]))),
      Channels = collapse(envs$channels[[i]]),
      Platforms = collapse(sort(unique(platforms))),
      Location = envs$prefix[i]
    ))
  }
  invisible(x)
}

environment_line <- function(x, i) {
  details <- c(
    if (!is.na(x$solve_group[i])) paste("solve group:", x$solve_group[i]),
    list_item(x, "platforms", i, "on ", order = sort)
  )
  paste0(
    paste(unlist(x$features[i]), collapse = ", "),
    if (length(details) > 0) {
      cli::col_grey(paste0(" (", paste(details, collapse = "; "), ")"))
    }
  )
}

# Helpers ----------------------------------------------------------------------

has_columns <- function(x, columns) {
  all(columns %in% names(x))
}

`%|NA|%` <- function(x, y) {
  ifelse(is.na(x), y, x)
}

collapse <- function(x) {
  x <- unlist(x)
  if (length(x) == 0) NULL else paste(x, collapse = ", ")
}

# A list column's entry, as text, or nothing if it's empty
list_item <- function(
  x,
  column,
  i,
  prefix,
  order = identity
) {
  if (!has_columns(x, column)) {
    return(NULL)
  }
  values <- order(unlist(x[[column]][i]))
  if (length(values) == 0) {
    return(NULL)
  }
  paste0(prefix, paste(values, collapse = ", "))
}

# A label, and a value wrapped to the console's width beside it
cat_labelled <- function(label, value, width, style = cli::col_grey) {
  indent <- width + 2
  lines <- cli::ansi_strwrap(
    value,
    width = max(cli::console_width() - indent, 20)
  )
  cli::cat_line(c(
    paste0(style(cli::ansi_align(label, width)), "  ", lines[1]),
    if (length(lines) > 1) paste0(strrep(" ", indent), lines[-1])
  ))
}

# Labels and values, aligned
key_values <- function(values) {
  values <- unlist(values)
  width <- max(nchar(names(values)), 0)
  for (label in names(values)) {
    cat_labelled(label, values[[label]], width)
  }
  invisible()
}

# A data frame as aligned lines of text, with a header
format_table <- function(df) {
  columns <- lapply(names(df), function(name) {
    values <- c(name, as.character(df[[name]]))
    format(values, width = max(nchar(values)))
  })
  lines <- do.call(paste, c(columns, sep = "  "))
  sub("\\s+$", "", lines)
}

#' @export
print.rpix_check_matrix <- function(x, ...) {
  if (!has_columns(x, c("environment", "r_version", "ok", "output"))) {
    return(NextMethod())
  }
  what <- attr(x, "what") %||% "task"
  title <- c(test = "Tests", check = "R CMD check", task = "Task")[[what]]
  cli::cat_line(cli::rule(left = title))
  width <- max(nchar(x$environment), 0)
  for (i in seq_len(nrow(x))) {
    counts <- check_counts[[what]]
    counts <- counts[counts %in% names(x)]
    summary <- if (length(counts) > 0 && !is.na(x[[counts[1]]][i])) {
      values <- unlist(x[i, counts])
      labels <- ifelse(values == 1, sub("s$", "", counts), counts)
      paste(values, labels, collapse = ", ")
    } else if (x$ok[i]) {
      "passed"
    } else {
      "failed"
    }
    mark <- if (x$ok[i]) {
      cli::col_green(cli::symbol$tick)
    } else {
      cli::col_red(cli::symbol$cross)
    }
    cat_labelled(
      paste(mark, x$environment[i]),
      paste0(
        if (!is.na(x$r_version[i])) paste0("R ", x$r_version[i], ": "),
        summary,
        if (has_columns(x, "seconds")) {
          cli::col_grey(" (", format_seconds(x$seconds[i]), ")")
        }
      ),
      width + 2,
      identity
    )
  }
  if (!all(x$ok)) {
    cli::cat_line(cli::col_grey(
      "See what failed with `cat(x$output[[i]])`, for row `i`."
    ))
  }
  invisible(x)
}
