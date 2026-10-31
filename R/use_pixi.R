#' Set up a Pixi project for R
#'
#' @description
#' Create a Pixi project in the working directory, or `path`, if there isn't
#' one there, and install R and rpix into its environment.
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
#' In a project that uses renv (with a `renv.lock`), it offers to move the
#' packages over with [pixi_import_renv()] first, which also turns renv off.
#' renv keeps rpix out of the project's own R, so run `use_pixi(path = )` from
#' another R session, e.g. your usual R outside the project.
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
#'   `"positron"`, `"vscode"`, `"emacs"`, `"neovim"` and `"zed"` (see
#'   [use_pixi_ide]), and `"jupyter"` (see [use_pixi_jupyter()],
#'   experimental).
#' @param init_if_missing If `TRUE`, create a Pixi project if there isn't one.
#' @param date Optional. Use packages as they were on this date, such as
#'   `"2025-06-01"`, e.g. to rerun an old analysis. Set before anything is
#'   added, so R and the packages are all as of that date. See
#'   [pixi_set_date()].
#' @param install_rpix If `TRUE`, add rpix to the project (`r-rpix`), so it's
#'   in `pixi.lock` like the other packages, and a collaborator's environment
#'   has it too. Until rpix is on conda-forge, it comes from the
#'   [rpix-forge](https://prefix.dev/channels/rpix-forge) channel, which is
#'   added to the project's channels after conda-forge, so everything else
#'   still comes from conda-forge.
#' @param path The folder to set up. Defaults to the working directory.
#' @param activation_cache If `TRUE`, turn on Pixi's activation cache for the
#'   project.
#' @param platforms The platforms a new project supports, besides this
#'   computer's. Defaults to `"linux-64"`, `"osx-64"`, `"osx-arm64"` and
#'   `"win-64"`. To add platforms to an existing project, use
#'   [pixi_add_platform()].
#' @param python If `TRUE`, add Python for reticulate, with
#'   [use_pixi_python()] (experimental).
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
  python = FALSE,
  ...
) {
  setup_ide <- list(
    rstudio = use_pixi_rstudio,
    positron = use_pixi_positron,
    vscode = use_pixi_vscode,
    emacs = use_pixi_emacs,
    neovim = use_pixi_neovim,
    zed = use_pixi_zed,
    jupyter = use_pixi_jupyter
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
        "i" = "Create one with {.code rpix::use_pixi()} or {.code pixi init}."
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

  offer_renv_import(path)

  r_base <- if (is.null(r_version)) "r-base" else paste0("r-base=", r_version)
  # conda-forge's R puts the user library of a regular R install first on
  # .libPaths() (https://github.com/conda-forge/r-base-feedstock/issues/37).
  # This package's activation script points R_LIBS_USER at nothing instead.
  isolation <- isolation_package
  # Added together with R, so Pixi picks the newest R they're all built for.
  # A new R comes out on conda-forge before its packages are rebuilt for it.
  r_packages <- c(
    if (install_rpix) "r-rpix",
    if (any(c("vscode", "emacs", "neovim", "zed") %in% ide)) {
      "r-languageserver"
    },
    if ("vscode" %in% ide) vscode_r_packages
  )
  if (install_rpix || "vscode" %in% ide) {
    use_rpix_forge(path)
  }
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
        newest <- r_without_packages(e, r_version)
        if (is.null(newest)) {
          stop(e)
        }
        if (!offer_newest_r(newest)) {
          abort_r_without_packages(e, newest, call = caller)
        }
        packages[packages == r_base] <- paste0("r-base=", newest$r_version)
        run_pixi(
          c("add", if (length(probe) > 0) "--no-install", packages),
          path = path,
          echo = TRUE
        )
      }
    )
  }
  if (length(probe) > 0) {
    run_pixi(c("remove", probe), path = path, echo = TRUE)
  }

  remove_legacy_rprofile(file.path(path, ".Rprofile"))
  warn_legacy_rprofile(file.path(home_dir(), ".Rprofile"))
  add_rprofile_block(file.path(path, ".Rprofile"))
  if (activation_cache) {
    use_activation_cache(path)
  }

  if (isTRUE(python)) {
    use_pixi_python(path = path)
  }
  for (i in ide) {
    args <- ide_args[intersect(names(ide_args), names(formals(setup_ide[[i]])))]
    do.call(setup_ide[[i]], c(list(path), args))
  }

  cli::cli_alert_success("Set up {.path {path}} for R.")
  if (is.null(ide)) {
    cli::cli_alert_info(
      "Start R from the project's environment, e.g. with {.code pixi run R}, or set up your IDE with {.code rpix::use_pixi(ide = ...)}."
    )
  }
  invisible(manifest)
}

# A project that uses renv: offer to move its packages over first, as
# pixi_import_renv() also adds the lock file's R (#252). Not when the project
# has R already, e.g. when use_pixi() runs again.
offer_renv_import <- function(path) {
  if (
    !file.exists(file.path(path, "renv.lock")) ||
      has_dependency("r-base", path)
  ) {
    return(invisible(FALSE))
  }
  cli::cli_alert_info("This project uses renv ({.file renv.lock}).")
  if (
    !is_interactive() ||
      !isTRUE(ask_yes_no(
        "Would you like to move its packages to Pixi, and turn renv off?"
      ))
  ) {
    cli::cli_alert_info(
      "Move them with {.code rpix::pixi_import_renv()}, which also turns renv off."
    )
    return(invisible(FALSE))
  }
  pixi_import_renv(path = path)
  invisible(TRUE)
}

# When Pixi can't add R packages for the R asked for, as it's newer than
# conda-forge has them for, say so plainly. Other errors go on as they are.
# The R asked for, and the newest R conda-forge has packages for, when Pixi
# failed for that reason; otherwise NULL
r_without_packages <- function(e, r_version) {
  unbuilt <- not_built_for_r(e$stderr)
  r_version <- r_version %||% ""
  asked <- regmatches(r_version, regexpr("^[0-9]+\\.[0-9]+", r_version))
  if (
    is.null(unbuilt) ||
      length(asked) == 0 ||
      package_version(asked) <= package_version(unbuilt$r_version)
  ) {
    return(NULL)
  }
  list(asked = asked, r_version = unbuilt$r_version)
}

offer_newest_r <- function(newest) {
  if (!is_interactive()) {
    return(FALSE)
  }
  cli::cli_alert_warning(
    "conda-forge has no R packages for R {newest$asked} yet; R {newest$r_version} is the newest you can use."
  )
  ask_yes_no(paste0("Would you like to use R ", newest$r_version, " instead?"))
}

abort_r_without_packages <- function(e, newest, call) {
  asked <- newest$asked
  unbuilt <- newest
  cli::cli_abort(
    c(
      "conda-forge has no R packages for R {asked} yet; R {unbuilt$r_version} is the newest you can use.",
      "i" = "Use it with {.code rpix::use_pixi(r_version = \"{unbuilt$r_version}\")}."
    ),
    class = "rpix_error_r_version",
    parent = e,
    call = call
  )
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
    command <- paste0("rpix::use_pixi(path = ", deparse(root), ")")
    cli::cli_alert_info(
      "{.path {root}} is a Pixi project too. To set that one up instead, run {.code {command}}."
    )
  }
  NULL
}

# rpix, and the packages VS Code's R extension uses (r-sess, r-jgd), aren't on
# conda-forge yet (conda-forge/staged-recipes#35133, #35105, #35104). Until
# they are, they come from this channel, built from the same recipes against
# conda-forge's R. It's added after conda-forge, so Pixi takes everything else
# from conda-forge, and these too once they're there.
rpix_forge <- "https://prefix.dev/roaldarbol/rpix-forge"

# Add rpix_forge to the project's channels, unless it's there
use_rpix_forge <- function(path) {
  manifest <- find_manifest(path)
  lines <- if (!is.null(manifest)) readLines(manifest, warn = FALSE)
  if (!any(grepl(rpix_forge, lines, fixed = TRUE))) {
    run_pixi(
      c("workspace", "channel", "add", rpix_forge, "--no-install"),
      path = path,
      echo = TRUE
    )
  }
  invisible()
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
  "    # e.g. an environment without r-rpix, or a project set up by an earlier rpix",
  "    message(",
  "      \"This Pixi environment's R doesn't have rpix. To add it, run in a terminal:\\n\",",
  "      \"pixi workspace channel add https://prefix.dev/roaldarbol/rpix-forge\\n\",",
  "      \"pixi add r-rpix\"",
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
