# Pixi tasks

Tasks are commands saved in `pixi.toml`, such as
`test = "Rscript -e 'devtools::test()'"`, which anyone with the project
can run with `pixi run test`.

- `pixi_tasks()` lists the project's tasks.

- `pixi_run()` runs a task, showing its output as it runs.

- `pixi_add_task()` adds a task.

- `pixi_remove_task()` removes tasks.

For more information, see
<https://pixi.sh/latest/workspace/advanced_tasks/>.

## Usage

``` r
pixi_tasks(environment = NULL, path = NULL)

pixi_run(task, args = NULL, environment = NULL, path = NULL, dry_run = FALSE)

pixi_add_task(
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
)

pixi_remove_task(
  names,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE
)
```

## Arguments

- environment:

  Optional. The environment to list or run tasks in. Defaults to all
  environments for `pixi_tasks()`, and to the default environment for
  `pixi_run()`.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- task, name:

  The task's name.

- args:

  For `pixi_run()`, values for the task's arguments, or extra arguments
  for its command. For `pixi_add_task()`, the names of the task's
  arguments, which the command uses as `{{ name }}`.

- dry_run:

  If `TRUE`, show the Pixi command without running it.

- command:

  The command, as you'd type it in a terminal.

- description:

  Optional. What the task does, shown by `pixi task list`.

- depends_on:

  Optional. Tasks to run before this one.

- env:

  Optional. Environment variables to set, as a named character vector.

- cwd:

  Optional. The folder to run the command in, relative to the project.

- feature:

  Optional. The feature the task belongs to, rather than the default
  one. See
  [`pixi_add_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md).

- platform:

  Optional. Only add or remove the task for this platform, such as
  `"win-64"`.

- names:

  The tasks' names.

## Value

- `pixi_tasks()`: a data frame with a row per task, and the columns
  `name`, `command`, `description`, `feature`, `environments`,
  `depends_on` and `args` (the last three are lists of character
  vectors). It includes the tasks for the platform you're on.

- The others: the command (invisibly) if `dry_run = TRUE`, otherwise the
  result of the Pixi call (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_add_task("test", "Rscript -e 'devtools::test()'")
pixi_tasks()
pixi_run("test")
pixi_run("test", environment = "r44")

# A task with an argument
pixi_add_task("render", "quarto render {{ file }}", args = "file")
pixi_run("render", "analysis.qmd")
} # }
```
