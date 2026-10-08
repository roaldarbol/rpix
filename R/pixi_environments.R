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
#' For more information, see <https://pixi.sh/latest/workspace/multi_environment/>.
#'
#' @param name The environment's name.
#' @param features The features it's made of. They have to exist already, so
#'   add packages to them first with `pixi_add(feature = )`.
#' @param solve_group Optional. Environments in the same solve group get the
#'   same versions of the packages they share.
#' @param default_feature If `FALSE`, leave out the default feature. Needed
#'   when a feature conflicts with it, e.g. pins another version of R.
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
#' @examples
#' \dontrun{
#' # An environment with R 4.4, next to the default one. It leaves out the
#' # default feature, since that has another version of R.
#' pixi_add(c("r-base=4.4", "dplyr"), feature = "r44")
#' pixi_add_environment("r44", features = "r44", default_feature = FALSE)
#'
#' # An environment with the default packages plus testthat, on the same
#' # versions as the default environment
#' pixi_add("testthat", feature = "test")
#' pixi_add_environment("test", features = "test", solve_group = "default")
#' pixi_environments()
#' }
pixi_environments <- function(path = NULL) {
  envs <- run_pixi("info", path = path, json = TRUE)$environments_info
  platforms <- lapply(envs$platforms, function(p) p$name)
  data.frame(
    name = envs$name,
    features = I(envs$features),
    platforms = I(platforms),
    solve_group = as.character(envs$solve_group %||% rep(NA, nrow(envs))),
    stringsAsFactors = FALSE
  )
}

#' @rdname pixi_environments
#' @export
pixi_add_environment <- function(
  name,
  features = NULL,
  solve_group = NULL,
  default_feature = TRUE,
  overwrite = FALSE,
  path = NULL,
  dry_run = FALSE
) {
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
  run_pixi(args, path = path, echo = TRUE, dry_run = dry_run)
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

#' Add channels or platforms to the project
#'
#' @description
#' * `pixi_add_channel()` adds conda channels, which packages are installed
#'   from. [pixi_add()] adds the ones it needs itself.
#' * `pixi_add_platform()` adds platforms, such as `"linux-64"`, `"osx-arm64"`
#'   or `"win-64"`, so `pixi.lock` covers them too and collaborators on them
#'   get the same packages.
#'
#' For more information, see
#' <https://pixi.sh/latest/reference/cli/pixi/workspace/channel/add/> and
#' <https://pixi.sh/latest/reference/cli/pixi/workspace/platform/add/>.
#'
#' @param channels Channel names, such as `"bioconda"`, or URLs.
#' @param platforms Platform names.
#' @inheritParams pixi_environments
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result
#'   of the Pixi call (invisibly).
#' @export
#' @examples
#' \dontrun{
#' pixi_add_channel("bioconda")
#' pixi_add_platform(c("linux-64", "osx-arm64", "win-64"))
#' }
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
