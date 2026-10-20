#' Set up a Pixi project for R
#'
#' @description
#' Create a Pixi project in the working directory, or `path`, if there isn't
#' one there, add R to it, and install rpix into its environment.
#'
#' It sets up that folder even inside another Pixi project. If a parent folder
#' is a Pixi project, it says so, and in an interactive session asks whether to
#' set that one up instead.
#'
#' It also adds conda-forge's `conda-ecosystem-user-package-isolation`, which
#' keeps your personal R library out of the environment's R. Otherwise
#' conda-forge's R loads packages installed for your usual R first.
#'
#' It can be run from any R. Afterwards, work in R started by Pixi: run
#' `pixi run R` in a terminal, or use an IDE set up with `ide` (see
#' <https://roald-arboel.com/rpix/articles/ide.html>). Each Pixi environment
#' has its own R and package library, so rpix doesn't point a running R at a
#' Pixi library: packages built for a different R can crash it.
#'
#' It also adds a block to the project's `.Rprofile` that calls
#' [pixi_activate()], so the environment is activated when an IDE starts its
#' R directly. Projects set up with rpix 0.3.0 or earlier have a "Pixi R
#' library setup" block in their `.Rprofile` instead, which pointed a running
#' R at the Pixi library. It's removed.
#'
#' A new project supports Linux, macOS (Intel and Apple Silicon) and Windows,
#' as well as this computer's platform, so collaborators on any of them can
#' install it. `pixi.lock` then covers each of them, so a package can only be
#' added if it's on conda-forge for all of them; for one that isn't, see
#' `platform` in [pixi_add()].
#'
#' In a package, it adds `.pixi`, `pixi.toml` and `pixi.lock` to
#' `.Rbuildignore`, so they stay out of the package's builds.
#'
#' It turns on Pixi's activation cache for the project, in
#' `.pixi/config.toml`. Pixi then reuses the environment's activation until the
#' project changes, so R started through Pixi, e.g. by `pixi run` or Positron,
#' starts in a fraction of a second rather than a few. The cache is
#' experimental in Pixi, and doesn't notice changes outside the project, e.g.
#' a newly installed Java.
#'
#' @param r_version Optional. The R version to add, such as `"4.5"`. Defaults
#'   to the newest one that conda-forge has R packages for; it has a new R
#'   before its packages are built for it.
#' @param ide Optional. IDEs to set the project up for: any of `"rstudio"`,
#'   `"positron"`, `"vscode"`, `"emacs"`, `"neovim"` and `"zed"`. See
#'   [use_pixi_ide].
#' @param init_if_missing If `TRUE`, create a Pixi project if there isn't one.
#' @param date Optional. Use packages as they were on this date, such as
#'   `"2025-06-01"`, e.g. to rerun an old analysis. Set before anything is
#'   added, so R and the packages are all as of that date. See
#'   [pixi_set_date()].
#' @param install_rpix If `TRUE`, install rpix into the project's environment,
#'   unless it has this version or a newer one. Its dependencies come from
#'   conda-forge, and rpix itself from R-universe until it's on conda-forge.
#' @param path The folder to set up. Defaults to the working directory.
#' @param activation_cache If `TRUE`, turn on Pixi's activation cache for the
#'   project.
#' @param platforms The platforms a new project supports, besides this
#'   computer's. Defaults to `"linux-64"`, `"osx-64"`, `"osx-arm64"` and
#'   `"win-64"`. To add platforms to an existing project, use
#'   [pixi_add_platform()].
#' @param ... Passed on to the IDE setup, e.g. `console = "arf"` for
#'   [use_pixi_vscode()], or `default_r = FALSE` for [use_pixi_positron()].
#' @returns The path to the project's manifest, invisibly.
#' @export
#' @examples
#' \dontrun{
#' use_pixi()
#' use_pixi(r_version = "4.5", ide = "positron")
#' use_pixi(ide = "vscode", console = "arf")
#' use_pixi(date = "2025-06-01")
#' }
use_pixi <- function(
  r_version = NULL,
  ide = NULL,
  init_if_missing = TRUE,
  install_rpix = TRUE,
  date = NULL,
  path = NULL,
  activation_cache = TRUE,
  platforms = NULL,
  ...
) {
  setup_ide <- list(
    rstudio = use_pixi_rstudio,
    positron = use_pixi_positron,
    vscode = use_pixi_vscode,
    emacs = use_pixi_emacs,
    neovim = use_pixi_neovim,
    zed = use_pixi_zed
  )
  if (!is.null(ide)) {
    ide <- match.arg(ide, names(setup_ide), several.ok = TRUE)
  }
  # The settings of the IDEs in `ide`, e.g. `console` for VS Code
  ide_args <- list(...)
  settings <- unlist(lapply(setup_ide[ide], function(f) names(formals(f))))
  given <- names(ide_args) %||% rep("", length(ide_args))
  if (!all(given %in% setdiff(settings, "path"))) {
    cli::cli_abort(c(
      "{.arg ...} takes named settings of the IDEs in {.arg ide}, such as {.code console = \"arf\"} for VS Code.",
      "i" = "See {.help rpix::use_pixi_ide}."
    ))
  }
  pixi_binary()
  dir <- normalizePath(path %||% getwd(), winslash = "/", mustWork = FALSE)

  manifest <- manifest_in(dir) %||% parent_project(dir)
  if (is.null(manifest)) {
    if (!init_if_missing) {
      cli::cli_abort(c(
        "There's no Pixi project in {.path {dir}}.",
        "i" = "Create one with {.code use_pixi()} or {.code pixi init}."
      ))
    }
    run_pixi(c("init", dir), project = "none", echo = TRUE)
    manifest <- manifest_in(dir)
    # Added after `pixi init`, which adds this computer's platform
    run_pixi(
      c(
        "workspace",
        "platform",
        "add",
        platforms %||% common_platforms,
        "--no-install"
      ),
      path = dir,
      echo = TRUE
    )
  }
  path <- dirname(manifest)
  build_ignore(path, pixi_files(path))
  if (!is.null(date)) {
    value <- exclude_newer_value(date)
    lines <- readLines(manifest, warn = FALSE)
    writeLines(set_exclude_newer(lines, value), manifest)
    cli::cli_alert_success(
      "Using packages as they were on {.val {value}} ({.code exclude-newer})."
    )
  }

  r_base <- if (is.null(r_version)) "r-base" else paste0("r-base=", r_version)
  # conda-forge's R puts the user library of a regular R install first on
  # .libPaths() (https://github.com/conda-forge/r-base-feedstock/issues/37).
  # This package's activation script points R_LIBS_USER at nothing instead.
  isolation <- isolation_package
  # Added together with R, so Pixi picks the newest R they're all built for.
  # A new R comes out on conda-forge before its packages are rebuilt for it.
  r_packages <- unique(c(
    if (install_rpix) rpix_dependencies(),
    if (any(c("vscode", "emacs", "neovim", "zed") %in% ide)) {
      "r-languageserver"
    },
    if ("vscode" %in% ide) sess_dependencies
  ))
  # Without any, r-cli stands in for them, and is removed afterwards, unless
  # the project has it
  probe <- if (length(r_packages) == 0 && !has_dependency("r-cli", path)) {
    "r-cli"
  }
  packages <- c(r_base, isolation, r_packages, probe)
  # Only the ones it doesn't have, e.g. when use_pixi() runs again
  packages <- packages[!has_dependency(packages, path)]
  if (length(probe) > 0) {
    cli::cli_alert_info(
      "Adding {.pkg r-cli} with R, so Pixi picks an R that conda-forge has R packages for, then removing it."
    )
  }
  caller <- environment()
  if (length(packages) > 0) {
    tryCatch(
      run_pixi(
        c("add", if (length(probe) > 0) "--no-install", packages),
        path = path,
        echo = TRUE
      ),
      rpix_error_pixi = function(e) {
        abort_r_without_packages(e, r_version, call = caller)
      }
    )
  }
  if (length(probe) > 0) {
    run_pixi(c("remove", probe), path = path, echo = TRUE)
  }

  if (install_rpix) {
    install_rpix_into(path)
  }

  remove_legacy_rprofile(file.path(path, ".Rprofile"))
  warn_legacy_rprofile(file.path(home_dir(), ".Rprofile"))
  add_rprofile_block(file.path(path, ".Rprofile"))
  if (activation_cache) {
    use_activation_cache(path)
  }

  for (i in ide) {
    args <- ide_args[intersect(names(ide_args), names(formals(setup_ide[[i]])))]
    do.call(setup_ide[[i]], c(list(path), args))
  }

  cli::cli_alert_success("Set up {.path {path}} for R.")
  if (is.null(ide)) {
    cli::cli_alert_info(
      "Start R from the project's environment, e.g. with {.code pixi run R}, or set up your IDE with {.code use_pixi(ide = ...)}."
    )
  }
  invisible(manifest)
}

# When Pixi can't add R packages for the R asked for, as it's newer than
# conda-forge has them for, say so plainly. Other errors go on as they are.
abort_r_without_packages <- function(e, r_version, call) {
  unbuilt <- not_built_for_r(e$stderr)
  r_version <- r_version %||% ""
  asked <- regmatches(r_version, regexpr("^[0-9]+\\.[0-9]+", r_version))
  if (
    is.null(unbuilt) ||
      length(asked) == 0 ||
      package_version(asked) <= package_version(unbuilt$r_version)
  ) {
    stop(e)
  }
  cli::cli_abort(
    c(
      "conda-forge has no R packages for R {asked} yet; R {unbuilt$r_version} is the newest you can use.",
      "i" = "Use it with {.code use_pixi(r_version = \"{unbuilt$r_version}\")}."
    ),
    class = "rpix_error_r_version",
    parent = e,
    call = call
  )
}

# Install rpix into the default environment, unless it has this version or a
# newer one. From inside the environment's R, so rpix is installed for that R.
# Its dependencies are already there, from conda-forge.
install_rpix_into <- function(path) {
  installed <- file.path(
    path,
    ".pixi",
    "envs",
    "default",
    "lib",
    "R",
    "library",
    "rpix",
    "DESCRIPTION"
  )
  version <- utils::packageVersion("rpix")
  if (
    file.exists(installed) &&
      package_version(read.dcf(installed, "Version")[1, 1]) >= version
  ) {
    cli::cli_alert_success("The environment has rpix {version} already.")
    return(invisible(FALSE))
  }
  # A failed install is only a warning, which would let Rscript succeed
  install <- paste0(
    "options(warn = 2); ",
    "utils::install.packages('rpix', repos = 'https://roaldarbol.r-universe.dev', ",
    "lib = .Library, dependencies = FALSE, type = 'source')"
  )
  run_pixi_step(
    c("run", "Rscript", "-e", install),
    step = "Installing rpix into the environment from R-universe",
    done = "Installed rpix into the environment from R-universe",
    path = path
  )
  invisible(TRUE)
}

# The manifest of a Pixi project in a parent folder of `dir`, if the user
# would rather set that one up. use_pixi() sets up `dir` otherwise.
parent_project <- function(dir) {
  manifest <- find_manifest(dirname(dir))
  if (is.null(manifest)) {
    return(NULL)
  }
  root <- dirname(manifest)
  if (is_interactive()) {
    question <- cli::format_inline(
      "{.path {root}} is a Pixi project. Set that one up, rather than {.path {dir}}?"
    )
    if (isTRUE(ask_yes_no(question))) {
      return(manifest)
    }
  } else {
    command <- paste0("use_pixi(path = ", deparse(root), ")")
    cli::cli_alert_info(
      "{.path {root}} is a Pixi project too. To set that one up instead, run {.code {command}}."
    )
  }
  NULL
}

# rpix's own dependencies, as conda packages. Reads rpix's DESCRIPTION through
# its namespace path, which also works under devtools::load_all().
rpix_dependencies <- function(imports = rpix_imports()) {
  imports <- trimws(strsplit(imports, ",", fixed = TRUE)[[1]])
  imports <- sub("[[:space:]]*\\(.*$", "", imports)
  parse_packages(imports)$name
}

# Which of the packages the project's default feature has already
has_dependency <- function(packages, path) {
  manifest <- find_manifest(path)
  lines <- if (!is.null(manifest)) readLines(manifest, warn = FALSE)
  rows <- c(
    table_lines(lines, "dependencies"),
    table_lines(lines, "tool.pixi.dependencies")
  )
  names <- sub('^\\s*"?([^"=[:space:]]+)"?\\s*=.*$', "\\1", lines[rows])
  packages %in% names
}

# Turn on Pixi's activation cache in the project's .pixi/config.toml. Without
# it, every start of R through Pixi runs the activation scripts, and
# conda-forge's r-base one takes seconds (`R CMD javareconf`). Pixi versions
# that don't know the setting fail, which only costs the speed-up.
use_activation_cache <- function(path) {
  set <- c(
    "config",
    "set",
    "--local",
    "experimental.use-environment-activation-cache",
    "true"
  )
  done <- tryCatch(
    {
      run_pixi(set, path = path)
      TRUE
    },
    rpix_error_pixi = function(e) FALSE
  )
  if (done) {
    cli::cli_alert_success(
      "Turned on Pixi's activation cache in {.file .pixi/config.toml}, so R starts faster through Pixi."
    )
  } else {
    cli::cli_alert_info(
      "Couldn't turn on Pixi's activation cache, so R can take a few seconds to start through Pixi. A newer Pixi has it."
    )
  }
  invisible(done)
}

rpix_imports <- function() {
  path <- getNamespaceInfo("rpix", "path")
  unname(read.dcf(file.path(path, "DESCRIPTION"), fields = "Imports")[1, 1])
}

# The block use_pixi() adds to the project's .Rprofile
rprofile_block <- c(
  "# >>> rpix >>>",
  "# Activates the project's Pixi environment when an IDE starts R directly.",
  "# See https://roald-arboel.com/rpix/articles/how-rpix-works.html",
  "local({",
  "  # In the environment's R, drop the personal library before any package",
  "  # loads: it has packages built for another R, which can crash this one",
  "  home <- normalizePath(R.home(), winslash = \"/\")",
  "  pixi <- grepl(\"/[.]pixi/envs/[^/]+/lib/R$\", home)",
  "  if (pixi) {",
  "    personal <- strsplit(Sys.getenv(\"R_LIBS_USER\"), .Platform$path.sep)[[1]]",
  "    personal <- normalizePath(personal, winslash = \"/\", mustWork = FALSE)",
  "    personal <- personal[!grepl(\"/[.]pixi/\", personal)]",
  "    .libPaths(setdiff(.libPaths(), personal))",
  "  }",
  "  if (requireNamespace(\"rpix\", quietly = TRUE)) {",
  "    if (\"pixi_activate\" %in% getNamespaceExports(\"rpix\")) {",
  "      rpix::pixi_activate()",
  "    }",
  "  } else if (pixi && interactive()) {",
  "    # rpix isn't in pixi.lock, e.g. for a collaborator, or in other environments",
  "    message(",
  "      \"This Pixi environment's R doesn't have rpix. To install it, run:\\n\",",
  "      \"install.packages('rpix', repos = 'https://roaldarbol.r-universe.dev', \",",
  "      \"lib = .Library, dependencies = FALSE, type = 'source')\"",
  "    )",
  "  }",
  "})",
  "# <<< rpix <<<"
)

#' Add rpix's block to `.Rprofile`, or update it if it's there
#' @noRd
add_rprofile_block <- function(file) {
  lines <- if (file.exists(file)) readLines(file, warn = FALSE) else character()
  start <- match(rprofile_block[1], lines)
  end <- match(rprofile_block[length(rprofile_block)], lines)

  if (!is.na(start) && !is.na(end) && end > start) {
    lines <- c(
      lines[seq_len(start - 1)],
      rprofile_block,
      lines[-seq_len(end)]
    )
  } else {
    lines <- c(lines, if (length(lines) > 0) "", rprofile_block)
  }
  writeLines(lines, file)
  invisible(file)
}

legacy_marker <- "# Pixi R library setup"

#' Remove the `.Rprofile` block written by rpix 0.3.0 and earlier
#'
#' It pointed the running R at the Pixi library. Finds the `local({...})`
#' block after the marker comment by counting braces.
#' @returns `TRUE` if a block was removed, invisibly.
#' @noRd
remove_legacy_rprofile <- function(file) {
  if (!file.exists(file)) {
    return(invisible(FALSE))
  }
  lines <- readLines(file, warn = FALSE)
  start <- which(lines == legacy_marker)
  if (length(start) == 0) {
    return(invisible(FALSE))
  }
  start <- start[1]

  depth <- 0
  end <- NA
  for (i in seq(start + 1, length(lines))) {
    depth <- depth + count_char(lines[i], "{") - count_char(lines[i], "}")
    if (depth == 0 && grepl("}", lines[i], fixed = TRUE)) {
      end <- i
      break
    }
  }
  if (is.na(end)) {
    cli::cli_warn(
      "Found the old Pixi setup in {.path {file}}, but couldn't find where it ends. Remove it by hand."
    )
    return(invisible(FALSE))
  }

  writeLines(lines[-(start:end)], file)
  cli::cli_alert_success(
    "Removed the old Pixi library setup from {.path {file}}."
  )
  invisible(TRUE)
}

# rpix doesn't edit the global .Rprofile, but the old block there affects every
# project
warn_legacy_rprofile <- function(file) {
  if (file.exists(file) && legacy_marker %in% readLines(file, warn = FALSE)) {
    cli::cli_warn(c(
      "{.path {file}} still has the Pixi library setup from rpix 0.3.0 or earlier.",
      "i" = "It can crash R, so remove the {.code {legacy_marker}} block."
    ))
  }
}

count_char <- function(x, char) {
  lengths(regmatches(x, gregexpr(char, x, fixed = TRUE)))
}

# The platforms of a new project, and of the rstudio task: those most people
# work on
common_platforms <- c("linux-64", "osx-64", "osx-arm64", "win-64")

# conda-forge's package that keeps the personal R library out of an
# environment's R (https://github.com/conda-forge/r-base-feedstock/issues/37)
isolation_package <- "conda-ecosystem-user-package-isolation"
