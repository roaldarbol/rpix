#' Run a function in another environment's R
#'
#' @description
#' Call a function in the R of another Pixi environment, e.g. one with another
#' version of R, and get its result back, like `callr::r()`. The function runs
#' in a new R process, started with `pixi run`, so it uses that environment's
#' R and packages; your current R is left alone.
#'
#' The function and its arguments are copied to the new R, but not the
#' variables around it. Refer to packages with `::` or load them in the
#' function, and pass in what it needs as arguments.
#'
#' @param func A function.
#' @param args A list of arguments to call it with.
#' @param environment Optional. The environment. Defaults to `default`.
#' @param show If `TRUE`, show the function's output while it runs.
#' @inheritParams pixi_environments
#' @returns The function's result.
#' @export
#' @examples
#' \dontrun{
#' pixi_r(function() R.version.string, environment = "r44")
#' pixi_r(function(x) packageVersion(x), list("dplyr"), environment = "r44")
#' }
pixi_r <- function(
  func,
  args = list(),
  environment = NULL,
  show = TRUE,
  path = NULL
) {
  if (!is.function(func)) {
    cli::cli_abort("{.arg func} must be a function.")
  }
  if (!is.list(args)) {
    cli::cli_abort("{.arg args} must be a list.")
  }

  job <- pixi_r_job(func, args, environment)
  on.exit(unlink(job$dir, recursive = TRUE), add = TRUE)
  run_pixi(job$args, path = path, echo = show, announce = FALSE)

  output <- readRDS(job$output)
  if (!is.null(output$error)) {
    cli::cli_abort(
      c(
        "The function failed in the {.val {environment %||% 'default'}} environment.",
        "x" = "{output$error}"
      ),
      class = "rpix_error_pixi_r"
    )
  }
  output$value
}

# Files and Pixi arguments to run a function in an environment's R. The
# result, or the error, ends up in `output`.
pixi_r_job <- function(func, args, environment) {
  # Don't take the caller's variables along; functions from packages are
  # looked up by the package's name
  if (!isNamespace(environment(func))) {
    environment(func) <- globalenv()
  }

  dir <- tempfile("rpix-r-")
  dir.create(dir)
  files <- file.path(dir, c("runner.R", "input.rds", "output.rds"))
  writeLines(pixi_r_runner, files[1])
  saveRDS(list(func = func, args = args), files[2])

  list(
    dir = dir,
    output = files[3],
    args = c(
      "run",
      if (!is.null(environment)) c("--environment", environment),
      "Rscript",
      "--no-init-file",
      files
    )
  )
}

# Runs in the other R: calls the function, and saves its result or error
pixi_r_runner <- c(
  "local({",
  "  files <- commandArgs(trailingOnly = TRUE)",
  "  input <- readRDS(files[1])",
  "  output <- tryCatch(",
  "    list(value = do.call(input$func, input$args)),",
  "    error = function(e) list(error = conditionMessage(e))",
  "  )",
  "  saveRDS(output, files[2])",
  "})"
)
