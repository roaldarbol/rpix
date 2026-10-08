# Search for package versions and dependencies

`search()` searches for available versions of a conda package and
displays their dependencies. This is useful for exploring what versions
are available before adding a package to your pixi project. The search
shows version information and dependency requirements for each version
found.

When called without arguments, it behaves like base R's `search()`
function and returns the current search path.

## Usage

``` r
search(package, channel = NULL, dry_run = FALSE)
```

## Arguments

- package:

  Package name to search for. It's translated like in
  [`add()`](https://roald-arboel.com/rpix/reference/add.md), so
  `"dplyr"` searches for `r-dplyr`, `"bioc::DESeq2"` for
  `bioconductor-deseq2` on bioconda, and `"conda::gdal"` for `gdal`. If
  missing, returns the search path like base R's search().

- channel:

  Optional. Defaults to conda-forge, but other conda channels can be
  specified to search in specific repositories.

- dry_run:

  Should the command be executed? If TRUE, the final pixi command will
  be shown but not executed. FALSE (default) executes the command.

## Value

When `package` is provided: doesn't return objects, displays search
results in console. When `package` is missing: returns character vector
of search path (like base R's search()).

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for available versions of tibble
search("tibble")

# Search in a specific channel
search("conda::numpy", channel = "conda-forge")

# Just show the command without running it
search("dplyr", dry_run = TRUE)

# Get search path (like base R)
search()
} # }
```
