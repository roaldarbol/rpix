# What pixi-build-r doesn't add to a package's build yet, read from its
# DESCRIPTION:
# * build tools that SystemRequirements asks for
#   (https://github.com/prefix-dev/pixi/issues/7228)
# * R's recommended packages, which pixi-build-r takes to come with R, but
#   conda-forge's r-base doesn't include
#   (https://github.com/prefix-dev/pixi/issues/7229)
# A list of conda packages for the build, host and run environments.
build_requirements <- function(description) {
  system <- description[["SystemRequirements"]] %||% NA
  found <- !is.na(system) &
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
  recommended <- intersect(
    description_packages(description),
    recommended_packages
  )
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
# that provides each. Java is needed when the package runs, too.
build_tools <- data.frame(
  pattern = c(
    "\\bcargo\\b|\\brustc\\b",
    "\\bjava\\b|\\bjdk\\b|\\bjre\\b",
    "\\bcmake\\b",
    "\\bpkg-?config\\b"
  ),
  package = c("rust", "openjdk", "cmake", "pkg-config"),
  run = c(FALSE, TRUE, FALSE, FALSE)
)

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
