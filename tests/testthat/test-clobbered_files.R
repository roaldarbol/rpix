# A project with an environment whose conda-meta records list files, and the
# files themselves
local_clobbered_project <- function(env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  prefix <- file.path(root, ".pixi", "envs", "default")
  dir.create(file.path(prefix, "conda-meta"), recursive = TRUE)
  dir.create(file.path(prefix, "Library", "bin"), recursive = TRUE)
  dir.create(file.path(prefix, "share", "doc"), recursive = TRUE)
  # On disk: Strawberry Perl's copy of the runtime, and some licence. Written
  # as bytes, so their checksums are the same on Windows.
  write_bytes <- function(text, file) writeBin(charToRaw(text), file)
  write_bytes(
    "perl's runtime",
    file.path(prefix, "Library", "bin", "libstdc++-6.dll")
  )
  write_bytes("licence", file.path(prefix, "share", "doc", "LICENSE"))
  hash <- function(text) cli::hash_sha256(text)
  record <- function(name, build, paths) {
    jsonlite::write_json(
      list(
        name = name,
        build = build,
        paths_data = list(
          paths = lapply(names(paths), function(p) {
            list(`_path` = p, sha256 = paths[[p]])
          })
        )
      ),
      file.path(prefix, "conda-meta", paste0(name, ".json")),
      auto_unbox = TRUE
    )
  }
  record(
    "perl",
    "5.32.1.1_strawberry",
    list(
      "Library/bin/libstdc++-6.dll" = hash("perl's runtime"),
      "share/doc/LICENSE" = hash("licence")
    )
  )
  record(
    "libstdcxx",
    "h1_0",
    list(
      "Library/bin/libstdc++-6.dll" = hash("conda-forge's runtime"),
      "share/doc/LICENSE" = hash("other licence")
    )
  )
  record("r-cli", "r45_0", list("lib/R/library/cli/libs/cli.dll" = hash("x")))
  # A record without files, e.g. a metapackage
  jsonlite::write_json(
    list(name = "r-recommended", build = "0"),
    file.path(prefix, "conda-meta", "r-recommended.json"),
    auto_unbox = TRUE
  )
  root
}

test_that("clobbered_files() finds libraries two packages install, and whose copy is there", {
  root <- local_clobbered_project()
  clobbered <- clobbered_files(root)
  # Not the licence, which overlaps harmlessly
  expect_equal(clobbered$path, "Library/bin/libstdc++-6.dll")
  expect_equal(clobbered$winner, "perl")
  expect_equal(clobbered$losers, "libstdcxx")
  expect_equal(clobbered$environment, "default")
})

test_that("clobbered_files() lists files rattler set aside, and copies it can't place", {
  root <- local_clobbered_project()
  prefix <- file.path(root, ".pixi", "envs", "default")
  dir.create(file.path(prefix, "bin"))
  file.create(file.path(prefix, "bin", "tool__clobber-from-other"))
  unlink(file.path(prefix, "Library", "bin", "libstdc++-6.dll"))
  clobbered <- clobbered_files(root)
  expect_setequal(clobbered$path, c("Library/bin/libstdc++-6.dll", "bin/tool"))
  expect_true(all(is.na(clobbered$winner)))
  expect_equal(clobbered$losers[clobbered$path == "bin/tool"], "other")
})

test_that("clobbered_files() is empty without environments, or files in common", {
  root <- withr::local_tempdir()
  expect_equal(nrow(clobbered_files(root)), 0)
  dir.create(
    file.path(root, ".pixi", "envs", "default", "conda-meta"),
    recursive = TRUE
  )
  expect_equal(nrow(clobbered_files(root)), 0)
})

test_that("pixi_sitrep() reports them, and Strawberry Perl's runtime", {
  root <- local_clobbered_project()
  expect_snapshot(
    show_clobbered(clobbered_files(root)),
    transform = function(x) {
      gsub(root, "<root>", x, fixed = TRUE)
    }
  )
  # Only the summary for other packages
  clobbered <- clobbered_files(root)
  clobbered$winner <- "something"
  expect_no_message(
    show_clobbered(clobbered),
    message = "Strawberry"
  )
})

test_that("show_clobbered() shows ten files, and how many more", {
  many <- clobbered_frame(
    environment = "default",
    path = paste0("bin/tool", 1:12),
    winner = "a",
    build = "0",
    losers = "b"
  )
  expect_snapshot(show_clobbered(many))
})
