# Extracted from test-pixi_info.R:73

# prequel ----------------------------------------------------------------------
fake_list <- function() {
  data.frame(
    name = c("r-rcpp", "r-base", "bioconductor-deseq2", "gdal", "requests"),
    version = c("1.0.14", "4.5.3", "1.48.0", "3.11.0", "2.32.3"),
    build = c("r45h", "h1", "r45h", "h2", "pypi_0"),
    build_number = c(0L, 1L, 0L, 0L, 0L),
    source = c(
      rep("https://conda.anaconda.org/conda-forge", 4),
      "https://pypi.org"
    ),
    kind = c("conda", "conda", "conda", "conda", "pypi"),
    is_explicit = c(TRUE, TRUE, FALSE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )
}

# test -------------------------------------------------------------------------
calls <- list()
local_mocked_bindings(run_pixi = function(args, ...) {
    calls[[length(calls) + 1]] <<- args
    list(stdout = "r-cli 3.6.6\n<e2><94><94><e2><94><80><e2><94><80> r-base 4.5.3\n")
  })
