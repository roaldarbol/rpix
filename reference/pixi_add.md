# Add packages

Add packages to the Pixi manifest and install them. Pixi only adds them
if they can be solved together with the rest of the project's
dependencies.

R package names are translated to conda names: `"dplyr"` becomes
`r-dplyr` and `"Rcpp"` becomes `r-rcpp` (conda names are lowercase). Use
a prefix to say where a package comes from:

- `"bioc::DESeq2"`: a Bioconductor package (`bioconductor-deseq2` from
  the bioconda channel, which is added to the project if needed).
  Without the prefix, a package that isn't on conda-forge is looked for
  on bioconda too, so `"DESeq2"` works as well. Bioconductor's
  annotation and data packages, such as org.Hs.eg.db, download their
  data with an install script, which Pixi only runs in projects that
  allow it; `pixi_add()` offers to allow it.

- `"conda::gdal"`: a conda package that isn't an R package, used as is.
  Names containing `-` or `_`, such as `"c-compiler"`, are also used as
  is.

- `"cran::dplyr"`: same as `"dplyr"`.

- `"github::user/repo"` (experimental): an R package on GitHub, which
  Pixi builds from source with its R build backend, `pixi-build-r`. Add
  `@ref` for a branch, tag or commit, as in
  `"github::cran/praise@1.0.0"`; `pixi.lock` records the exact commit
  either way. rpix writes it into `pixi.toml`, turns on Pixi's
  `pixi-build` preview, and pins the build to the project's R. Its
  dependencies come from conda-forge. It asks for `pixi-build-r` 0.2.0
  or later, which adds the Rust, CMake, pkg-config and R's recommended
  packages a package needs; a project with packages as of a date before
  2026-10-15 can't get it (see
  [`pixi_set_date()`](https://roald-arboel.com/rpix/reference/pixi_set_date.md)).
  rpix also adds what `pixi-build-r` doesn't: Java when
  `SystemRequirements` names it, and in a project for Windows, MSYS2's
  `make`, `sed` and `coreutils`, and MinGW's compilers in place of
  `pixi-build-r`'s. See
  <https://pixi.prefix.dev/latest/build/backends/pixi-build-r/>. This
  may change, e.g. to use `pixi add` once it can set a build backend;
  see <https://github.com/roaldarbol/rpix/issues/96>. While Pixi builds,
  rpix shows a line rather than the build's log, unless the build fails.

In a project with several environments, Pixi doesn't install after
adding or removing, so `pixi_add()` and
[`pixi_remove()`](https://roald-arboel.com/rpix/reference/pixi_remove.md)
install the environment R runs in (or else the default one), when the
change applies to it.

When it adds R (`r-base`) to the default feature, it also adds
`conda-ecosystem-user-package-isolation`, unless it's there, to keep
your personal R library out of the environment's R, as
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md)
does.

Pixi's output is shown once it has added the packages, or if it fails in
a way rpix can't handle, but not when rpix can, e.g. by looking on
bioconda. To see Pixi's output and build logs as Pixi runs, set
`options(rpix.verbose = TRUE)`.

For more information, see
<https://pixi.prefix.dev/latest/reference/cli/pixi/add/>.

## Usage

``` r
pixi_add(
  packages,
  versions = NULL,
  channel = NULL,
  feature = NULL,
  platform = NULL,
  path = NULL,
  dry_run = FALSE
)
```

## Arguments

- packages:

  Package names. A version constraint can follow the name, as in
  `"dplyr>=1.1"`.

- versions:

  Optional. Version constraints, either one for all packages or one per
  package (use `NA` for no constraint). A version without an operator,
  such as `"1.1"`, means `1.1.*`. For a package from GitHub, it's a
  branch, tag or commit instead, as with `@ref`.

- channel:

  Optional. A conda channel to install the packages from. It's added to
  the project's channels if it isn't there yet.

- feature:

  Optional. The feature to add the packages to, rather than the default
  one. See
  [`pixi_add_environment()`](https://roald-arboel.com/rpix/reference/pixi_environments.md).

- platform:

  Optional. Only add the packages for this platform, such as
  `"linux-64"`.

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

- dry_run:

  If `TRUE`, show the Pixi commands without running them.

## Value

The commands (invisibly) if `dry_run = TRUE`, otherwise the result of
the Pixi call (invisibly).

## Examples

``` r
# A throwaway Pixi project in R's temporary folder, so the examples leave
# yours alone. With `dry_run = TRUE`, rpix shows the Pixi command it would run.
project <- file.path(tempdir(), "rpix-example")
dir.create(project, showWarnings = FALSE)
writeLines(
  c(
    "[workspace]",
    'name = "rpix-example"',
    'channels = ["conda-forge"]',
    'platforms = ["linux-64", "osx-arm64", "win-64"]',
    "",
    "[dependencies]",
    'r-base = "4.5.*"',
    'conda-ecosystem-user-package-isolation = "*"'
  ),
  file.path(project, "pixi.toml")
)

pixi_add("tibble", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi add r-tibble --manifest-path /tmp/RtmpBm82CL/rpix-example/pixi.toml`
pixi_add(
  c("dplyr>=1.1", "bioc::DESeq2", "conda::gdal"),
  path = project,
  dry_run = TRUE
)
#> ℹ Would run: `pixi workspace channel add bioconda --no-install --manifest-path /tmp/RtmpBm82CL/rpix-example/pixi.toml`
#> ℹ Would run: `pixi add "r-dplyr>=1.1" bioconda::bioconductor-deseq2 gdal --manifest-path /tmp/RtmpBm82CL/rpix-example/pixi.toml`
pixi_add("dplyr", versions = "1.1", path = project, dry_run = TRUE)
#> ℹ Would run: `pixi add r-dplyr=1.1 --manifest-path /tmp/RtmpBm82CL/rpix-example/pixi.toml`
```
