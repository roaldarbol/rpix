#' Pixi tasks
#'
#' @description
#' Tasks are commands saved in `pixi.toml`, such as `test = "Rscript -e
#' 'devtools::test()'"`, which anyone with the project can run with
#' `pixi run test`.
#'
#' * `pixi_tasks()` lists the project's tasks.
#' * `pixi_run()` runs a task, showing its output as it runs.
#' * `pixi_add_task()` adds a task.
#' * `pixi_remove_task()` removes tasks.
#'
#' For more information, see <https://pixi.sh/latest/workspace/advanced_tasks/>.
#'
#' @param task,name The task's name.
#' @param args For `pixi_run()`, values for the task's arguments, or extra
#'   arguments for its command. For `pixi_add_task()`, the names of the task's
#'   arguments, which the command uses as `{{ name }}`.
#' @param environment Optional. The environment to list or run tasks in.
#'   Defaults to all environments for `pixi_tasks()`, and to the default
#'   environment for `pixi_run()`.
#' @param command The command, as you'd type it in a terminal.
#' @param description Optional. What the task does, shown by `pixi task list`.
#' @param depends_on Optional. Tasks to run before this one.
#' @param env Optional. Environment variables to set, as a named character
#'   vector.
#' @param cwd Optional. The folder to run the command in, relative to the
#'   project.
#' @param names The tasks' names.
#' @param feature Optional. The feature the task belongs to, rather than the
#'   default one. See [pixi_add_environment()].
#' @param platform Optional. Only add or remove the task for this platform,
#'   such as `"win-64"`.
#' @inheritParams pixi_environments
#' @returns
#' * `pixi_tasks()`: a data frame with a row per task, and the columns `name`,
#'   `command`, `description`, `feature`, `environments`, `depends_on` and
#'   `args` (the last three are lists of character vectors). It includes the
#'   tasks for the platform you're on.
#' * The others: the command (invisibly) if `dry_run = TRUE`, otherwise the
#'   result of the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_add_task("test", "Rscript -e 'devtools::test()'")
#' pixi_tasks()
#' pixi_run("test")
#' pixi_run("test", environment = "r44")
#'
#' # A task with an argument
#' pixi_add_task("render", "quarto render {{ file }}", args = "file")
#' pixi_run("render", "analysis.qmd")
#' }
pixi_tasks <- function(environment = NULL, path = NULL) {
  result <- run_pixi(c("task", "list", "--json"), path = path)
  envs <- jsonlite::fromJSON(result$stdout, simplifyVector = FALSE)

  rows <- list()
  for (env in envs) {
    groups <- c(
      list(list(name = NA_character_, tasks = env$tasks)),
      env$features
    )
    for (group in groups) {
      for (task in group$tasks) {
        key <- paste(group$name, task$name)
        if (is.null(rows[[key]])) {
          rows[[key]] <- task_row(task, group$name)
        }
        rows[[key]]$environments <- c(
          rows[[key]]$environments,
          env$environment
        )
      }
    }
  }

  if (!is.null(environment)) {
    rows <- Filter(function(row) environment %in% row$environments, rows)
  }
  rows <- unname(rows)
  # Pixi lists tasks in no particular order
  feature <- vapply(rows, function(row) row$feature, character(1))
  name <- vapply(rows, function(row) row$name, character(1))
  rows <- rows[order(feature != "default", feature, name, na.last = TRUE)]
  column <- function(name) lapply(rows, function(row) row[[name]])

  tasks <- data.frame(
    name = as.character(column("name")),
    command = as.character(column("command")),
    description = as.character(column("description")),
    feature = as.character(column("feature")),
    environments = I(column("environments")),
    depends_on = I(column("depends_on")),
    args = I(column("args")),
    stringsAsFactors = FALSE
  )
  new_rpix_df(tasks, "rpix_tasks")
}

task_row <- function(task, feature) {
  command <- unlist(task$cmd)
  list(
    name = task$name,
    command = if (is.null(command)) {
      NA_character_
    } else {
      paste(command, collapse = " ")
    },
    description = task$description %||% NA_character_,
    feature = feature,
    environments = character(),
    depends_on = as.character(unlist(lapply(
      task$depends_on,
      `[[`,
      "task_name"
    ))),
    args = as.character(unlist(lapply(task$args, `[[`, "name")))
  )
}

#' @rdname pixi_tasks
#' @export
pixi_run <- function(
  task,
  args = NULL,
  environment = NULL,
  path = NULL,
  dry_run = FALSE
) {
  run_pixi(
    c(
      "run",
      if (!is.null(environment)) c("--environment", environment),
      task,
      args
    ),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' @rdname pixi_tasks
#' @export
pixi_add_task <- function(
  name,
  command,
  description = NULL,
  depends_on = NULL,
  args = NULL,
  env = NULL,
  cwd = NULL,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE
) {
  if (!is.null(env) && (is.null(names(env)) || any(!nzchar(names(env))))) {
    cli::cli_abort("{.arg env} must be a named character vector.")
  }
  run_pixi(
    c(
      "task",
      "add",
      name,
      command,
      if (!is.null(description)) c("--description", description),
      if (length(depends_on) > 0) c("--depends-on", depends_on),
      if (length(args) > 0) as.vector(rbind("--arg", args)),
      if (length(env) > 0) {
        as.vector(rbind("--env", paste0(names(env), "=", env)))
      },
      if (!is.null(cwd)) c("--cwd", cwd),
      scope_args(feature, platform)
    ),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' @rdname pixi_tasks
#' @export
pixi_remove_task <- function(
  names,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE
) {
  run_pixi(
    c("task", "remove", names, scope_args(feature, platform)),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}
