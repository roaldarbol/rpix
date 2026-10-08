test_that("add() builds the pixi add command", {
  root <- local_pixi_project()
  withr::local_dir(root)
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)

  command <- suppressMessages(add(c("dplyr", "tidyr"), dry_run = TRUE))
  expect_match(command, "^pixi add r-dplyr r-tidyr --manifest-path")

  command <- suppressMessages(add(
    "dplyr",
    versions = ">=1.1",
    channel = "my-channel",
    dry_run = TRUE
  ))
  expect_match(
    command,
    "^pixi add \"r-dplyr>=1.1\" --channel my-channel --manifest-path"
  )

  command <- suppressMessages(add("dplyr", versions = "1.1", dry_run = TRUE))
  expect_match(command, "^pixi add r-dplyr=1.1 ")
})

test_that("remove() builds the pixi remove command", {
  root <- local_pixi_project()
  withr::local_dir(root)
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)

  command <- suppressMessages(remove(c("dplyr", "tidyr"), dry_run = TRUE))
  expect_match(command, "^pixi remove r-dplyr r-tidyr --manifest-path")
})

test_that("search() builds the pixi search command, and falls back to base::search()", {
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  withr::local_dir(withr::local_tempdir())

  expect_equal(
    suppressMessages(search("dplyr", dry_run = TRUE)),
    "pixi search r-dplyr"
  )
  expect_equal(search(), base::search())
  expect_error(search(c("a", "b")), "single package")
})
