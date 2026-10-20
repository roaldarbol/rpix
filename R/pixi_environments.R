#' Features and environments
#'
#' @description
#' A Pixi project can have several environments, each with its own R and
#' packages: say one with R 4.4 and one with R 4.5, or one with the packages
#' your tests need on top of the project's own.
#'
#' Environments are made of *features*: named sets of packages. The default
#' feature holds what [pixi_add()] adds, and is in every environment unless
#' it's left out. Add packages to another feature with
#' `pixi_add(feature = )`; that also creates the feature. Then make an
#' environment of it with `pixi_add_environment()`, and start its R with
#' `pixi run --environment <name> R`.
#'
#' * `pixi_environments()` lists the project's environments.
#' * `pixi_add_environment()` adds an environment, made of features.
#' * `pixi_remove_environment()` removes one.
#'
#' For more information, see <https://pixi.prefix.dev/latest/workspace/multi_environment/>.
#'
#' @param name The environment's name.
#' @param features The features it's made of. They have to exist already, so
#'   add packages to them first with `pixi_add(feature = )`. Without any, the
#'   environment is a copy of the default one.
#' @param r_version Optional. Another version of R for the environment, such
#'   as `"4.4"`, in one step: a feature named after the environment gets that
#'   R, the default feature's packages (by name, so it gets the versions built
#'   for that R) and `conda-ecosystem-user-package-isolation`. The environment
#'   leaves out the default feature, which has the project's R, and is
#'   installed, with rpix in it if the project has rpix. Packages built from
#'   source aren't copied; rpix says how to add them. If that R can't have the
#'   project's packages, `pixi.toml` and `pixi.lock` are left as they were.
#' @param solve_group Optional. Environments in the same solve group get the
#'   same versions of the packages they share.
#' @param default_feature If `FALSE`, leave out the default feature. Needed
#'   when a feature conflicts with it, e.g. pins another version of R. If the
#'   environment has R, rpix then adds `conda-ecosystem-user-package-isolation`
#'   to its first feature, as [use_pixi()] does to the default one, to keep
#'   your personal R library out.
#' @param overwrite If `TRUE`, replace an environment that already exists.
#' @param path The project. Defaults to the project of the running Pixi
#'   environment, or the working directory.
#' @param dry_run If `TRUE`, show the Pixi command without running it.
#' @returns
#' * `pixi_environments()`: a data frame with a row per environment, and the
#'   columns `name`, `features` and `platforms` (lists of character vectors)
#'   and `solve_group`.
#' * The others: the command (invisibly) if `dry_run = TRUE`, otherwise the
#'   result of the Pixi call (invisibly).
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' # An environment with R 4.4 and the project's packages, next to the
#' # default one
#' pixi_add_environment("r44", r_version = "4.4", path = project, dry_run = TRUE)
#'
#' # An environment with the default packages plus testthat, on the same
#' # versions as the default environment
#' pixi_add("testthat", feature = "test", path = project, dry_run = TRUE)
#' pixi_add_environment(
#'   "test",
#'   features = "test",
#'   solve_group = "default",
#'   path = project,
#'   dry_run = TRUE
#' )
#'
#' \dontrun{
#' # Needs Pixi
#' pixi_environments()
#' }
pixi_environments <- function(path = NULL) {
  envs <- run_pixi("info", path = path, json = TRUE)$environments_info
  platforms <- lapply(envs$platforms, function(p) p$name)
  envs <- data.frame(
    name = envs$name,
    features = I(envs$features),
    platforms = I(platforms),
    solve_group = as.character(envs$solve_group %||% rep(NA, nrow(envs))),
    stringsAsFactors = FALSE
  )
  new_rpix_df(envs, "rpix_environments")
}

#' @rdname pixi_environments
#' @export
pixi_add_environment <- function(
  name,
  features = NULL,
  r_version = NULL,
  solve_group = NULL,
  default_feature = TRUE,
  overwrite = FALSE,
  path = NULL,
  dry_run = FALSE
) {
  if (!is.null(r_version)) {
    return(add_r_environment(
      name,
      r_version,
      features = features,
      solve_group = solve_group,
      overwrite = overwrite,
      path = path,
      dry_run = dry_run
    ))
  }
  if (length(features) == 0) {
    cli::cli_alert_warning(
      "Without {.arg features}, {.val {name}} is a copy of the default environment."
    )
    hint(
      "Give it features of its own, e.g. {.code features = \"test\"}, or another R with {.code r_version = \"4.4\"}."
    )
  }
  args <- c(
    "workspace",
    "environment",
    "add",
    name,
    if (length(features) > 0) as.vector(rbind("--feature", features)),
    if (!is.null(solve_group)) c("--solve-group", solve_group),
    if (!default_feature) "--no-default-feature",
    if (overwrite) "--force"
  )
  isolation <- if (!default_feature) {
    add_isolation(features, path = path, dry_run = dry_run)
  }
  result <- run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
  if (isTRUE(dry_run)) {
    return(invisible(c(isolation, result)))
  }
  invisible(result)
}

# An environment without the default feature lacks the isolation from the
# personal library that use_pixi() adds there. If it has R, add the isolation
# to its first feature, unless one of its features has it.
add_isolation <- function(features, path = NULL, dry_run = FALSE) {
  manifest <- find_manifest(path)
  if (length(features) == 0 || is.null(manifest)) {
    return(NULL)
  }
  lines <- readLines(manifest, warn = FALSE)
  has <- function(package) {
    pattern <- paste0("^\\s*", package, "\\s*=")
    any(vapply(
      features,
      function(f) {
        any(grepl(pattern, lines[table_lines(lines, dependency_table(f))]))
      },
      logical(1)
    ))
  }
  if (!has("r-base") || has(isolation_package)) {
    return(NULL)
  }
  cli::cli_alert_info(
    "Adding {.pkg {isolation_package}} to {.val {features[1]}}, to keep your personal R library out: the environment leaves out the default feature, which has it."
  )
  pixi_add(
    paste0("conda::", isolation_package),
    feature = features[1],
    path = path,
    dry_run = dry_run
  )
}

#' @rdname pixi_environments
#' @export
pixi_remove_environment <- function(name, path = NULL, dry_run = FALSE) {
  run_pixi(
    c("workspace", "environment", "remove", name),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' Add or remove the project's channels and platforms
#'
#' @description
#' * `pixi_add_channel()` adds conda channels, which packages are installed
#'   from. [pixi_add()] adds the ones it needs itself.
#' * `pixi_add_platform()` adds platforms, such as `"linux-64"`, `"osx-arm64"`
#'   or `"win-64"`, so `pixi.lock` covers them too and collaborators on them
#'   get the same packages.
#' * `pixi_remove_channel()` and `pixi_remove_platform()` remove them again,
#'   e.g. a platform no one uses, which Pixi then no longer solves for, or a
#'   channel the project no longer needs packages from.
#'
#' For more information, see
#' <https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/channel/>
#' and <https://pixi.prefix.dev/latest/reference/cli/pixi/workspace/platform/>.
#'
#' @param channels Channel names, such as `"bioconda"`, or URLs.
#' @param platforms Platform names.
#' @inheritParams pixi_environments
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @export
#' @example man/examples/project.R
#' @examples
#'
#' pixi_add_channel("bioconda", path = project, dry_run = TRUE)
#' pixi_add_platform("osx-64", path = project, dry_run = TRUE)
pixi_add_channel <- function(channels, path = NULL, dry_run = FALSE) {
  run_pixi(
    c("workspace", "channel", "add", channels),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' @rdname pixi_add_channel
#' @export
pixi_add_platform <- function(platforms, path = NULL, dry_run = FALSE) {
  run_pixi(
    c("workspace", "platform", "add", platforms),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' @rdname pixi_add_channel
#' @export
pixi_remove_channel <- function(channels, path = NULL, dry_run = FALSE) {
  run_pixi(
    c("workspace", "channel", "remove", channels),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

#' @rdname pixi_add_channel
#' @export
pixi_remove_platform <- function(platforms, path = NULL, dry_run = FALSE) {
  run_pixi(
    c("workspace", "platform", "remove", platforms),
    path = path,
    echo = TRUE,
    dry_run = dry_run
  )
}

# An environment with another version of R, in one step (#201): a feature
# named after it, with that R, the default feature's packages and the
# isolation, without the default feature, which has the project's R
add_r_environment <- function(
  name,
  r_version,
  features = NULL,
  solve_group = NULL,
  overwrite = FALSE,
  path = NULL,
  dry_run = FALSE,
  call = parent.frame()
) {
  root <- require_project(path, call = call)
  manifest <- find_manifest(root)
  lines <- readLines(manifest, warn = FALSE)
  default <- default_feature_packages(lines)
  specs <- unique(c(
    paste0("r-base=", r_version),
    isolation_package,
    setdiff(default$specs, c("r-base", isolation_package))
  ))
  add <- c("add", "--feature", name, "--no-install", specs)
  environment <- c(
    "workspace",
    "environment",
    "add",
    name,
    as.vector(rbind("--feature", unique(c(name, features)))),
    "--no-default-feature",
    if (!is.null(solve_group)) c("--solve-group", solve_group),
    if (overwrite) "--force"
  )
  # Pins the versions, which Pixi leaves at * for a feature no environment
  # used yet, but not R
  pin <- c("upgrade", "--feature", name, "--exclude", "r-base", "--no-install")
  if (isTRUE(dry_run)) {
    commands <- vapply(
      list(add, environment, pin),
      function(args) run_pixi(args, path = root, dry_run = TRUE),
      character(1)
    )
    return(invisible(commands))
  }

  lock <- file.path(root, "pixi.lock")
  locked <- if (file.exists(lock)) readLines(lock, warn = FALSE)
  restore <- function() {
    writeLines(lines, manifest)
    if (!is.null(locked)) writeLines(locked, lock)
  }
  cli::cli_alert_info(
    "Adding the {.val {name}} environment, with R {r_version} and the project's {length(specs) - 2} package{?s}."
  )
  tryCatch(
    {
      run_pixi(add, path = root)
      run_pixi(environment, path = root)
      run_pixi(pin, path = root)
    },
    rpix_error_pixi = function(e) {
      restore()
      cli::cli_abort(
        c(
          "R {r_version} can't have all the project's packages, so {.file pixi.toml} is as it was.",
          "i" = "Pixi's output below names what doesn't fit. Add the environment with fewer packages with {.code rpix::pixi_add(c(\"r-base={r_version}\", ...), feature = \"{name}\")} and {.code rpix::pixi_add_environment(\"{name}\", features = \"{name}\", default_feature = FALSE)}."
        ),
        parent = reveal_pixi_failure(e),
        call = call
      )
    }
  )
  install_environment(name, root)
  cli::cli_alert_success(
    "Added the {.val {name}} environment, with R {r_version}."
  )
  if (length(default$skipped) > 0) {
    cli::cli_alert_info(
      "Not copied, as {cli::qty(length(default$skipped))}{?it's/they're} built from source: {.pkg {default$skipped}}. Add {?it/them} to the environment with {.code rpix::pixi_add(..., feature = \"{name}\")}."
    )
  }
  hint("Switch to it with {.code rpix::pixi_switch(\"{name}\")}.")
  invisible(file.path(root, "pixi.toml"))
}

# The default feature's packages as `pixi add` takes them: names, with their
# channel if they have one (e.g. bioconda::bioconductor-limma), and the ones
# built from source (git, path or url sources), which can't be copied by name
default_feature_packages <- function(lines) {
  rows <- c(
    table_lines(lines, "dependencies"),
    table_lines(lines, "tool.pixi.dependencies")
  )
  rows <- rows[!grepl("^\\s*\\[", lines[rows])]
  text <- sub("#.*$", "", lines[rows])
  # Each entry with its continuation lines, as TOML 1.1's inline tables can
  # span several
  braces <- function(x, brace) lengths(regmatches(x, gregexpr(brace, x)))
  depth <- cumsum(braces(text, "\\{") - braces(text, "\\}"))
  starts <- c(TRUE, depth[-length(depth)] == 0)
  entries <- vapply(
    split(text, cumsum(starts)),
    paste,
    character(1),
    collapse = " "
  )
  pattern <- '^\\s*"?([A-Za-z0-9._-]+)"?\\s*=\\s*(.*)$'
  entries <- entries[grepl(pattern, entries)]
  names <- sub(pattern, "\\1", entries)
  values <- trimws(sub(pattern, "\\2", entries))
  table <- startsWith(values, "{")
  source <- table & grepl("\\b(git|path|url|package)\\s*=", values)
  channel <- ifelse(
    table & grepl('channel\\s*=\\s*"', values),
    sub('^.*channel\\s*=\\s*"([^"]+)".*$', "\\1", values),
    NA_character_
  )
  specs <- ifelse(is.na(channel), names, paste0(channel, "::", names))
  list(specs = unname(specs[!source]), skipped = unname(names[source]))
}
