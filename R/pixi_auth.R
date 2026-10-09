#' Log in to private channels
#'
#' @description
#' Pixi needs credentials to install packages from private conda channels,
#' e.g. on prefix.dev, anaconda.org, Artifactory or S3. These functions run
#' `pixi auth`, which stores credentials in your system's keychain, or in
#' `~/.rattler/credentials.json`, for every Pixi project to use.
#'
#' * `pixi_auth_login()` logs in to a host. It asks for the token or
#'   password with hidden input, so it isn't shown, or saved in your R
#'   history. It needs the askpass package: add it with
#'   `pixi_add("askpass")`.
#' * `pixi_auth_logout()` removes the credentials for a host.
#' * `pixi_auth_status()` lists the hosts Pixi has credentials for, without
#'   the secrets.
#'
#' rpix never shows or saves a secret itself. Pixi takes it as a command-line
#' argument, so while Pixi runs, other users on the same computer could see it
#' in the list of running processes.
#'
#' For continuous integration, use the `auth-*` inputs of the setup-pixi
#' action instead. For more information, see
#' <https://pixi.prefix.dev/latest/deployment/authentication/>.
#'
#' @param host The host, such as `"prefix.dev"` or `"repo.example.com"`.
#' @param method How to log in:
#'   * `"token"`: a token, e.g. for prefix.dev.
#'   * `"password"`: a username and password (basic HTTP authentication), e.g.
#'     for Artifactory or Nexus.
#'   * `"conda-token"`: a token for anaconda.org or quetz.
#'   * `"s3"`: an access key ID and secret access key, for channels on S3.
#' @param username For `method = "password"`, the username. Asked for if not
#'   given.
#' @returns
#' * `pixi_auth_login()` and `pixi_auth_logout()`: the result of the Pixi
#'   call, invisibly, with any secret hidden.
#' * `pixi_auth_status()`: a data frame with a row per host, and the columns
#'   `host`, `method`, `username` and `source`.
#' @export
#' @examples
#' \dontrun{
#' pixi_auth_login("prefix.dev")
#' pixi_auth_login("repo.example.com", method = "password", username = "me")
#' pixi_auth_status()
#' pixi_auth_logout("prefix.dev")
#' }
pixi_auth_login <- function(
  host,
  method = c("token", "password", "conda-token", "s3"),
  username = NULL
) {
  method <- match.arg(method)
  if (!is_interactive()) {
    cli::cli_abort(
      c(
        "{.fn pixi_auth_login} asks for a secret, so it needs an interactive R session.",
        "i" = "In continuous integration, use the {.code auth-*} inputs of the setup-pixi action."
      )
    )
  }

  secrets <- switch(
    method,
    token = c(token = ask_secret(paste0("Token for ", host, ":"))),
    password = {
      username <- username %||% ask_text("Username: ")
      c(
        password = ask_secret(paste0(
          "Password for ",
          username,
          " on ",
          host,
          ":"
        ))
      )
    },
    `conda-token` = c(
      `conda-token` = ask_secret(paste0("Token for ", host, ":"))
    ),
    s3 = c(
      `s3-access-key-id` = ask_secret(paste0(
        "S3 access key ID for ",
        host,
        ":"
      )),
      `s3-secret-access-key` = ask_secret(
        paste0("S3 secret access key for ", host, ":")
      )
    )
  )
  args <- c(
    "auth",
    "login",
    host,
    if (method == "password") c("--username", username),
    as.vector(rbind(paste0("--", names(secrets)), unname(secrets)))
  )
  result <- run_pixi(
    args,
    project = "none",
    echo = TRUE,
    secrets = unname(secrets)
  )
  cli::cli_alert_success("Logged in to {.val {host}}.")
  invisible(result)
}

#' @rdname pixi_auth_login
#' @export
pixi_auth_logout <- function(host) {
  invisible(run_pixi(c("auth", "logout", host), project = "none", echo = TRUE))
}

#' @rdname pixi_auth_login
#' @export
pixi_auth_status <- function() {
  result <- run_pixi(c("auth", "status"), project = "none")
  parse_auth_status(result$stdout)
}

# pixi auth status's text as a data frame. Each entry is a host, followed by
# "  - Key: value" lines.
parse_auth_status <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  hosts <- grep("^[^[:space:]-].*[^:]$", lines)
  hosts <- hosts[!grepl("^(Stored|No stored)", lines[hosts])]
  entries <- lapply(seq_along(hosts), function(i) {
    end <- c(hosts[-1] - 1, length(lines))[i]
    fields <- lines[seq(hosts[i], end)][-1]
    fields <- fields[grepl("^\\s+- [^:]+: ", fields)]
    keys <- tolower(sub("^\\s+- ([^:]+): .*$", "\\1", fields))
    values <- sub("^\\s+- [^:]+: ", "", fields)
    value <- function(key) {
      if (key %in% keys) values[match(key, keys)] else NA_character_
    }
    data.frame(
      host = sub("^\\*\\.", "", lines[hosts[i]]),
      method = value("method"),
      username = value("username"),
      source = value("source"),
      stringsAsFactors = FALSE
    )
  })
  if (length(entries) == 0) {
    return(data.frame(
      host = character(),
      method = character(),
      username = character(),
      source = character()
    ))
  }
  do.call(rbind, entries)
}

# Ask for a secret without showing it. askpass shows a dialog on macOS and
# Windows, and hides typing in a terminal.
ask_secret <- function(prompt) {
  if (!has_askpass()) {
    cli::cli_abort(
      c(
        "Asking for a secret without showing it needs the {.pkg askpass} package.",
        "i" = "Add it with {.code pixi_add(\"askpass\")}."
      ),
      call = NULL
    )
  }
  secret <- askpass::askpass(prompt)
  if (is.null(secret) || !nzchar(secret)) {
    cli::cli_abort("Cancelled: nothing was entered.", call = NULL)
  }
  secret
}

ask_text <- function(prompt) {
  readline(prompt)
}

has_askpass <- function() {
  requireNamespace("askpass", quietly = TRUE)
}

is_interactive <- function() {
  interactive()
}
