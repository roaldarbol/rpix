# How many CRAN and Bioconductor packages Pixi and rpix can install, for the
# article "How many packages you can use". Writes
# vignettes/articles/package-availability.json, which the article reads.
#
# Run from the repository root, optionally with a platform (default osx-64):
#
#   pixi run availability            # or: pixi run availability linux-64
#   Rscript data-raw/package-availability.R linux-64
#
# Needs R with jsonlite, and Pixi on the PATH. Takes under a minute, and
# downloads about 50 MB: CRAN's package database (12 MB), conda-forge's and
# bioconda's channeldata.json (35 MB), Posit's r-system-requirements rules,
# Bioconductor's package lists, and whatever repodata Pixi needs to solve an
# r-base environment (nothing is installed: `pixi add --no-install`).
#
# Downloads go to a temporary directory. To keep them between runs, set
# AVAILABILITY_CACHE=data-raw/cache (ignored by git and R CMD build); delete it
# to fetch fresh data. Only the small JSON is committed.

platform <- commandArgs(trailingOnly = TRUE)[1]
if (is.na(platform)) {
  platform <- "osx-64"
}
cache <- Sys.getenv("AVAILABILITY_CACHE", tempfile("availability-"))
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
out <- "vignettes/articles/package-availability.json"
options(
  timeout = 600,
  repos = c(CRAN = "https://cloud.r-project.org"),
  # Bioconductor refuses some default user agents
  HTTPUserAgent = "rpix package-availability (https://github.com/roaldarbol/rpix)"
)

fetch <- function(url, file) {
  path <- file.path(cache, file)
  if (!file.exists(path)) {
    download.file(url, path, mode = "wb", quiet = TRUE)
  }
  path
}
share <- function(x, n) round(x / n, 4)
log_step <- function(...) message(format(Sys.time(), "%H:%M:%S "), ...)

# CRAN -------------------------------------------------------------------------

log_step("CRAN's package database")
db_file <- file.path(cache, "cran.rds")
if (!file.exists(db_file)) {
  saveRDS(tools::CRAN_package_db(), db_file)
}
db <- readRDS(db_file)
db <- db[!duplicated(db$Package), ]
pkg <- db$Package
n <- length(pkg)

base <- rownames(installed.packages(priority = "base"))
recommended <- c(
  "KernSmooth",
  "MASS",
  "Matrix",
  "boot",
  "class",
  "cluster",
  "codetools",
  "foreign",
  "lattice",
  "mgcv",
  "nlme",
  "nnet",
  "rpart",
  "spatial",
  "survival"
)
fdeps <- tools::package_dependencies(
  pkg,
  db = db,
  which = c("Depends", "Imports", "LinkingTo")
)
dep_name <- unlist(fdeps, use.names = FALSE)
dep_pkg <- rep(seq_len(n), lengths(fdeps))
# TRUE for packages whose hard dependencies are all in `have` (lower case)
deps_in <- function(have) {
  tabulate(dep_pkg[!tolower(dep_name) %in% have], nbins = n) == 0
}

# conda-forge and bioconda ----------------------------------------------------

log_step("conda-forge's and bioconda's channeldata")
# Each package's latest version, and the platforms it has ever been built for
channel <- function(name) {
  cd <- jsonlite::fromJSON(
    fetch(
      sprintf("https://conda.anaconda.org/%s/channeldata.json", name),
      paste0(name, ".json")
    ),
    simplifyVector = FALSE
  )$packages
  data.frame(
    name = names(cd),
    version = vapply(cd, function(p) p$version %||% NA_character_, ""),
    here = vapply(
      cd,
      function(p) any(c(platform, "noarch") %in% unlist(p$subdirs)),
      TRUE
    )
  )
}
cf <- channel("conda-forge")
cf <- cf[startsWith(cf$name, "r-") & cf$here, ]
cf$pkg <- sub("^r-", "", cf$name)
bc <- channel("bioconda")
bc <- bc[startsWith(bc$name, "bioconductor-"), ]
bc$pkg <- sub("^bioconductor-", "", bc$name)

on_cf <- tolower(pkg) %in% cf$pkg

# Bioconductor ----------------------------------------------------------------

log_step("Bioconductor")
config <- readLines(fetch("https://bioconductor.org/config.yaml", "bioc.yaml"))
yaml_value <- function(key) {
  sub(
    ".*: *\"?([^\"]*)\"?$",
    "\\1",
    grep(paste0("^", key, ":"), config, value = TRUE)
  )
}
release <- yaml_value("release_version")
# The r_ver_for_bioc_ver block: lines like `  "3.22": "4.5"`
block <- config[-seq_len(grep("^r_ver_for_bioc_ver:", config))]
block <- block[seq_len(
  match(TRUE, !grepl("^\\s", block), length(block) + 1) - 1
)]
r_for_bioc <- setNames(
  sub(".*: *\"([^\"]+)\".*", "\\1", block),
  sub("^\\s*\"([^\"]+)\".*", "\\1", block)
)
bioc_packages <- function(version) {
  url <- sprintf(
    "https://bioconductor.org/packages/%s/bioc/src/contrib/PACKAGES",
    version
  )
  as.data.frame(read.dcf(
    fetch(url, paste0("bioc-", version, ".PACKAGES")),
    fields = c("Package", "Version")
  ))
}
# The release bioconda has: the newest one for which most software packages
# are on bioconda at that release's version
older <- names(r_for_bioc)[
  numeric_version(names(r_for_bioc)) <= numeric_version(release)
]
older <- head(older[order(numeric_version(older), decreasing = TRUE)], 4)
for (bioconda_release in older) {
  bp <- bioc_packages(bioconda_release)
  latest <- bc$version[match(tolower(bp$Package), bc$pkg)]
  at_version <- !is.na(latest) & latest == bp$Version
  if (mean(at_version) > 0.5) break
}
stopifnot(mean(at_version) > 0.5)
bp_here <- tolower(bp$Package) %in% bc$pkg[bc$here]
# Some are already at the next release's version
bp_current <- bp_here &
  package_version(latest, strict = FALSE) >= package_version(bp$Version)
release_software <- nrow(bioc_packages(release))

# What conda-forge's R brings -------------------------------------------------

log_step("Solving an r-base environment (without installing it)")
pixi <- Sys.which("pixi")
r_version <- r_for_bioc[[bioconda_release]]
project <- tempfile("r-base-")
dir.create(project)
manifest <- file.path(project, "pixi.toml")
run_pixi <- function(...) {
  out <- system2(pixi, c(...), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(out, "status"))) {
    stop(paste(out, collapse = "\n"))
  }
  invisible(out)
}
run_pixi("init", "--platform", platform, shQuote(project))
run_pixi(
  "add",
  "--no-install",
  "--manifest-path",
  shQuote(manifest),
  shQuote(paste0("r-base=", r_version))
)
env <- jsonlite::fromJSON(paste(
  run_pixi(
    "list",
    "--json",
    "--no-install",
    "--manifest-path",
    shQuote(manifest)
  ),
  collapse = "\n"
))
pixi_version <- sub("^pixi ", "", run_pixi("--version"))

# SystemRequirements ----------------------------------------------------------

log_step("Posit's system requirement rules")
sha <- tryCatch(
  readLines(
    url(
      "https://api.github.com/repos/rstudio/r-system-requirements/commits/main",
      headers = c(Accept = "application/vnd.github.sha")
    ),
    warn = FALSE
  ),
  error = function(e) "main"
)
rules_dir <- tempfile("rules-")
untar(
  fetch(
    paste0(
      "https://codeload.github.com/rstudio/r-system-requirements/tar.gz/",
      sha
    ),
    paste0("rules-", sha, ".tar.gz")
  ),
  exdir = rules_dir
)
rule_files <- list.files(
  rules_dir,
  "\\.json$",
  recursive = TRUE,
  full.names = TRUE
)
rule_files <- rule_files[basename(dirname(rule_files)) == "rules"]
rules <- lapply(rule_files, function(f) unlist(jsonlite::fromJSON(f)$patterns))
names(rules) <- sub("\\.json$", "", basename(rule_files))

# A rule is provided when r-base's environment has the library (by name, or
# one of these aliases), or when it needs nothing: make, a tool rpix adds, or
# a tool only needed when the package runs
alias <- c(
  libjpeg = "libjpeg-turbo",
  libwebp = "libwebp-base",
  libbz2 = "bzip2",
  xz = "liblzma"
)
nothing <- c(
  "gnumake",
  "git",
  "rust",
  "java",
  "cmake",
  "pkg-config",
  "pandoc",
  "pandoc-citeproc",
  "python",
  "python3"
)
provided <- vapply(
  names(rules),
  function(r) {
    candidates <- c(r, paste0("lib", r), sub("^lib", "", r), alias[r])
    r %in% nothing || any(candidates %in% env$name)
  },
  TRUE
)

# Language standards, compilers, make, threads, and OpenMP, BLAS and LAPACK
# (which come with R) need nothing; if that's all the text says, the package
# needs nothing
noop <- paste(
  "c\\+\\+ ?(0x|11|14|17|20|23)",
  "\\bcxx ?(11|14|17|20|23)\\b",
  "\\bc(99|11|17|23)\\b",
  "\\bgnu\\b",
  "\\bg?make\\b",
  "posix threads",
  "pthreads?",
  "compilers?",
  "openmp",
  "\\bblas\\b",
  "\\blapack\\b",
  "\\b(and|or|the|for|a|optional|only|needed|version|with|later|higher)\\b",
  sep = "|"
)
sr <- db$SystemRequirements
texts <- unique(sr[!is.na(sr)])
hits <- vapply(
  rules,
  function(p) {
    Reduce(`|`, lapply(p, grepl, x = texts, ignore.case = TRUE, perl = TRUE))
  },
  logical(length(texts))
)
says_nothing <- !grepl(
  "[a-z]{2,}",
  gsub(noop, "", texts, ignore.case = TRUE, perl = TRUE),
  ignore.case = TRUE
)
status <- ifelse(
  says_nothing,
  "ok",
  ifelse(
    rowSums(hits) == 0,
    "unrecognised",
    ifelse(rowSums(hits[, !provided, drop = FALSE]) == 0, "ok", "library")
  )
)
sys <- ifelse(is.na(sr), "ok", status[match(sr, texts)])
sys_ok <- sys == "ok"

# Classify --------------------------------------------------------------------

log_step("Classifying")
core <- tolower(c(base, recommended))
deps_ok <- deps_in(c(core, cf$pkg))
from_source <- !on_cf & deps_ok & sys_ok
usable <- on_cf | from_source
blocked_dep <- !on_cf & !deps_ok
blocked_sys <- !on_cf & deps_ok & !sys_ok

# Iterate, treating packages that build from source as available
chain <- function(have, ok, sys_ok) {
  repeat {
    new <- !ok & sys_ok & deps_in(c(have, tolower(pkg[ok])))
    if (!any(new)) {
      return(ok)
    }
    ok <- ok | new
  }
}
bioc_names <- unique(c(bc$pkg, tolower(bp$Package)))
chains <- chain(c(core, cf$pkg), usable, sys_ok)
with_bioc <- chain(c(core, cf$pkg, bc$pkg[bc$here]), chains, sys_ok)
# The rest, if Bioconductor packages and system libraries were all available
rest <- blocked_dep & !chains
if_all <- chain(c(core, cf$pkg, bioc_names), chains, sys != "unrecognised")

# The Bioconductor packages the rest depend on most
rest_deps <- dep_name[dep_pkg %in% which(rest)]
bioc_deps <- sort(
  table(rest_deps[!rest_deps %in% pkg & tolower(rest_deps) %in% bioc_names]),
  decreasing = TRUE
)
# The system libraries packages need most
libs <- sort(
  colSums(hits[
    match(sr[blocked_sys & sys == "library"], texts),
    !provided,
    drop = FALSE
  ]),
  decreasing = TRUE
)

# The 1,000 packages other CRAN packages depend on most
rev_count <- tabulate(match(dep_name, pkg), nbins = n)
top <- order(-rev_count, pkg)[1:1000]

# conda-forge at CRAN's version (conda writes 1.2-3 as 1.2_3)
conda_v <- package_version(
  gsub("_", "-", cf$version[match(tolower(pkg[on_cf]), cf$pkg)]),
  strict = FALSE
)
cran_v <- package_version(db$Version[on_cf], strict = FALSE)
valid <- !is.na(conda_v) & !is.na(cran_v)
current <- conda_v[valid] == cran_v[valid]

# Write -----------------------------------------------------------------------

result <- list(
  date = format(Sys.Date()),
  platform = platform,
  pixi = pixi_version,
  r = env$version[env$name == "r-base"],
  r_system_requirements = sha,
  cran = list(
    packages = n,
    conda_forge = sum(on_cf),
    source = sum(from_source),
    usable = sum(usable),
    blocked_dependency = sum(blocked_dep),
    blocked_system = sum(blocked_sys),
    top = length(top),
    top_on_conda_forge = sum(on_cf[top]),
    conda_forge_current = share(sum(current), length(current)),
    chains_blocked = sum(chains & blocked_dep),
    usable_chains = sum(chains),
    usable_bioconda = sum(with_bioc),
    rest = sum(rest),
    rest_bioc_or_library = sum(if_all & rest),
    bioc_dependencies = head(names(bioc_deps), 4),
    system_libraries = head(names(libs[libs > 0]), 5),
    shares = list(
      conda_forge = share(sum(on_cf), n),
      source = share(sum(from_source), n),
      usable = share(sum(usable), n),
      blocked_dependency = share(sum(blocked_dep), n),
      blocked_system = share(sum(blocked_sys), n),
      usable_chains = share(sum(chains), n),
      usable_bioconda = share(sum(with_bioc), n)
    )
  ),
  bioconductor = list(
    release = release,
    release_r = r_for_bioc[[release]],
    release_software = release_software,
    bioconda_release = bioconda_release,
    bioconda_r = r_version,
    bioconda_release_software = nrow(bp),
    on_bioconda = sum(bp_here),
    on_bioconda_share = share(sum(bp_here), nrow(bp)),
    at_version_share = share(sum(bp_current), sum(bp_here))
  )
)
jsonlite::write_json(result, out, auto_unbox = TRUE, pretty = TRUE, digits = NA)
log_step("Wrote ", out)
