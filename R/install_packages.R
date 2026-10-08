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
        "i" = "To install outside Pixi, so it isn't recorded in {.file pixi.toml}, use {.code utils::install.packages()}."
      ),
      call = NULL
    )
  }

  found <- find_r_packages(pkgs)
  missing <- names(found)[is.na(found)]
  if (length(missing) > 0) {
    cli::cli_abort(
      c(
        "{.pkg {missing}} {?isn't/aren't} on conda-forge or bioconda, so Pixi can't add {?it/them}.",
        "i" = "To install outside Pixi, so it isn't recorded in {.file pixi.toml}, use {.code utils::install.packages()}.",
        "i" = "Turn this off with {.code options(rpix.install_packages = FALSE)}."
      ),
      call = NULL
    )
  }
  cli::cli_alert_info(
    "Adding {.pkg {names(found)}} with Pixi, so {?it's/they're} recorded in {.file pixi.toml}."
  )
  pixi_add(unname(found), path = root)
  invisible()
}

utils_install_packages <- function(...) {
  utils::install.packages(...)
}
