local_jupyter_project <- function(
  environments = list(
    default = list(features = "default", deps = c("r-base", "r-cli")),
    r44 = list(features = "r44", deps = c("r-base", "python"))
  ),
  manifest = c("[workspace]", "", "[dependencies]", 'r-base = "4.5.*"'),
  env = parent.frame()
) {
  root <- local_pixi_project(content = manifest, env = env)
  calls <- local_recorded_pixi(env = env)
  calls$root <- root
  local_mocked_bindings(
    pixi_info = function(path) {
      list(
        environments_info = data.frame(
          name = names(environments),
          features = I(lapply(environments, `[[`, "features")),
          dependencies = I(lapply(environments, `[[`, "deps"))
        )
      )
    },
    .env = env
  )
  calls
}

read_kernel <- function(root, name) {
  jsonlite::read_json(file.path(
    root,
    ".jupyter",
    "kernels",
    name,
    "kernel.json"
  ))
}

test_that("use_pixi_jupyter() adds kernels, JupyterLab and the task", {
  calls <- local_jupyter_project()
  expect_snapshot(use_pixi_jupyter(path = calls$root))
  firsts <- vapply(calls$args, function(a) paste(a[1:2], collapse = " "), "")
  # IRkernel in the default feature; IRkernel and ipykernel in r44's
  expect_equal(calls$args[[1]], c("add", "--no-install", "r-irkernel"))
  expect_equal(
    calls$args[[2]],
    c("add", "--no-install", "r-irkernel", "ipykernel", "--feature", "r44")
  )
  expect_true("workspace environment" %in% firsts)
  expect_equal(
    calls$args[[length(calls$args)]][c(1:4, 7, 8)],
    c(
      "task",
      "add",
      "jupyter",
      "jupyter lab",
      "--env",
      "JUPYTER_PATH=$PIXI_PROJECT_ROOT/.jupyter"
    )
  )

  kernel <- read_kernel(calls$root, "pixi-r44")
  expect_equal(kernel$display_name, "R (Pixi: r44)")
  expect_equal(
    unlist(kernel$argv)[1:5],
    c("pixi", "run", "--environment", "r44", "R")
  )
  python <- read_kernel(calls$root, "pixi-r44-python")
  expect_equal(python$display_name, "Python (Pixi: r44)")
  expect_equal(python$language, "python")
  expect_false(dir.exists(file.path(
    calls$root,
    ".jupyter",
    "kernels",
    "pixi-default-python"
  )))
})

test_that("use_pixi_jupyter() leaves what's there, and adds the task again", {
  calls <- local_jupyter_project(
    environments = list(
      default = list(features = "default", deps = c("r-base", "r-irkernel")),
      jupyter = list(features = "jupyter", deps = "jupyterlab")
    ),
    manifest = c(
      "[workspace]",
      "",
      "[dependencies]",
      'r-base = "4.5.*"',
      'r-irkernel = "*"',
      "",
      "[feature.jupyter.dependencies]",
      'jupyterlab = "*"',
      "",
      "[environments]",
      'jupyter = { features = ["jupyter"], no-default-feature = true }'
    )
  )
  suppressMessages(use_pixi_jupyter(path = calls$root))
  firsts <- vapply(calls$args, `[`, "", 1)
  expect_equal(firsts, c("task", "task"))
  expect_true(file.exists(file.path(
    calls$root,
    ".jupyter",
    "kernels",
    "pixi-default",
    "kernel.json"
  )))
})

test_that("use_pixi_jupyter() needs an environment with R", {
  calls <- local_jupyter_project(
    environments = list(default = list(features = "default", deps = "python"))
  )
  expect_error(
    suppressMessages(use_pixi_jupyter(path = calls$root)),
    "No environment of the project has R"
  )
})
