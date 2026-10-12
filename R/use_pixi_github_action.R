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
#'   environment on each operating system. The environments need rcmdcheck.
#'   Use it with [use_pixi_check_matrix()]'s environments, e.g.
#'   `environments = c("r44", "r45", "minimum")`.
#' * `"test-coverage"`: test coverage, reported to Codecov. The environment
#'   needs covr and xml2.
#' * `"pkgdown"`: build the pkgdown site and publish it to GitHub Pages. The
#'   environment needs pkgdown and pandoc.
#' * `"task"`: run one of the project's Pixi tasks, e.g. to render a report.
#'
#' The operating systems are those of the project's platforms that GitHub
#' runs: Linux (`linux-64`), macOS (`osx-arm64`) and Windows (`win-64`). Add
#' platforms with [pixi_add_platform()]. Pixi is pinned to the version you
#' have, and the workflow fails if `pixi.lock` is out of date with
#' `pixi.toml`, so commit both.
#'
#' @param workflow Which workflow: `"check"`, `"test-coverage"`, `"pkgdown"`
#'   or `"task"`.
#' @param environments The environments to use. Defaults to the default
#'   environment. `"test-coverage"` and `"pkgdown"` use the first.
#' @param task For `"task"`, the task to run.
#' @param overwrite If `TRUE`, replace a workflow that's there.
#' @param path The project. Defaults to the working directory.
#' @returns The path to the workflow file, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi_github_action("check")
#' use_pixi_github_action("check", environments = c("r44", "r45", "minimum"))
#' use_pixi_github_action("task", task = "render")
#' }
use_pixi_github_action <- function(
  workflow = c("check", "test-coverage", "pkgdown", "task"),
  environments = "default",
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
  if (nrow(runners) == 0) {
    cli::cli_abort(c(
      "The project has none of the platforms GitHub runs: {.val {github_runners$platform}}.",
      "i" = "Add one with {.code pixi_add_platform(\"linux-64\")}."
    ))
  }
  missing <- setdiff(github_runners$platform, platforms)
  if (workflow %in% c("check", "task") && length(missing) > 0) {
    cli::cli_alert_info(
      "Not on {.val {github_runners$os[github_runners$platform %in% missing]}}: the project doesn't have {.val {missing}}. Add {cli::qty(length(missing))}{?it/them} with {.code pixi_add_platform()}."
    )
  }

  needs <- workflow_needs[[workflow]]
  lacking <- needs[!vapply(needs, manifest_has_package, logical(1), root)]
  if (length(lacking) > 0) {
    cli::cli_alert_warning(
      "The workflow needs {.pkg {lacking}}, which {cli::qty(length(lacking))}{?isn't/aren't} in {.file pixi.toml}. Add {?it/them}, e.g. with {.code pixi_add()}."
    )
  }

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
# packages
workflow_needs <- list(
  check = "rcmdcheck",
  "test-coverage" = c("covr", "xml2"),
  pkgdown = c("pkgdown", "conda::pandoc"),
  task = character()
)

setup_pixi_version <- "v0.10.2"

# The Pixi version that's installed, as setup-pixi takes it: v0.81.0
installed_pixi_version <- function() {
  version <- trimws(run_pixi("--version", project = "none")$stdout)
  paste0("v", sub("^pixi\\s+", "", version))
}

# Whether pixi.toml lists a package, in any table. An R package is looked
# for as r-<name>, a "conda::" one as it is.
manifest_has_package <- function(package, root) {
  manifest <- find_manifest(root)
  if (is.null(manifest)) {
    return(FALSE)
  }
  name <- if (startsWith(package, "conda::")) {
    sub("^conda::", "", package)
  } else {
    paste0("r-", tolower(package))
  }
  lines <- readLines(manifest, warn = FALSE)
  any(grepl(
    paste0('^\\s*"?', gsub(".", "\\.", name, fixed = TRUE), '"?\\s*='),
    lines
  ))
}
