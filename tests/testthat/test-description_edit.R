description_lines <- c(
  "Package: demo",
  "Title: A Demo",
  "Version: 0.1",
  "Authors@R:",
  "    person(\"A\", \"B\", role = c(\"aut\", \"cre\"))",
  "Imports:",
  "    cli,",
  "    rlang (>= 1.0)",
  "Suggests: testthat",
  "Config/testthat/edition: 3"
)

local_description_project <- function(env = parent.frame()) {
  root <- local_pixi_project(env = env)
  withr::local_dir(root, .local_envir = env)
  withr::local_envvar(
    PIXI_WORKSPACE_ROOT = NA,
    PIXI_PROJECT_ROOT = NA,
    .local_envir = env
  )
  writeLines(description_lines, file.path(root, "DESCRIPTION"))
  root
}

# A field's value, as read.dcf() gives it
field <- function(root, name) {
  read.dcf(file.path(root, "DESCRIPTION"))[[1, name]]
}

has_field <- function(root, name) {
  name %in% colnames(read.dcf(file.path(root, "DESCRIPTION")))
}

entries_for <- function(
  root,
  names,
  type = "Imports",
  minimum = NA_character_,
  remotes = character()
) {
  list(
    file = file.path(root, "DESCRIPTION"),
    type = type,
    names = names,
    minimum = rep_len(minimum, length(names)),
    remotes = remotes
  )
}

test_that("add_to_description() adds to a field, and leaves the rest alone", {
  root <- local_description_project()
  suppressMessages(add_to_description(entries_for(root, c("dplyr", "cli"))))
  lines <- readLines(file.path(root, "DESCRIPTION"))
  expect_equal(
    lines,
    c(
      description_lines[1:5],
      "Imports:",
      "    cli,",
      "    rlang (>= 1.0),",
      "    dplyr",
      description_lines[9:10]
    )
  )
  expect_equal(field(root, "Imports"), "cli,\nrlang (>= 1.0),\ndplyr")
})

test_that("add_to_description() updates a version, and adds new fields", {
  root <- local_description_project()
  suppressMessages(add_to_description(
    entries_for(root, "rlang", minimum = "1.1.0")
  ))
  suppressMessages(add_to_description(
    entries_for(root, "Rcpp", type = "LinkingTo")
  ))
  suppressMessages(add_to_description(
    entries_for(root, "withr", type = "Suggests")
  ))
  expect_match(field(root, "Imports"), "rlang (>= 1.1.0)", fixed = TRUE)
  expect_equal(field(root, "LinkingTo"), "Rcpp")
  expect_equal(field(root, "Suggests"), "testthat,\nwithr")
  expect_equal(field(root, "Config/testthat/edition"), "3")
})

test_that("add_to_description() adds GitHub repositories to Remotes once", {
  root <- local_description_project()
  entries <- entries_for(root, "emo", remotes = "hadley/emo")
  suppressMessages(add_to_description(entries))
  suppressMessages(add_to_description(entries))
  expect_equal(field(root, "Remotes"), "hadley/emo")
})

test_that("remove_from_description() removes entries, and an empty field", {
  root <- local_description_project()
  suppressMessages(remove_from_description(entries_for(root, "cli")))
  expect_equal(field(root, "Imports"), "rlang (>= 1.0)")
  suppressMessages(remove_from_description(
    entries_for(root, "testthat", type = "Suggests")
  ))
  expect_false(has_field(root, "Suggests"))
  expect_snapshot(remove_from_description(entries_for(root, "praise")))
})

test_that("remove_from_description() removes a package's Remotes entry", {
  root <- local_description_project()
  entries <- entries_for(root, "emo", remotes = "hadley/emo")
  suppressMessages(add_to_description(entries))
  entries$remotes <- "hadley/emo@main"
  suppressMessages(remove_from_description(entries))
  expect_false(has_field(root, "Remotes"))
})

test_that("description_entries() takes names, minimum versions and remotes", {
  root <- local_description_project()
  local_mocked_bindings(
    parse_github = function(package, ...) list(package = "emo")
  )
  entries <- description_entries(
    c(
      "dplyr>=1.1",
      "bioc::limma",
      "praise",
      "github::hadley/emo",
      "github::cran/fortunes"
    ),
    c(NA, NA, "==1.0.0", NA, NA),
    "Imports",
    path = root
  )
  expect_equal(entries$names, c("dplyr", "limma", "praise", "emo", "emo"))
  expect_equal(entries$minimum, c("1.1", NA, NA, NA, NA))
  expect_equal(entries$remotes, "hadley/emo")
})

test_that("description_entries() checks the type, the project and the packages", {
  root <- local_description_project()
  expect_snapshot(error = TRUE, {
    description_entries("dplyr", NULL, "imports", path = root)
    description_entries("conda::gdal", NULL, "Imports", path = root)
    description_entries("pypi::pydytuesday", NULL, "Imports", path = root)
  })
  unlink(file.path(root, "DESCRIPTION"))
  expect_error(
    description_entries("dplyr", NULL, "Imports", path = root),
    "is for packages"
  )
})

test_that("pixi_add(type = ) and pixi_remove(type = ) change DESCRIPTION too", {
  root <- local_description_project()
  expect_equal(
    suppressMessages(pixi_add("dplyr>=1.1", type = "Imports", dry_run = TRUE)),
    "pixi add \"r-dplyr>=1.1\" --manifest-path pixi.toml"
  )
  # Not in a dry run
  expect_equal(readLines(file.path(root, "DESCRIPTION")), description_lines)

  calls <- local_recorded_pixi()
  local_mocked_bindings(install_changed_environment = function(...) NULL)
  suppressMessages(pixi_add("dplyr>=1.1", type = "Imports"))
  expect_match(field(root, "Imports"), "dplyr (>= 1.1)", fixed = TRUE)
  suppressMessages(pixi_remove("cli", type = "Imports"))
  expect_equal(calls$args[[length(calls$args)]][1:2], c("remove", "r-cli"))
  expect_false(grepl("cli", field(root, "Imports")))
})

test_that("pixi_add(type = ) leaves DESCRIPTION alone if Pixi fails", {
  root <- local_description_project()
  local_mocked_bindings(run_pixi = function(...) stop("Pixi failed"))
  expect_error(suppressMessages(pixi_add("dplyr", type = "Imports")))
  expect_equal(readLines(file.path(root, "DESCRIPTION")), description_lines)
})

test_that("SystemRequirements gets conda packages, after what it says already", {
  root <- local_description_project()
  entries <- description_entries(
    c("conda::gdal>=3.6", "conda::pkg-config"),
    NULL,
    "SystemRequirements",
    path = root
  )
  expect_equal(entries$names, c("gdal", "pkg-config"))
  suppressMessages(add_to_description(entries))
  expect_equal(field(root, "SystemRequirements"), "gdal (>= 3.6), pkg-config")

  # Free text that's there stays as it is
  lines <- readLines(file.path(root, "DESCRIPTION"))
  lines[grepl("^SystemRequirements:", lines)] <-
    "SystemRequirements: GNU make, and a C++17 compiler"
  writeLines(lines, file.path(root, "DESCRIPTION"))
  suppressMessages(add_to_description(
    description_entries("conda::cmake", NULL, "SystemRequirements", path = root)
  ))
  expect_equal(
    field(root, "SystemRequirements"),
    "GNU make, and a C++17 compiler,\ncmake"
  )
  # Not twice, whatever the case
  expect_snapshot(add_to_description(
    description_entries("conda::CMake", NULL, "SystemRequirements", path = root)
  ))

  suppressMessages(remove_from_description(
    description_entries("conda::cmake", NULL, "SystemRequirements", path = root)
  ))
  expect_equal(
    field(root, "SystemRequirements"),
    "GNU make, and a C++17 compiler"
  )
})

test_that("SystemRequirements takes conda packages, and the R fields R packages", {
  root <- local_description_project()
  expect_snapshot(error = TRUE, {
    description_entries("dplyr", NULL, "SystemRequirements", path = root)
    description_entries(
      "github::hadley/emo",
      NULL,
      "SystemRequirements",
      path = root
    )
  })
})

test_that("a dry run of pixi_remove(type = ) leaves DESCRIPTION alone", {
  root <- local_description_project()
  expect_snapshot(pixi_remove("cli", type = "Imports", dry_run = TRUE))
  expect_equal(readLines(file.path(root, "DESCRIPTION")), description_lines)
})
