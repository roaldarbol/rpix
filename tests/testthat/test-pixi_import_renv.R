# A project with the fixture lock file and renv's .Rprofile line, with
# pixi_import_renv()'s lookups and additions mocked. `answer` is the answer
# to whether to build packages from source; NULL is a session that can't ask.
local_renv_project <- function(
  dependencies = character(),
  answer = NULL,
  env = parent.frame()
) {
  dir <- withr::local_tempdir(.local_envir = env)
  file.copy(test_path("fixtures", "renv.lock"), dir)
  writeLines(
    c("source(\"renv/activate.R\")", "options(digits = 4)"),
    file.path(dir, ".Rprofile")
  )
  calls <- new.env()
  calls$add <- list()
  calls$searched <- character()
  calls$asked <- character()
  local_mocked_bindings(
    require_project = function(path) dir,
    project_dependencies = function(root) dependencies,
    find_r_packages = function(packages) {
      found <- c(
        cli = "cran::cli",
        dplyr = "cran::dplyr",
        Matrix = "cran::Matrix",
        DESeq2 = "bioc::DESeq2",
        notonconda = NA,
        unipkg = NA,
        biocmissing = NA
      )
      found[packages]
    },
    on_channel = function(name, channel) {
      calls$searched <- c(calls$searched, paste(channel, name))
      name != "r-dplyr==1.1.4"
    },
    pixi_add = function(packages, path, dry_run) {
      calls$add <- c(calls$add, list(packages))
    },
    is_interactive = function() !is.null(answer),
    ask_yes_no = function(question) {
      calls$asked <- c(calls$asked, question)
      answer
    },
    .env = env
  )
  calls$dir <- dir
  calls
}

mypkg <- "github::me/mypkg@0123456789abcdef0123456789abcdef01234567"
ghdep <- "github::me/ghdep@fedcba9876543210fedcba9876543210fedcba98"

test_that("pixi_import_renv() adds the packages the project uses, and turns renv off", {
  calls <- local_renv_project()

  expect_snapshot(result <- pixi_import_renv())
  # cli and Matrix are only there for dplyr and DESeq2. ghdep is there for
  # mypkg, but conda-forge doesn't have it.
  expect_equal(
    calls$add,
    list(c(
      "r-base>=4.4",
      "cran::dplyr>=1.1.4",
      "bioc::DESeq2>=1.46.0",
      mypkg,
      ghdep
    ))
  )
  expect_equal(result$from_source, c("mypkg", "ghdep"))
  expect_equal(result$not_from_repository, c("subpkg", "labpkg"))
  expect_equal(result$missing, c("unipkg", "biocmissing", "notonconda"))
  expect_equal(
    readLines(file.path(calls$dir, ".Rprofile")),
    "options(digits = 4)"
  )
})

test_that("pixi_import_renv() can add every package, at exact versions", {
  calls <- local_renv_project()

  suppressMessages(pixi_import_renv(versions = "exact", all = TRUE))
  expect_equal(
    calls$add[[1]],
    c(
      "r-base=4.4",
      "cran::cli==3.6.3",
      # Not on conda-forge at that version
      "cran::dplyr>=1.1.4",
      "cran::Matrix==1.7_1",
      "bioc::DESeq2==1.46.0",
      mypkg,
      ghdep
    )
  )
  expect_true("bioconda bioconductor-deseq2==1.46.0" %in% calls$searched)
})

test_that("pixi_import_renv() offers to build CRAN packages that aren't on conda-forge", {
  calls <- local_renv_project(answer = TRUE)

  expect_snapshot(result <- pixi_import_renv(versions = "exact"))
  expect_equal(calls$asked, "Would you like to build it from source?")
  # At the lock file's version, which CRAN's GitHub mirror has a tag for
  expect_true("github::cran/notonconda@2.0-1" %in% calls$add[[1]])
  expect_equal(result$from_source, c("notonconda", "mypkg", "ghdep"))
  expect_equal(result$missing, c("unipkg", "biocmissing"))

  # Without exact versions, the newest
  calls <- local_renv_project(answer = TRUE)
  suppressMessages(pixi_import_renv())
  expect_true("github::cran/notonconda" %in% calls$add[[1]])
})

test_that("pixi_import_renv() says how to build them if the answer is no", {
  calls <- local_renv_project(answer = FALSE)

  expect_snapshot(result <- pixi_import_renv(deactivate = FALSE))
  expect_false(any(grepl("github::cran", calls$add[[1]])))
  expect_equal(result$from_source, c("mypkg", "ghdep"))
  expect_equal(result$missing, c("unipkg", "biocmissing", "notonconda"))
})

test_that("pixi_import_renv() uses the newest R with packages, if the lock file's has none", {
  calls <- local_renv_project()
  lockfile <- file.path(calls$dir, "renv.lock")
  writeLines(
    sub('"4.4.2"', '"4.6.1"', readLines(lockfile), fixed = TRUE),
    lockfile
  )
  # Pixi's error for R 4.6 when conda-forge had no R packages for it
  stderr <- paste(
    readLines(
      test_path("fixtures", "pixi-r-version-new-r.txt"),
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
  pixi <- structure(
    class = c("rpix_error_pixi", "error", "condition"),
    list(message = "pixi failed", call = NULL, stderr = stderr)
  )
  local_mocked_bindings(
    pixi_add = function(packages, path, dry_run) {
      calls$add <- c(calls$add, list(packages))
      if (packages[1] != "r-base") {
        cli::cli_abort(
          "Not built",
          class = "rpix_error_r_version",
          parent = pixi
        )
      }
    }
  )

  expect_snapshot(result <- pixi_import_renv(deactivate = FALSE))
  expect_equal(calls$add[[1]][1], "r-base>=4.6")
  expect_equal(calls$add[[2]], c("r-base", calls$add[[1]][-1]))
  expect_equal(result$packages, calls$add[[2]])

  # An R that has packages stays, and so does the error
  writeLines(
    sub('"4.6.1"', '"4.4.2"', readLines(lockfile), fixed = TRUE),
    lockfile
  )
  calls$add <- list()
  expect_error(
    suppressMessages(pixi_import_renv(deactivate = FALSE)),
    class = "rpix_error_r_version"
  )
  expect_length(calls$add, 1)
})

test_that("pixi_import_renv() can leave versions, R and renv alone", {
  calls <- local_renv_project(dependencies = "r-base")

  expect_snapshot(
    pixi_import_renv(versions = "none", deactivate = FALSE, dry_run = TRUE)
  )
  # The branch renv recorded, or the default one
  expect_equal(
    calls$add,
    list(c(
      "cran::dplyr",
      "bioc::DESeq2",
      "github::me/mypkg@main",
      "github::me/ghdep"
    ))
  )
  expect_length(readLines(file.path(calls$dir, ".Rprofile")), 2)

  # A dry run says what it would do to .Rprofile
  expect_snapshot(pixi_import_renv(dry_run = TRUE))
  expect_length(readLines(file.path(calls$dir, ".Rprofile")), 2)
})

test_that("pixi_import_renv() needs a lock file", {
  calls <- local_renv_project()
  expect_error(
    pixi_import_renv(file.path(calls$dir, "nope.lock")),
    "no renv lock file"
  )
})

test_that("lock_spec() writes the version as asked", {
  local_mocked_bindings(on_channel = function(name, channel) TRUE)
  expect_equal(lock_spec("cran::cli", "3.6.3", "none"), "cran::cli")
  expect_equal(lock_spec("cran::cli", NULL, "exact"), "cran::cli")
  expect_equal(
    lock_spec("cran::Matrix", "1.7-1", "minimum"),
    "cran::Matrix>=1.7_1"
  )
  expect_equal(
    lock_spec("cran::Matrix", "1.7-1", "exact"),
    "cran::Matrix==1.7_1"
  )
})

test_that("remove_renv_activation() leaves .Rprofile files without renv alone", {
  file <- withr::local_tempfile()
  expect_false(remove_renv_activation(file))
  writeLines("options(digits = 4)", file)
  expect_false(remove_renv_activation(file))
  expect_equal(readLines(file), "options(digits = 4)")
})

test_that("lock_source() says where a package in renv.lock is from", {
  github <- list(
    Source = "GitHub",
    RemoteType = "github",
    RemoteUsername = "me",
    RemoteRepo = "pkg"
  )
  expect_equal(lock_source(github), "github")
  expect_equal(lock_source(list(Source = "Bioconductor")), "repository")
  expect_equal(lock_source(list()), "other")
  # Installed with pak, which can leave Source out
  expect_equal(lock_source(github[-1]), "github")
  expect_equal(lock_source(c(github, RemoteSubdir = "pkg")), "subfolder")
  expect_equal(lock_source(c(github, RemoteSubdir = "")), "github")
  # GitHub Enterprise
  expect_equal(
    lock_source(c(github, RemoteHost = "github.example.com/api/v3")),
    "other"
  )
  expect_equal(lock_source(github[-3]), "other")
})

test_that("lock_github() falls back to the branch without a commit", {
  entry <- list(RemoteUsername = "me", RemoteRepo = "pkg", RemoteRef = "dev")
  expect_equal(lock_github(entry, "minimum"), "github::me/pkg@dev")
  expect_equal(lock_github(entry[1:2], "exact"), "github::me/pkg")
})

test_that("from_cran() knows CRAN and its mirrors", {
  repositories <- c(
    CRAN = "https://cloud.r-project.org",
    posit = "https://packagemanager.posit.co/cran/latest",
    mirror = "https://cran.rstudio.com",
    universe = "https://ropensci.r-universe.dev"
  )
  from <- function(repository) {
    from_cran(
      list(Source = "Repository", Repository = repository),
      repositories
    )
  }
  expect_true(from("CRAN"))
  expect_true(from("P3M"))
  expect_true(from("posit"))
  expect_true(from("mirror"))
  expect_true(from("https://cloud.r-project.org"))
  expect_false(from("universe"))
  expect_false(from("https://example.com/drat"))
  expect_true(from_cran(list(Source = "Repository"), repositories))
  expect_false(from_cran(list(Source = "Bioconductor"), repositories))
})
