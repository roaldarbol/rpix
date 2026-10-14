# How many packages you can use

For years, the answer to “can I use conda for R?” was “only if your
packages happen to be on conda-forge”. That’s no longer the case: with
conda-forge, bioconda, and packages built from source, most of CRAN and
Bioconductor is usable in a Pixi project. This article has the numbers,
for deciding whether Pixi is ready for your R work.

The numbers are from 12 October 2026, with Pixi 0.81.0. They’ll change
as conda-forge, bioconda and Pixi do.

## CRAN

Of CRAN’s 25,299 packages:

|                                                 | Packages   | Share   |
|-------------------------------------------------|------------|---------|
| On conda-forge                                  | 3,423      | 14%     |
| Built from source by rpix                       | 16,751     | 66%     |
| **Usable through Pixi and rpix**                | **20,174** | **80%** |
| Not yet: a dependency isn’t on conda-forge      | 4,754      | 19%     |
| Not yet: needs a system library R doesn’t bring | 371        | 1%      |

conda-forge has fewer packages than CRAN, but the ones that matter most:
945 of the 1,000 packages other CRAN packages depend on most, and 93% of
its R packages are at CRAN’s current version.

**Built from source** is what
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
offers for a CRAN package that isn’t on conda-forge: Pixi builds it from
CRAN’s source, with its dependencies from conda-forge (see [Finding
packages](https://roald-arboel.com/rpix/articles/finding-packages.md)).
A package counts when all its dependencies (`Depends`, `Imports` and
`LinkingTo`) are on conda-forge or come with R, and its
`SystemRequirements` need nothing beyond what conda-forge’s R brings
(such as curl, cairo, libxml2 or GSL) and the build tools Pixi and rpix
add (Rust, CMake, pkg-config, Java). Building one takes a minute or two.
A random sample of 25 of them all built and loaded, on macOS.

### What’s still missing

Most of the packages that don’t work yet depend on a package that isn’t
on conda-forge either. For 3,938 of these 4,754, that dependency can be
built from source too, so once Pixi can build packages that depend on
other packages built from source
([prefix-dev/pixi#6925](https://github.com/prefix-dev/pixi/issues/6925)),
rpix can build the whole chain. Most of the rest need a Bioconductor
package (often limma, Biostrings, GenomicRanges or S4Vectors), which
needs
[prefix-dev/pixi#6994](https://github.com/prefix-dev/pixi/issues/6994),
or a system library such as GDAL or libsndfile.

|                                               | Usable | Share |
|-----------------------------------------------|--------|-------|
| Today                                         | 20,174 | 80%   |
| Building missing dependencies from source too | 24,112 | 95%   |
| And Bioconductor dependencies from bioconda   | 24,592 | 97%   |

## Bioconductor

bioconda has essentially all of Bioconductor 3.22, for R 4.5: 2,291 of
its 2,300 software packages, 98% of them at their 3.22 version or newer.
Add them with a `bioc::` prefix, or without one:
[`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
looks on bioconda when a package isn’t on conda-forge.

Some things to know:

- **Use R 4.5.** Bioconductor 3.23, for R 4.6, isn’t on bioconda yet.
  That waits on conda-forge building its R packages for R 4.6, which
  only a few are so far.
- **Annotation and data packages**, such as org.Hs.eg.db, download their
  data with an install script, which Pixi only runs in projects that
  allow it.
  [`pixi_add()`](https://roald-arboel.com/rpix/reference/pixi_add.md)
  offers to allow it.
- **Windows:** bioconda doesn’t build its packages for Windows.
  Bioconductor packages that don’t depend on other Bioconductor packages
  do build from source there, from [Bioconductor’s git mirror on
  GitHub](https://github.com/bioc), but rpix doesn’t offer that yet.

## Platforms

The source builds were measured on macOS. Packages of each kind (pure R,
R’s recommended packages, C, C++, Fortran, Rust and Bioconductor) also
build on Linux, and on Windows with what rpix adds for building there.

## How these were counted

- **CRAN:** every package in CRAN’s package database, with its
  dependencies and `SystemRequirements`.
- **conda-forge and bioconda:** the packages in their channel data, for
  osx-64, matched by name (`r-<name>` and `bioconductor-<name>`).
- **System requirements:** read with Posit’s
  [r-system-requirements](https://github.com/rstudio/r-system-requirements)
  rules. A language standard (“C++17”), make, and tools only needed when
  the package runs (pandoc, Python) count as needing nothing.

The script that counts them is
[`data-raw/package-availability.R`](https://github.com/roaldarbol/rpix/blob/main/data-raw/package-availability.R).
