# What pixi-build-r doesn't add to a package's build yet, read from its
# DESCRIPTION: build tools that SystemRequirements asks for, other than Rust
# (https://github.com/prefix-dev/pixi/issues/7239). With `older_backend` (see
# older_backend()), also what pixi-build-r only adds since 2026-10-12:
# * Rust (https://github.com/prefix-dev/pixi/issues/7228)
# * R's recommended packages, which conda-forge's r-base doesn't include
#   (https://github.com/prefix-dev/pixi/issues/7229)
# A list of conda packages for the build, host and run environments.
build_requirements <- function(description, older_backend = FALSE) {
  system <- description[["SystemRequirements"]] %||% NA
  found <- !is.na(system) &
    (older_backend | !build_tools$older_backend) &
    vapply(
      build_tools$pattern,
      grepl,
      logical(1),
      system,
      ignore.case = TRUE,
      perl = TRUE,
      USE.NAMES = FALSE
    )
  tools <- build_tools[found, ]
  recommended <- if (older_backend) {
    intersect(description_packages(description), recommended_packages)
  }
  recommended <- if (length(recommended) > 0) {
    paste0("r-", tolower(recommended))
  } else {
    character()
  }
  list(
    build = tools$package,
    host = recommended,
    run = c(tools$package[tools$run], recommended)
  )
}

# Build tools, by what SystemRequirements says, and the conda-forge package
# that provides each. Java is needed when the package runs, too. pixi-build-r
# adds Rust itself since 2026-10-12, so only older versions need it.
build_tools <- data.frame(
  pattern = c(
    "\\bcargo\\b|\\brustc\\b",
    "\\bjava\\b|\\bjdk\\b|\\bjre\\b",
    "\\bcmake\\b",
    "\\bpkg-?config\\b"
  ),
  package = c("rust", "openjdk", "cmake", "pkg-config"),
  run = c(FALSE, TRUE, FALSE, FALSE),
  older_backend = c(TRUE, FALSE, FALSE, FALSE)
)

# Whether the project may get a pixi-build-r from before 2026-10-12, when it
# started adding Rust and R's recommended packages, and installing into R's
# library on Windows. A project's exclude-newer applies to the build backend
# too (https://github.com/prefix-dev/pixi/issues/7240): a date before then, or
# a duration, which may reach back before then.
older_backend <- function(date) {
  !is.null(date) &&
    (!is_absolute_date(date) ||
      as.Date(substr(date, 1, 10)) < as.Date("2026-10-13"))
}

recommended_packages <- c(
  "KernSmooth",
  "MASS",
  "Matrix",
  "boot",
  "class",
  "cluster",
  "codetools",
  "foreign",
  "lattice",
  "mgcv",
  "nlme",
  "nnet",
  "rpart",
  "spatial",
  "survival"
)

# The packages in a DESCRIPTION's Depends, Imports and LinkingTo
description_packages <- function(description) {
  fields <- intersect(c("Depends", "Imports", "LinkingTo"), names(description))
  values <- unlist(description[fields])
  values <- values[!is.na(values)]
  if (length(values) == 0) {
    return(character())
  }
  entries <- trimws(unlist(strsplit(values, ",")))
  entries <- sub("[[:space:]]*\\(.*$", "", entries)
  unique(entries[nzchar(entries)])
}
