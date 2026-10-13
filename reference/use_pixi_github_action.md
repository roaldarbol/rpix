# Set up GitHub Actions with the project's Pixi environments

Write a GitHub Actions workflow that installs the project's environments
exactly as `pixi.lock` records them, with
[setup-pixi](https://github.com/prefix-dev/setup-pixi), so CI uses the
same R and packages as your computer. It replaces `setup-r`,
`setup-r-dependencies` and `setup-pandoc` from
[r-lib/actions](https://github.com/r-lib/actions), whose other actions
run as usual on top.

- `"check"`: `R CMD check`, with r-lib's `check-r-package`, for each
  environment on each operating system. The environments need rcmdcheck,
  as
  [`use_pixi_check_matrix()`](https://roald-arboel.com/rpix/reference/pixi_check_matrix.md)'s
  do.

- `"test-coverage"`: test coverage, reported to Codecov. The environment
  needs covr and xml2.

- `"pkgdown"`: build the pkgdown site and publish it to GitHub Pages.
  The environment needs pkgdown and pandoc.

- `"task"`: run one of the project's Pixi tasks, e.g. to render a
  report.

In a package, `"check"`, `"test-coverage"` and `"pkgdown"` also need the
package's dependencies from `DESCRIPTION`, `Suggests` included. rpix
warns about each environment that lacks any of these.

The operating systems are those of the project's platforms that GitHub
runs: Linux (`linux-64`), macOS (`osx-arm64`) and Windows (`win-64`).
Add platforms with
[`pixi_add_platform()`](https://roald-arboel.com/rpix/reference/pixi_add_channel.md).
Pixi is pinned to the version you have, and the workflow fails if
`pixi.lock` is out of date with `pixi.toml`, so commit both.

## Usage

``` r
use_pixi_github_action(
  workflow = c("check", "test-coverage", "pkgdown", "task"),
  environments = NULL,
  task = NULL,
  overwrite = FALSE,
  path = NULL
)
```

## Arguments

- workflow:

  Which workflow: `"check"`, `"test-coverage"`, `"pkgdown"` or `"task"`.

- environments:

  Optional. The environments to use; `"test-coverage"` and `"pkgdown"`
  use the first. Defaults to those that have what the workflow needs:
  for `"check"` all of them, and for `"test-coverage"` and `"pkgdown"`
  the first, or else the default environment. `"task"` defaults to the
  default environment.

- task:

  For `"task"`, the task to run.

- overwrite:

  If `TRUE`, replace a workflow that's there.

- path:

  The project. Defaults to the working directory.

## Value

The path to the workflow file, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
use_pixi_github_action("check")
use_pixi_github_action("check", environments = c("r44", "r45"))
use_pixi_github_action("task", task = "render")
} # }
```
