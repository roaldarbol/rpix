# Run the runner in this R instead of an environment's R
local_pixi_r_here <- function(env = parent.frame()) {
  calls <- new.env()
  local_mocked_bindings(
    run_pixi = function(args, ...) {
      calls$args <- args
      calls$dots <- list(...)
      processx::run(
        file.path(R.home("bin"), "Rscript"),
        utils::tail(args, 4)
      )
    },
    .env = env
  )
  calls
}

test_that("pixi_r() runs a function in an environment and returns its result", {
  calls <- local_pixi_r_here()

  expect_equal(pixi_r(function(x, y) x + y, list(1, y = 2)), 3)
  expect_equal(
    calls$args[1:4],
    c("run", "Rscript", "--no-init-file", calls$args[4])
  )
  expect_match(calls$args[4], "runner.R$")
  expect_false(calls$dots$announce)
  expect_true(calls$dots$echo)

  pixi_r(function() NULL, environment = "r44", show = FALSE)
  expect_equal(calls$args[1:3], c("run", "--environment", "r44"))
  expect_false(calls$dots$echo)
})

test_that("pixi_r() doesn't take the caller's variables along", {
  local_pixi_r_here()
  x <- 1
  expect_error(pixi_r(function() x), class = "rpix_error_pixi_r")
  expect_equal(
    pixi_r(utils::packageVersion, list("base")),
    packageVersion("base")
  )
})

test_that("pixi_r() turns errors into R errors", {
  local_pixi_r_here()
  expect_snapshot(
    pixi_r(function() stop("boom"), environment = "r44"),
    error = TRUE
  )
})

test_that("pixi_r() checks its arguments", {
  expect_error(pixi_r("R.home"), "must be a function")
  expect_error(pixi_r(function(x) x, 1), "must be a list")
})

test_that("pixi_r() runs in the project's R", {
  skip_on_cran()
  skip_if_no_pixi()
  skip_if(is.null(pixi_r_location(r_home())), "not in a Pixi environment")

  home <- pixi_r(R.home, show = FALSE)
  expect_true(same_path(home, R.home()))
})
