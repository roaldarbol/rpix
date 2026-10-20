# What `pixi update --dry-run --json` prints, cut down
change <- function(name, before, after, explicit = TRUE) {
  url <- function(version) {
    if (is.null(version)) {
      return(NULL)
    }
    list(
      conda = paste0(
        "https://conda.anaconda.org/conda-forge/osx-64/",
        name,
        "-",
        version,
        "-h123_0.conda"
      )
    )
  }
  c(
    list(name = name, before = url(before), after = url(after), type = "conda"),
    if (explicit) list(explicit = TRUE)
  )
}

preview_json <- function(
  changes = list(
    change("r-cli", "3.6.4", "3.6.6"),
    change("freetype", "2.14.3", NULL, explicit = FALSE),
    change("pango", "1.58.2", "1.58.3", explicit = FALSE)
  )
) {
  environment <- if (length(changes) > 0) {
    list(default = list(`osx-64` = changes))
  } else {
    structure(list(), names = character())
  }
  jsonlite::toJSON(
    list(version = 1, environment = environment),
    auto_unbox = TRUE,
    null = "null"
  )
}

# Records Pixi's calls, and answers a dry run with `json`
local_previewed_pixi <- function(json = preview_json(), env = parent.frame()) {
  calls <- new.env()
  calls$args <- list()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- c(calls$args, list(args))
      if ("--dry-run" %in% args) {
        list(status = 0, stdout = json)
      } else {
        invisible(list(status = 0))
      }
    },
    running_environment = function(...) NULL,
    conda_platform = function() "osx-64",
    .env = env
  )
  withr::local_envvar(PIXI_NO_INSTALL = NA, .local_envir = env)
  calls
}

test_that("pixi_upgrade() leaves R as it is, unless asked", {
  calls <- local_recorded_pixi()
  pixi_upgrade(dry_run = TRUE)
  pixi_upgrade(r = TRUE, dry_run = TRUE)
  pixi_upgrade("r-base", dry_run = TRUE)
  # Named packages leave R anyway
  pixi_upgrade("dplyr", dry_run = TRUE)
  pixi_update(dry_run = TRUE)
  expect_equal(
    calls$args,
    list(
      c("upgrade", "--exclude", "r-base"),
      "upgrade",
      c("upgrade", "r-base"),
      c("upgrade", "r-dplyr"),
      "update"
    )
  )

  calls <- local_previewed_pixi()
  expect_message(pixi_upgrade(), "Leaving R as it is")
})

test_that("pixi_update() shows what would change and asks first", {
  calls <- local_previewed_pixi()
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_yes_no = function(question) FALSE
  )
  expect_snapshot(pixi_update())
  expect_equal(calls$args, list(c("update", "--dry-run", "--json")))

  calls$args <- list()
  local_mocked_bindings(ask_yes_no = function(question) TRUE)
  suppressMessages(pixi_update())
  expect_equal(
    calls$args,
    list(
      c("update", "--dry-run", "--json"),
      "update",
      c("install", "--environment", "default")
    )
  )
})

test_that("pixi_update() says when there's nothing to update", {
  calls <- local_previewed_pixi(preview_json(list()))
  local_mocked_bindings(is_interactive = function() TRUE)
  expect_message(pixi_update(), "Nothing to update")
  expect_length(calls$args, 1)
})

test_that("pixi_upgrade(r = TRUE) says what upgrading R means", {
  calls <- local_previewed_pixi(preview_json(list(
    change("r-base", "4.4.3", "4.5.3"),
    change("r-cli", "3.6.6", "3.6.6")
  )))
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_yes_no = function(question) FALSE
  )
  expect_snapshot(pixi_upgrade(r = TRUE))

  calls <- local_previewed_pixi()
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_yes_no = function(question) FALSE
  )
  expect_message(pixi_upgrade(r = TRUE), "R stays as it is")
})

test_that("in the running R's environment, it says to restart, and leaves Windows' to later", {
  calls <- local_previewed_pixi()
  local_mocked_bindings(
    running_environment = function(...) "default",
    is_windows = function() FALSE,
    rstudio_api = function(name) NULL
  )
  expect_message(pixi_update(), "Restart R")
  expect_equal(calls$args[[2]], c("install", "--environment", "default"))

  calls$args <- list()
  local_mocked_bindings(is_windows = function() TRUE)
  expect_snapshot(pixi_upgrade())
  expect_equal(
    calls$args,
    list(c("upgrade", "--exclude", "r-base", "--no-install"))
  )

  # Another environment than this R's is installed as usual
  calls$args <- list()
  suppressMessages(pixi_update(environment = "r44"))
  expect_equal(calls$args[[2]], c("install", "--environment", "r44"))
})

test_that("in RStudio, it offers to restart R", {
  restarted <- FALSE
  local_mocked_bindings(
    rstudio_api = function(name) function() restarted <<- TRUE,
    offer = function(question, ...) TRUE
  )
  expect_true(offer_restart())
  expect_true(restarted)
})

test_that("change_rows() reads Pixi's changes", {
  rows <- change_rows(
    jsonlite::fromJSON(
      preview_json(list(
        change("r-base", "4.4.3", "4.5.3"),
        change("bioconductor-limma", "3.62.0", "3.64.1"),
        change("freetype", "2.14.3", NULL, explicit = FALSE),
        change("libnew", NULL, "1.0", explicit = FALSE)
      )),
      simplifyVector = FALSE
    )$environment$default$`osx-64`
  )
  expect_equal(rows$label, c("R", "limma", "freetype", "libnew"))
  expect_equal(rows$before, c("4.4.3", "3.62.0", "2.14.3", "none"))
  expect_equal(rows$after, c("4.5.3", "3.64.1", "none", "1.0"))
  expect_equal(rows$explicit, c(TRUE, TRUE, FALSE, FALSE))
})

test_that("change_rows() reads PyPI's versions, and copes without one", {
  rows <- change_rows(list(
    list(
      name = "pydytuesday",
      before = list(version = "0.1.1"),
      after = list(version = "0.1.2")
    ),
    list(name = "odd", before = list(conda = "odd.conda"), after = NULL)
  ))
  expect_equal(rows$before, c("0.1.1", "?"))
  expect_equal(rows$after, c("0.1.2", "none"))
})

test_that("it goes ahead when Pixi can't show the changes", {
  calls <- local_previewed_pixi(json = "not JSON")
  local_mocked_bindings(is_interactive = function() TRUE)
  suppressMessages(pixi_update())
  expect_equal(calls$args[[2]], "update")
})

test_that("conda_platform() names this computer's platform", {
  expect_equal(conda_platform("Windows", "x86_64"), "win-64")
  expect_equal(conda_platform("Darwin", "aarch64"), "osx-arm64")
  expect_equal(conda_platform("Darwin", "x86_64"), "osx-64")
  expect_equal(conda_platform("Linux", "aarch64"), "linux-aarch64")
  expect_equal(conda_platform("Linux", "x86_64"), "linux-64")
  expect_true(
    conda_platform() %in%
      c("win-64", "osx-arm64", "osx-64", "linux-aarch64", "linux-64")
  )
})

test_that("running_environment() finds the project's environment this R runs in", {
  root <- withr::local_tempdir()
  writeLines("[workspace]", file.path(root, "pixi.toml"))
  local_mocked_bindings(
    r_home = function() file.path(root, ".pixi", "envs", "r44", "lib", "R")
  )
  expect_equal(running_environment(root), "r44")
  local_mocked_bindings(r_home = function() "/usr/lib/R")
  expect_null(running_environment(root))
})

test_that("the preview shows another platform when this one isn't there", {
  calls <- local_previewed_pixi()
  local_mocked_bindings(
    conda_platform = function() "linux-64",
    is_interactive = function() TRUE,
    ask_yes_no = function(question) FALSE
  )
  expect_message(pixi_update(), "osx-64")
})
