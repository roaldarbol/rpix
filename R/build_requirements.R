# What pixi-build-r doesn't add to a package's build, read from its
# DESCRIPTION: Java, when SystemRequirements asks for it. The package needs it
# when it runs, too. pixi-build-r adds Rust, CMake, pkg-config and R's
# recommended packages itself since 0.2.0 (see backend_version).
# A list of conda packages for the build, host and run environments.
build_requirements <- function(description) {
  system <- description[["SystemRequirements"]] %||% NA
  java <- !is.na(system) &&
    grepl(
      "\\bjava\\b|\\bjdk\\b|\\bjre\\b",
      system,
      ignore.case = TRUE,
      perl = TRUE
    )
  tools <- if (java) "openjdk" else character()
  list(build = tools, host = character(), run = tools)
}

# The pixi-build-r that rpix's entries ask for: 0.2.0, published on
# conda-forge on 2026-10-14, is the first to add Rust, CMake, pkg-config and R's
# recommended packages, and to install into R's library on Windows
# (https://github.com/prefix-dev/pixi/issues/7228,
# https://github.com/prefix-dev/pixi/issues/7229,
# https://github.com/prefix-dev/pixi/issues/7231,
# https://github.com/prefix-dev/pixi/issues/7239).
backend_version <- ">=0.2"

# Whether the project's exclude-newer hides pixi-build-r 0.2.0: it applies to
# the build backend too (https://github.com/prefix-dev/pixi/issues/7240), so a
# date before 2026-10-15 does. A duration only does for a while after the
# release, which rpix doesn't work out.
date_hides_backend <- function(date) {
  is_absolute_date(date) &&
    as.Date(substr(date, 1, 10)) < as.Date("2026-10-15")
}
