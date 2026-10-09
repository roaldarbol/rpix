# Record pixi_auth_login()'s call to Pixi, with the secrets it asked for
local_auth <- function(
  secrets = c("s3cr3t-1", "s3cr3t-2"),
  env = parent.frame()
) {
  calls <- new.env()
  calls$asked <- character()
  answers <- secrets
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_secret = function(prompt) {
      calls$asked <- c(calls$asked, prompt)
      answer <- answers[1]
      answers <<- answers[-1]
      answer
    },
    ask_text = function(prompt) "me",
    run_pixi = function(args, ..., secrets = NULL) {
      calls$args <- args
      calls$secrets <- secrets
      invisible(list(status = 0))
    },
    .env = env
  )
  calls
}

test_that("pixi_auth_login() asks for a token, and hides it", {
  calls <- local_auth()
  expect_snapshot(pixi_auth_login("prefix.dev"))
  expect_equal(calls$asked, "Token for prefix.dev:")
  expect_equal(
    calls$args,
    c("auth", "login", "prefix.dev", "--token", "s3cr3t-1")
  )
  expect_equal(calls$secrets, "s3cr3t-1")
})

test_that("pixi_auth_login() logs in with a password, a conda token or S3 keys", {
  calls <- local_auth()
  suppressMessages(pixi_auth_login("repo.example.com", method = "password"))
  expect_equal(
    calls$args,
    c(
      "auth",
      "login",
      "repo.example.com",
      "--username",
      "me",
      "--password",
      "s3cr3t-1"
    )
  )
  expect_equal(calls$asked, "Password for me on repo.example.com:")

  calls <- local_auth()
  suppressMessages(
    pixi_auth_login("repo.example.com", method = "password", username = "you")
  )
  expect_equal(calls$args[5], "you")

  calls <- local_auth()
  suppressMessages(pixi_auth_login("anaconda.org", method = "conda-token"))
  expect_equal(calls$args[4:5], c("--conda-token", "s3cr3t-1"))

  calls <- local_auth()
  suppressMessages(pixi_auth_login("s3://bucket", method = "s3"))
  expect_equal(
    calls$args[4:7],
    c("--s3-access-key-id", "s3cr3t-1", "--s3-secret-access-key", "s3cr3t-2")
  )
  expect_equal(calls$secrets, c("s3cr3t-1", "s3cr3t-2"))
})

test_that("pixi_auth_login() needs an interactive session", {
  local_mocked_bindings(is_interactive = function() FALSE)
  expect_snapshot(pixi_auth_login("prefix.dev"), error = TRUE)
})

test_that("ask_secret() asks with askpass, and needs something entered", {
  local_mocked_bindings(
    askpass = function(prompt) "s3cr3t",
    .package = "askpass"
  )
  expect_equal(ask_secret("Token:"), "s3cr3t")
  local_mocked_bindings(askpass = function(prompt) NULL, .package = "askpass")
  expect_error(ask_secret("Token:"), "Cancelled")
})

test_that("ask_text() and is_interactive() ask R", {
  expect_equal(ask_text("Username: "), "")
  expect_equal(is_interactive(), interactive())
})

test_that("parse_auth_status() reads pixi auth status", {
  text <- paste(
    c(
      "Stored authentication entries:",
      "*.prefix.dev",
      "  - Source: file (/home/me/.rattler/credentials.json)",
      "  - Method: BearerToken",
      "  - Token validity: unknown (no expiry metadata)",
      "",
      "*.repo.example.com",
      "  - Source: keyring",
      "  - Method: BasicHTTP",
      "  - Username: me"
    ),
    collapse = "\n"
  )
  status <- parse_auth_status(text)
  expect_equal(status$host, c("prefix.dev", "repo.example.com"))
  expect_equal(status$method, c("BearerToken", "BasicHTTP"))
  expect_equal(status$username, c(NA, "me"))
  expect_equal(
    status$source,
    c("file (/home/me/.rattler/credentials.json)", "keyring")
  )

  empty <- parse_auth_status("No stored authentication entries found.\n")
  expect_equal(nrow(empty), 0)
  expect_named(empty, c("host", "method", "username", "source"))
})

test_that("logging in and out works with Pixi, without showing the token", {
  skip_if_no_pixi()
  # A credentials file of its own, rather than the keychain
  withr::local_envvar(
    RATTLER_AUTH_FILE = withr::local_tempfile(fileext = ".json")
  )
  local_mocked_bindings(
    is_interactive = function() TRUE,
    ask_secret = function(prompt) "not-a-real-token-123"
  )

  output <- capture.output(
    messages <- capture.output(
      pixi_auth_login("example.invalid"),
      type = "message"
    )
  )
  shown <- paste(c(output, messages), collapse = "\n")
  expect_match(shown, "<hidden>")
  expect_no_match(shown, "not-a-real-token-123")

  status <- pixi_auth_status()
  expect_equal(status$host, "example.invalid")
  expect_equal(status$method, "BearerToken")

  suppressMessages(capture.output(pixi_auth_logout("example.invalid")))
  expect_equal(nrow(pixi_auth_status()), 0)
})
