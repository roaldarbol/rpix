# In a Pixi environment's R, install.packages() adds packages with Pixi, so
# they're recorded in pixi.toml and pixi.lock. pixi_activate() attaches it.

# Attach rpix's install.packages() in front of utils' one. During R's startup
# utils isn't attached yet, and attaching it later would put it in front, so
# then it waits for utils.
attach_install_packages <- function(root, now = "package:utils" %in% search()) {
  if (!now) {
    setHook(
      packageEvent("utils", "attach"),
      function(...) attach_install_packages(root, now = TRUE)
    )
    return(invisible(FALSE))
  }
  if ("rpix:install" %in% search()) {
    detach("rpix:install", character.only = TRUE)
  }
  shims <- new.env()
  shims$install.packages <- function(pkgs, ...) {
    install_with_pixi(pkgs, ..., root = root)
  }
  # attach() rather than a package, so it only masks install.packages() in
  # a Pixi environment's R. Fetched from base to keep R CMD check's attach()
  # note away; it's attached on purpose.
  attach_env <- get("attach", envir = baseenv())
  attach_env(shims, name = "rpix:install", warn.conflicts = FALSE)
  invisible(TRUE)
}

install_with_pixi <- function(pkgs, ..., root) {
  if (isFALSE(getOption("rpix.install_packages"))) {
    return(utils_install_packages(pkgs, ...))
  }
  extra <- names(list(...))
  extra <- setdiff(extra[nzchar(extra)], c("dependencies", "quiet", "Ncpus"))
  files <- grepl("[/\\\\]|\\.(tar\\.gz|tgz|zip)$", pkgs)
  if (length(extra) > 0 || any(files)) {
    unusable <- c(
      if (length(extra) > 0) paste0("`", extra, "`"),
      if (any(files)) "package files"
    )
    cli::cli_abort(
      c(
        "In a Pixi environment, {.fn install.packages} adds packages with Pixi, which can't use {unusable}.",
        "i" = "Give package names, e.g. {.code install.packages(\"dplyr\")}.",
        "i" = "For a package that isn't on conda-forge, Pixi can build it from source: {.code pixi_add(\"github::user/repo\")}."
      ),
      call = NULL
    )
  }

  # Pixi only says it's already a dependency, which doesn't update it
  listed <- listed_packages(pkgs, root)
  if (length(listed) > 0) {
    update <- paste0("pixi_update(", deparse1(unname(listed)), ")")
    cli::cli_alert_info(
      "{.pkg {names(listed)}} {?is/are} already in {.file pixi.toml}. To update {?it/them}, run {.code {update}}."
    )
    pkgs <- setdiff(pkgs, names(listed))
    if (length(pkgs) == 0) {
      return(invisible())
    }
  }

  found <- find_r_packages(pkgs)
  cli::cli_alert_info(
    "Adding {.pkg {names(found)}} with Pixi, so {?it's/they're} recorded in {.file pixi.toml}."
  )
  # Packages that aren't on conda-forge or bioconda go to pixi_add() as CRAN
  # packages, so it offers to build them from CRAN's source
  missing <- is.na(found)
  pixi_add(
    c(
      unname(found[!missing]),
      if (any(missing)) paste0("cran::", names(found)[missing])
    ),
    path = root
  )
  invisible()
}

# The packages pixi.toml lists for the environment R runs in, as references
# for pixi_update(), named by package
listed_packages <- function(pkgs, root) {
  dependencies <- tryCatch(environment_dependencies(root), error = function(e) {
    NULL
  })
  environment <- pixi_r_location(r_home())$name %||% "default"
  dependencies <- as.character(unlist(dependencies[[environment]]))
  dependencies <- dependencies[grepl("^(r|bioconductor)-", dependencies)]
  conda <- dependencies[match(tolower(pkgs), r_names(dependencies))]
  listed <- !is.na(conda)
  references <- ifelse(
    startsWith(conda[listed], "bioconductor-"),
    paste0("bioc::", pkgs[listed]),
    pkgs[listed]
  )
  stats::setNames(references, pkgs[listed])
}

utils_install_packages <- function(...) {
  utils::install.packages(...)
}
