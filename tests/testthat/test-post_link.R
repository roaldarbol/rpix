# Pixi's warning when it skips install scripts, as Pixi 0.81 prints it
skipped_output <- paste(
  "\033[33m WARN\033[0m Skipped running the post-link scripts because `run-post-link-scripts` = `false`",
  "\t- bin/.bioconductor-org.hs.eg.db-pre-unlink.sh",
  "",
  "To enable them, run:",
  "\tpixi config set --local run-post-link-scripts insecure",
  "✔ Added bioconda::bioconductor-org.hs.eg.db",
  sep = "\n"
)

local_post_link <- function(answer = NULL, env = parent.frame()) {
  calls <- local_recorded_pixi(env = env)
  local_mocked_bindings(
    is_interactive = function() !is.null(answer),
    ask_yes_no = function(question) {
      calls$asked <- c(calls$asked, question)
      answer
    },
    .env = env
  )
  calls
}

test_that("skipped_post_link() reads which packages Pixi skipped", {
  expect_null(skipped_post_link("✔ Added r-dplyr"))
  expect_equal(skipped_post_link(skipped_output), "bioconductor-org.hs.eg.db")

  windows <- paste(
    "WARN Skipped running the post-link scripts because ...",
    "\t- Scripts\\.bioconductor-go.db-post-link.bat",
    "\t- Scripts\\.bioconductor-go.db-pre-unlink.bat",
    "WARN Skipped running the post-link scripts because ...",
    "\t- bin/.r-x_y+z-pre-link.sh",
    sep = "\n"
  )
  expect_equal(
    skipped_post_link(windows),
    c("bioconductor-go.db", "r-x_y+z")
  )

  expect_equal(
    skipped_post_link("WARN Skipped running the post-link scripts because"),
    character()
  )
})

test_that("check_post_link() does nothing when Pixi ran them, or there were none", {
  calls <- local_post_link(answer = TRUE)
  expect_false(check_post_link(list(status = 0)))
  expect_false(check_post_link(list(stdout = "", stderr = "✔ Added")))
  expect_length(calls$args, 0)
  expect_null(calls$asked)
})

test_that("check_post_link() offers to allow them, and installs the packages again", {
  calls <- local_post_link(answer = TRUE)
  expect_snapshot(
    out <- check_post_link(list(stderr = skipped_output), environment = "test")
  )
  expect_true(out)
  expect_equal(
    calls$asked,
    "Allow install scripts in this project, and install it again?"
  )
  expect_equal(
    calls$args,
    list(
      c("config", "set", "--local", "run-post-link-scripts", "insecure"),
      c(
        "reinstall",
        "bioconductor-org.hs.eg.db",
        "--environment",
        "test"
      )
    )
  )
})

test_that("check_post_link() says how to run them when it can't ask, or the answer is no", {
  calls <- local_post_link()
  expect_snapshot(check_post_link(list(stderr = skipped_output)))
  expect_warning(
    check_post_link(list(stderr = skipped_output)),
    class = "rpix_warning_post_link"
  )

  calls <- local_post_link(answer = FALSE)
  expect_warning(
    expect_message(check_post_link(list(stderr = skipped_output))),
    class = "rpix_warning_post_link"
  )
  expect_length(calls$args, 0)

  # When Pixi doesn't say which, it's the whole environment
  local_post_link()
  expect_snapshot(
    check_post_link(list(stdout = "WARN Skipped running the post-link scripts"))
  )
})

test_that("pixi_add() and pixi_install() check for skipped scripts", {
  local_mocked_bindings(
    run_pixi = function(...) {
      invisible(list(status = 0, stderr = skipped_output))
    },
    is_interactive = function() FALSE,
    project_channels = function(...) "bioconda"
  )
  expect_warning(
    pixi_add("bioc::org.Hs.eg.db"),
    class = "rpix_warning_post_link"
  )
  expect_warning(pixi_install(), class = "rpix_warning_post_link")
  expect_warning(pixi_update(), class = "rpix_warning_post_link")
  expect_warning(pixi_upgrade(), class = "rpix_warning_post_link")
})
