#' Set up GitHub Actions with the project's Pixi environments
#'
#' @description
#' Write a GitHub Actions workflow that installs the project's environments
#' exactly as `pixi.lock` records them, with
#' [setup-pixi](https://github.com/prefix-dev/setup-pixi), so CI uses the same
#' R and packages as your computer. It replaces `setup-r`,
#' `setup-r-dependencies` and `setup-pandoc` from
#' [r-lib/actions](https://github.com/r-lib/actions), whose other actions run
#' as usual on top.
#'
#' * `"check"`: `R CMD check`, with r-lib's `check-r-package`, for each
#'   environment on each operating system. The environments need rcmdcheck,
#'   as [use_pixi_check_matrix()]'s do.
#' * `"test-coverage"`: test coverage, reported to Codecov. The environment
#'   needs covr and xml2.
#' * `"pkgdown"`: build the pkgdown site and publish it to GitHub Pages. The
#'   environment needs pkgdown and pandoc.
#' * `"task"`: run one of the project's Pixi tasks, e.g. to render a report.
#'
#' In a package, `"check"`, `"test-coverage"` and `"pkgdown"` also need the
#' package's dependencies from `DESCRIPTION`, `Suggests` included. rpix warns
#' about each environment that lacks any of these.
#'
#' The operating systems are those of the project's platforms that GitHub
#' runs: Linux (`linux-64`), macOS (`osx-arm64`) and Windows (`win-64`). Add
#' platforms with [pixi_add_platform()]. Pixi is pinned to the version you
#' have, and the workflow fails if `pixi.lock` is out of date with
#' `pixi.toml`, so commit both.
#'
#' @param workflow Which workflow: `"check"`, `"test-coverage"`, `"pkgdown"`
#'   or `"task"`.
#' @param environments Optional. The environments to use; `"test-coverage"`
#'   and `"pkgdown"` use the first. Defaults to those that have what the
#'   workflow needs: for `"check"` all of them, and for `"test-coverage"` and
#'   `"pkgdown"` the first, or else the default environment. `"task"` defaults
#'   to the default environment.
#' @param task For `"task"`, the task to run.
#' @param overwrite If `TRUE`, replace a workflow that's there.
#' @param path The project. Defaults to the working directory.
#' @returns The path to the workflow file, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi_github_action("check")
#' use_pixi_github_action("check", environments = c("r44", "r45"))
#' use_pixi_github_action("task", task = "render")
#' }
use_pixi_github_action <- function(
  workflow = c("check", "test-coverage", "pkgdown", "task"),
  environments = NULL,
  task = NULL,
  overwrite = FALSE,
  path = NULL
) {
  workflow <- match.arg(workflow)
  root <- require_project(path)
  if (workflow == "task" && is.null(task)) {
    cli::cli_abort("Give the {.arg task} to run.")
  }
  name <- if (workflow == "task") task else workflow
  file <- file.path(
    root,
    ".github",
    "workflows",
    paste0("pixi-", name, ".yaml")
  )
  if (file.exists(file) && !overwrite) {
    cli::cli_abort(c(
      "{.path {file.path('.github', 'workflows', basename(file))}} is there already.",
      "i" = "Replace it with {.code overwrite = TRUE}."
    ))
  }

  platforms <- project_platforms(root)
  runners <- github_runners[github_runners$platform %in% platforms, ]
  if (nrow(runners) == 0 && is_interactive()) {
    cli::cli_alert_warning(
      "The project has none of the platforms GitHub runs: {.val {github_runners$platform}}."
    )
    if (isTRUE(ask_yes_no("Would you like to add linux-64?"))) {
      pixi_add_platform("linux-64", path = root)
      platforms <- project_platforms(root)
      runners <- github_runners[github_runners$platform %in% platforms, ]
    }
  }
  if (nrow(runners) == 0) {
    cli::cli_abort(c(
      "The project has none of the platforms GitHub runs: {.val {github_runners$platform}}.",
      "i" = "Add one with {.code rpix::pixi_add_platform(\"linux-64\")}."
    ))
  }
  missing <- setdiff(github_runners$platform, platforms)
  if (workflow %in% c("check", "task") && length(missing) > 0) {
    cli::cli_alert_info(
      "Not on {.val {github_runners$os[github_runners$platform %in% missing]}}: the project doesn't have {.val {missing}}. Add {cli::qty(length(missing))}{?it/them} with {.code rpix::pixi_add_platform()}."
    )
  }

  environments <- workflow_environments(workflow, environments, root)

  values <- c(
    os = paste(runners$os, collapse = ", "),
    environments = paste(environments, collapse = ", "),
    environment = environments[1],
    task = task %||% "",
    setup_pixi = setup_pixi_version,
    pixi_version = installed_pixi_version()
  )
  text <- readLines(
    system.file(
      "templates",
      paste0("github-", workflow, ".yaml"),
      package = "rpix"
    ),
    warn = FALSE
  )
  for (key in names(values)) {
    text <- gsub(paste0("{{", key, "}}"), values[[key]], text, fixed = TRUE)
  }

  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  writeLines(text, file)
  build_ignore(root, ".github")
  cli::cli_alert_success(
    "Wrote {.path {file.path('.github', 'workflows', basename(file))}}. Commit it with {.file pixi.toml} and {.file pixi.lock}."
  )
  invisible(file)
}

# The GitHub runners, and the Pixi platform each runs
github_runners <- data.frame(
  platform = c("linux-64", "osx-arm64", "win-64"),
  os = c("ubuntu-latest", "macos-latest", "windows-latest")
)

# What each workflow needs in the environment, as R packages or conda
# packages. In a package, all but "task" need its dependencies too.
workflow_needs <- list(
  check = "rcmdcheck",
  "test-coverage" = c("covr", "xml2"),
  pkgdown = c("pkgdown", "conda::pandoc"),
  task = character()
)

# The environments a workflow runs in: `environments`, or those that have
# what it needs (all of them for "check", the first for the others). Warns
# about each one that lacks something.
workflow_environments <- function(
  workflow,
  environments,
  root,
  call = rlang::caller_env()
) {
  envs <- pixi_info(root)$environments_info
  unknown <- setdiff(environments, envs$name)
  if (length(unknown) > 0) {
    cli::cli_abort(
      c(
        "The project has no environment {.val {unknown}}.",
        "i" = "Its environments are {.val {envs$name}}."
      ),
      call = call
    )
  }
  if (workflow == "task") {
    return(environments %||% "default")
  }

  deps <- lapply(envs$dependencies, unlist)
  needs <- workflow_packages(workflow, root, unique(unlist(deps)))
  lacking <- stats::setNames(
    lapply(deps, function(d) needs$spec[!needs$conda %in% d]),
    envs$name
  )
  # Where to add what an environment lacks: its own feature
  features <- stats::setNames(
    vapply(envs$features, function(f) unlist(f)[1], character(1)),
    envs$name
  )

  if (is.null(environments)) {
    ready <- envs$name[lengths(lacking) == 0]
    if (workflow == "check" && length(ready) == 0) {
      best <- names(which.min(lengths(lacking)))
      cli::cli_abort(
        c(
          "No environment has what {.code R CMD check} needs.",
          "i" = "Add environments that do with {.code rpix::use_pixi_check_matrix()}, or add what {.val {best}} lacks with {.code {add_hint(lacking[[best]], features[[best]])}}."
        ),
        call = call
      )
    }
    environments <- if (workflow == "check") ready else c(ready, "default")[1]
    if (length(ready) > 0) {
      cli::cli_alert_info(
        "Using {cli::qty(length(environments))}the environment{?s} {.val {environments}}, which {?has/have} what the workflow needs."
      )
    }
  }

  for (environment in environments) {
    missing <- lacking[[environment]]
    if (length(missing) > 0) {
      cli::cli_alert_warning(
        "{.val {environment}} lacks {.pkg {missing}}, which the workflow needs. Add {cli::qty(length(missing))}{?it/them} with {.code {add_hint(missing, features[[environment]])}}."
      )
    }
  }
  environments
}

# What a workflow needs: `spec`, as pixi_add() takes it, and `conda`, the name
# in an environment's dependencies. Of a package's dependencies, only those
# some environment has count: no choice of environment helps with the others.
workflow_packages <- function(workflow, root, available) {
  tools <- workflow_needs[[workflow]]
  needs <- data.frame(
    spec = tools,
    conda = ifelse(
      startsWith(tools, "conda::"),
      sub("^conda::", "", tools),
      paste0("r-", tolower(tools))
    )
  )
  if (!is_package(root)) {
    return(needs)
  }
  packages <- setdiff(
    package_dependencies(file.path(root, "DESCRIPTION")),
    tools
  )
  bioc <- paste0("bioconductor-", tolower(packages)) %in% available
  conda <- ifelse(
    bioc,
    paste0("bioconductor-", tolower(packages)),
    paste0("r-", tolower(packages))
  )
  spec <- ifelse(bioc, paste0("bioc::", packages), packages)
  keep <- conda %in% available
  rbind(needs, data.frame(spec = spec[keep], conda = conda[keep]))
}

# The pixi_add() call that adds packages to a feature
add_hint <- function(packages, feature) {
  quoted <- paste0('"', packages, '"', collapse = ", ")
  if (length(packages) > 1) {
    quoted <- paste0("c(", quoted, ")")
  }
  feature <- if (feature == "default") {
    ""
  } else {
    paste0(', feature = "', feature, '"')
  }
  paste0("rpix::pixi_add(", quoted, feature, ")")
}

setup_pixi_version <- "v0.10.2"

# The Pixi version that's installed, as setup-pixi takes it: v0.81.0
installed_pixi_version <- function() {
  version <- trimws(run_pixi("--version", project = "none")$stdout)
  paste0("v", sub("^pixi\\s+", "", version))
}
