task_list_json <- '[
  {
    "environment": "default",
    "tasks": [],
    "features": [
      {"name": "default", "tasks": [
        {"name": "test", "cmd": "Rscript -e \'devtools::test()\'",
         "description": "Run the tests", "depends_on": [], "args": null},
        {"name": "render", "cmd": ["quarto", "render", "{{ file }}"],
         "description": null,
         "depends_on": [{"task_name": "test", "args": null, "environment": null}],
         "args": [{"name": "file", "default": null, "choices": null}]}
      ]}
    ]
  },
  {
    "environment": "r44",
    "tasks": [{"name": "inline", "cmd": null, "description": null,
               "depends_on": [{"task_name": "test"}], "args": null}],
    "features": [
      {"name": "r44", "tasks": [
        {"name": "check", "cmd": "R CMD check", "description": null,
         "depends_on": [], "args": null}
      ]},
      {"name": "default", "tasks": [
        {"name": "test", "cmd": "Rscript -e \'devtools::test()\'",
         "description": "Run the tests", "depends_on": [], "args": null},
        {"name": "render", "cmd": ["quarto", "render", "{{ file }}"],
         "description": null,
         "depends_on": [{"task_name": "test", "args": null, "environment": null}],
         "args": [{"name": "file", "default": null, "choices": null}]}
      ]}
    ]
  }
]'

test_that("pixi_tasks() lists tasks once, with the environments they're in", {
  calls <- local_recorded_pixi(list(stdout = task_list_json))

  tasks <- pixi_tasks()
  expect_equal(calls$args[[1]], c("task", "list", "--json"))
  expect_equal(tasks$name, c("test", "render", "inline", "check"))
  expect_equal(
    tasks$command,
    c(
      "Rscript -e 'devtools::test()'",
      "quarto render {{ file }}",
      NA,
      "R CMD check"
    )
  )
  expect_equal(tasks$description, c("Run the tests", NA, NA, NA))
  expect_equal(tasks$feature, c("default", "default", NA, "r44"))
  expect_equal(tasks$environments[[1]], c("default", "r44"))
  expect_equal(tasks$environments[[4]], "r44")
  expect_equal(tasks$depends_on[[2]], "test")
  expect_equal(tasks$depends_on[[1]], character())
  expect_equal(tasks$args[[2]], "file")

  expect_equal(pixi_tasks(environment = "default")$name, c("test", "render"))
})

test_that("pixi_tasks() gives an empty data frame without tasks", {
  local_recorded_pixi(list(
    stdout = '[{"environment": "default", "tasks": [], "features": []}]'
  ))

  tasks <- pixi_tasks()
  expect_equal(nrow(tasks), 0)
  expect_named(
    tasks,
    c(
      "name",
      "command",
      "description",
      "feature",
      "environments",
      "depends_on",
      "args"
    )
  )
})

test_that("pixi_run() runs a task in an environment, with arguments", {
  calls <- local_recorded_pixi()

  pixi_run("test")
  pixi_run("render", "analysis.qmd", environment = "r44")

  expect_equal(calls$args[[1]], c("run", "test"))
  expect_equal(
    calls$args[[2]],
    c("run", "--environment", "r44", "render", "analysis.qmd")
  )
})

test_that("pixi_add_task() passes the task's options", {
  calls <- local_recorded_pixi()

  pixi_add_task("test", "Rscript -e 'devtools::test()'")
  pixi_add_task(
    "render",
    "quarto render {{ file }}",
    description = "Render a file",
    depends_on = c("document", "test"),
    args = "file",
    env = c(CI = "true", LANG = "C"),
    cwd = "docs",
    feature = "docs",
    platform = "linux-64"
  )

  expect_equal(
    calls$args[[1]],
    c("task", "add", "test", "Rscript -e 'devtools::test()'")
  )
  expect_equal(
    calls$args[[2]],
    c(
      "task",
      "add",
      "render",
      "quarto render {{ file }}",
      "--description",
      "Render a file",
      "--depends-on",
      "document",
      "test",
      "--arg",
      "file",
      "--env",
      "CI=true",
      "--env",
      "LANG=C",
      "--cwd",
      "docs",
      "--feature",
      "docs",
      "--platform",
      "linux-64"
    )
  )
})

test_that("pixi_add_task() needs named environment variables", {
  local_recorded_pixi()
  expect_error(pixi_add_task("a", "echo", env = "true"), "named")
  expect_error(pixi_add_task("a", "echo", env = c(A = "1", "2")), "named")
})

test_that("pixi_remove_task() removes tasks from a feature or platform", {
  calls <- local_recorded_pixi()

  pixi_remove_task(c("test", "render"), feature = "docs", platform = "win-64")

  expect_equal(
    calls$args[[1]],
    c(
      "task",
      "remove",
      "test",
      "render",
      "--feature",
      "docs",
      "--platform",
      "win-64"
    )
  )
})

test_that("tasks can be added, listed, run and removed with Pixi", {
  skip_on_cran()
  skip_if_no_pixi()
  withr::local_envvar(PIXI_PROJECT_ROOT = NA)
  dir <- withr::local_tempdir()
  run_pixi(c("init", dir), project = "none")

  pixi_add_task(
    "greet",
    "echo hello {{ name }}",
    description = "Say hello",
    args = "name",
    path = dir
  )
  tasks <- pixi_tasks(path = dir)
  expect_equal(tasks$name, "greet")
  expect_equal(tasks$description, "Say hello")
  expect_equal(tasks$args[[1]], "name")

  output <- capture.output(result <- pixi_run("greet", "world", path = dir))
  expect_match(result$stdout, "hello world")

  pixi_remove_task("greet", path = dir)
  expect_equal(nrow(pixi_tasks(path = dir)), 0)
})
