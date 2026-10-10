#' Install Pixi
#'
#' @description
#' Install Pixi from R, with Pixi's official installer, so you don't need a
#' terminal. It installs Pixi into `~/.pixi/bin` (or `$PIXI_HOME/bin`), where
#' rpix finds it straight away. When an rpix function can't find Pixi, it
#' offers to run `install_pixi()`.
#'
#' By default, the installer also adds Pixi to your shell's `PATH`, so `pixi`
#' works in a terminal too, after you open a new one. If Pixi is installed
#' already, nothing happens unless `force = TRUE`; update an existing Pixi with
#' `pixi self-update` in a terminal.
#'
#' The installer is downloaded from <https://pixi.sh>. It may send prefix.dev
#' an anonymous install count; set `PIXI_NO_TELEMETRY=1` to turn that off. See
#' <https://pixi.prefix.dev/latest/installation/>.
#'
#' @param version Optional. The version of Pixi, such as `"0.81.0"`. Defaults
#'   to the latest.
#' @param update_path If `TRUE`, let the installer add Pixi to your shell's
#'   `PATH`, e.g. in `~/.zshrc`. If `FALSE`, only rpix will find it.
#' @param force If `TRUE`, install even if Pixi is installed already.
#' @returns The path to Pixi, invisibly.
#' @export
#' @examples
#' \dontrun{
#' install_pixi()
#' }
install_pixi <- function(version = NULL, update_path = TRUE, force = FALSE) {
  existing <- tryCatch(pixi_binary(offer_install = FALSE), error = function(e) {
    NULL
  })
  if (!is.null(existing) && !force) {
    cli::cli_alert_success("Pixi is installed already, at {.path {existing}}.")
    cli::cli_alert_info(
      "Update it with {.code pixi self-update} in a terminal, or reinstall it with {.code install_pixi(force = TRUE)}."
    )
    return(invisible(existing))
  }

  home <- Sys.getenv("PIXI_HOME", file.path(home_dir(), ".pixi"))
  if (is_interactive()) {
    question <- paste0(
      "Install Pixi into ",
      file.path(home, "bin"),
      if (update_path) ", and add it to your shell's PATH",
      "?"
    )
    if (!isTRUE(ask_yes_no(question))) {
      cli::cli_abort(
        "Cancelled: Pixi wasn't installed.",
        class = "rpix_cancelled",
        call = NULL
      )
    }
  }

  windows <- is_windows()
  installer <- tempfile(
    "pixi-install",
    fileext = if (windows) ".ps1" else ".sh"
  )
  on.exit(unlink(installer), add = TRUE)
  url <- if (windows) {
    "https://pixi.sh/install.ps1"
  } else {
    "https://pixi.sh/install.sh"
  }
  downloaded <- tryCatch(
    {
      download_installer(url, installer)
      TRUE
    },
    error = function(e) FALSE
  )
  if (!downloaded) {
    cli::cli_abort(
      c(
        "Couldn't download Pixi's installer from {.url {url}}.",
        "i" = "Check your internet connection, or install Pixi as {.url https://pixi.prefix.dev/latest/installation/} describes."
      ),
      call = NULL
    )
  }

  env <- c(
    "current",
    if (!is.null(version)) c(PIXI_VERSION = version),
    if (!update_path) c(PIXI_NO_PATH_UPDATE = "1")
  )
  status <- run_installer(installer, windows, env)
  if (status != 0) {
    cli::cli_abort(
      c(
        "Pixi's installer failed, with exit status {status}.",
        "i" = "See its output above, or install Pixi as {.url https://pixi.prefix.dev/latest/installation/} describes."
      ),
      call = NULL
    )
  }

  pixi <- file.path(home, "bin", if (windows) "pixi.exe" else "pixi")
  cli::cli_alert_success("Installed {pixi_version(pixi)} at {.path {pixi}}.")
  if (update_path) {
    cli::cli_alert_info("Open a new terminal to use {.code pixi} there.")
  }
  invisible(pixi)
}

pixi_version <- function(pixi) {
  trimws(processx::run(pixi, "--version")$stdout)
}

download_installer <- function(url, destination) {
  utils::download.file(url, destination, quiet = TRUE, mode = "wb")
}

# Run the installer, showing its output, and return its exit status
run_installer <- function(installer, windows, env) {
  command <- installer_command(installer, windows)
  # Both streams as they are, rather than processx's echo, which turns
  # stderr red
  show <- function(x, process) cat(x)
  result <- processx::run(
    command[1],
    command[-1],
    env = env,
    stdout_callback = show,
    stderr_callback = show,
    error_on_status = FALSE
  )
  result$status
}

installer_command <- function(installer, windows) {
  if (windows) {
    c(
      "powershell",
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      installer
    )
  } else {
    c("sh", installer)
  }
}
