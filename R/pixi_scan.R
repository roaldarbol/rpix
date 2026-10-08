#' Find packages the project's code uses
#'
#' @description
#' Look through the project's R code for the packages it uses, and compare
#' them with the packages in `pixi.toml`:
#'
#' * Packages the code uses, but that aren't in `pixi.toml`.
#' * R packages in the default environment that the code never uses.
#'
#' It reads `.R` files, and the R chunks of `.qmd` and `.Rmd` files, and finds
#' `library()`, `require()`, `requireNamespace()`, `loadNamespace()` and
#' `pkg::fun`. It skips the `.pixi`, `renv`, `docs` and `.git` folders. It
#' also finds `pkg::fun` in the commands of the project's Pixi tasks, such as
#' `Rscript -e 'devtools::test()'`.
#'
#' A package that only other packages need doesn't count as unused if it's
#' in `pixi.toml` on purpose, so check before removing one. rpix and the
#' packages it needs aren't listed as unused.
#'
#' @param add If `TRUE`, add the missing packages that are on conda-forge or
#'   bioconda.
#' @inheritParams pixi_environments
#' @returns A list, invisibly, with:
#'   * `used`: a data frame with a row per package the code uses, and the
#'     columns `package` and `files` (a list of the files that use it).
#'   * `missing`: the packages the code uses that aren't in `pixi.toml`.
#'   * `unused`: the R packages in the default environment the code doesn't
#'     use, as conda names.
#' @export
#' @examples
#' \dontrun{
#' pixi_scan()
#' pixi_scan(add = TRUE)
#' }
pixi_scan <- function(add = FALSE, path = NULL) {
  root <- require_project(path)
  used <- scan_project(root, task_commands(root))

  own <- package_name(root)
  in_manifest <- r_names(unlist(environment_dependencies(root)))
  missing <- setdiff(used$package, c(own, "rpix", base_packages()))
  missing <- missing[!tolower(missing) %in% in_manifest]

  ignore <- c("r-base", "r-languageserver", rpix_dependencies())
  default <- setdiff(project_dependencies(root), ignore)
  default <- default[grepl("^(r|bioconductor)-", default)]
  unused <- default[!r_names(default) %in% tolower(used$package)]

  cli::cli_alert_info(
    "The code uses {length(used$package)} package{?s}."
  )
  if (length(missing) > 0) {
    cli::cli_alert_warning("Not in {.file pixi.toml}: {.pkg {missing}}.")
    if (!add) {
      cli::cli_bullets(c(
        " " = "Add them with {.code pixi_scan(add = TRUE)}."
      ))
    }
  } else {
    cli::cli_alert_success("{.file pixi.toml} has all of them.")
  }
  if (length(unused) > 0) {
    cli::cli_alert_info("Never used in the code: {.pkg {unused}}.")
  }

  if (add && length(missing) > 0) {
    found <- find_r_packages(missing)
    if (any(!is.na(found))) {
      pixi_add(unname(found[!is.na(found)]), path = root)
    }
    if (anyNA(found)) {
      cli::cli_alert_warning(
        "Not on conda-forge or bioconda, so not added: {.pkg {names(found)[is.na(found)]}}."
      )
    }
  }

  invisible(list(used = used, missing = missing, unused = unused))
}

# The packages each R file in the project, and its tasks, use
scan_project <- function(root, commands = character()) {
  files <- list.files(
    root,
    pattern = "\\.([Rr]|qmd|[Rr]md|Rprofile)$",
    recursive = TRUE,
    all.files = TRUE
  )
  skipped <- "^(\\.pixi|renv|docs|\\.git|_site|_freeze|node_modules)/"
  files <- files[!grepl(skipped, files)]

  uses <- lapply(files, function(file) scan_file(file.path(root, file)))
  if (length(commands) > 0) {
    files <- c(files, "pixi.toml")
    uses <- c(uses, list(command_packages(commands)))
  }
  packages <- sort(unique(unlist(uses)))
  data.frame(
    package = packages,
    files = I(lapply(packages, function(package) {
      files[vapply(uses, function(u) package %in% u, logical(1))]
    })),
    stringsAsFactors = FALSE
  )
}

# The packages a file uses
scan_file <- function(file) {
  lines <- readLines(file, warn = FALSE)
  if (grepl("\\.(qmd|[Rr]md)$", file)) {
    lines <- r_chunks(lines)
  }
  code_packages(lines)
}

# The lines of a Quarto or R Markdown document's R chunks
r_chunks <- function(lines) {
  starts <- grepl("^\\s*```+\\s*\\{r[ ,}]", lines)
  ends <- grepl("^\\s*```+\\s*$", lines)
  inside <- FALSE
  keep <- logical(length(lines))
  for (i in seq_along(lines)) {
    if (!inside && starts[i]) {
      inside <- TRUE
    } else if (inside && ends[i]) {
      inside <- FALSE
    } else {
      keep[i] <- inside
    }
  }
  lines[keep]
}

# The packages R code uses, from R's own parser
code_packages <- function(lines) {
  exprs <- tryCatch(
    parse(text = lines, keep.source = TRUE),
    error = function(e) NULL
  )
  if (length(exprs) == 0) {
    return(character())
  }
  tokens <- utils::getParseData(exprs)
  tokens <- tokens[tokens$terminal, c("token", "text")]

  namespaced <- tokens$text[tokens$token == "SYMBOL_PACKAGE"]
  loaders <- c("library", "require", "requireNamespace", "loadNamespace")
  calls <- which(
    tokens$token == "SYMBOL_FUNCTION_CALL" & tokens$text %in% loaders
  )
  loaded <- vapply(
    calls,
    function(i) {
      arg <- i + 2
      # e.g. library(package = dplyr)
      if (identical(tokens$token[arg], "SYMBOL_SUB")) {
        arg <- arg + 2
      }
      if (isTRUE(tokens$token[arg] %in% c("SYMBOL", "STR_CONST"))) {
        gsub("^[\"']|[\"']$", "", tokens$text[arg])
      } else {
        NA_character_
      }
    },
    character(1)
  )
  packages <- unique(c(namespaced, stats::na.omit(loaded)))
  packages[is_r_package_name(packages)]
}

# The commands of the project's tasks
task_commands <- function(root) {
  commands <- pixi_tasks(path = root)$command
  commands[!is.na(commands)]
}

# The packages in shell commands, such as Rscript -e 'devtools::test()'
command_packages <- function(commands) {
  matches <- regmatches(
    commands,
    gregexpr("[A-Za-z][A-Za-z0-9.]*[A-Za-z0-9](?=:::?)", commands, perl = TRUE)
  )
  unique(unlist(matches))
}

# R package names, in lower case, for conda names
r_names <- function(conda) {
  tolower(sub("^(r|bioconductor)-", "", conda))
}

# The name of the package in the project, if there is one
package_name <- function(root) {
  description <- file.path(root, "DESCRIPTION")
  if (!file.exists(description)) {
    return(character())
  }
  unname(read.dcf(description, fields = "Package")[1, 1])
}

# The packages in each environment, by environment
environment_dependencies <- function(root) {
  envs <- pixi_info(root)$environments_info
  stats::setNames(unclass(envs$dependencies), envs$name)
}
