#' Add dependencies

#' @description
#' `add()` will add dependencies to the pixi.toml.
#'
#' For more information, see https://pixi.sh/latest/reference/cli/pixi/add/.
#'
#' It will only add if the package with its version constraint is able to work
#' with rest of the dependencies in the project. More info on
#' [multi-platform](https://pixi.sh/advanced/multi_platform_configuration/)
#' configuration.
#'
#' @param packages Package name(s) to be added.
#' @param versions Optional. Version constraints for all packages.
#' @param channel Optional. Defaults to conda-forge, but other conda channels can be specified.
#' @param dry_run Should the command be executed? If TRUE, the final pixi command will be shown but not executed. FALSE (default) executes the command.
#' @returns The command (invisibly) if `dry_run = TRUE`, otherwise the result of
#'   the pixi call (invisibly).
#' @import cli
#' @export add
#' @examples
#' \dontrun{
#' add("tibble")
#' }

add <- function(packages, versions = NULL, channel = NULL, dry_run = FALSE) {
  specs <- paste0("r-", packages)

  # Append version constraints, adding `=` if no operator is given
  if (!is.null(versions)) {
    versions <- sub("^(?![=<>~^!])", "=", versions, perl = TRUE)
    specs <- paste0(specs, versions)
  }

  args <- c("add", specs)
  if (!is.null(channel)) {
    args <- c(args, "--channel", channel)
  }

  run_pixi(args, echo = TRUE, dry_run = dry_run)
}
