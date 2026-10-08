# Extracted from test-print.R:130

# prequel ----------------------------------------------------------------------
tasks_df <- function() {
  new_rpix_df(
    data.frame(
      name = c("test", "render", "check", "inline"),
      command = c(
        "Rscript -e 'devtools::test()'",
        "quarto render {{ file }}",
        "R CMD check",
        NA
      ),
      description = c(
        "Run the tests",
        NA,
        "Check the package, with a description long enough to wrap onto a second line of the console",
        NA
      ),
      feature = c("default", "default", "r44", NA),
      environments = I(list(
        c("default", "r44"),
        c("default", "r44"),
        "r44",
        "r44"
      )),
      depends_on = I(list(character(), "test", character(), "test")),
      args = I(list(character(), "file", character(), character())),
      stringsAsFactors = FALSE
    ),
    "rpix_tasks"
  )
}
packages_df <- function(n) {
  names <- sprintf("r-pkg%02d", seq_len(n))
  new_rpix_df(
    data.frame(
      name = names,
      version = rep("1.0", n),
      r_package = sub("r-", "", names),
      explicit = seq_len(n) %% 2 == 1,
      channel = rep("conda-forge", n),
      kind = rep("conda", n),
      build = rep("h0", n),
      stringsAsFactors = FALSE
    ),
    "rpix_packages",
    environment = "r44"
  )
}

# test -------------------------------------------------------------------------
local_mocked_bindings(
    run_pixi = function(args, ...) list(version = "0.81.0")
  )
