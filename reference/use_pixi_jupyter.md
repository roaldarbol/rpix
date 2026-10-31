# Use Jupyter notebooks with the project's R

**Experimental.** This may change, see
<https://github.com/roaldarbol/rpix/issues/184>.

Set the project up for Jupyter notebooks, so they run with the R of the
project's environments. It installs what it adds below into those
environments.

- It adds a `jupyter` environment with JupyterLab, of its own, so the
  environments with R don't get Python and JupyterLab.

- It adds IRkernel (`r-irkernel`) to each environment with R, and, where
  an environment has Python, `ipykernel`.

- It writes a kernel for each of those environments into the project, in
  `.jupyter/kernels/`, named e.g. "R (Pixi: default)" or "R (Pixi:
  r44)". A kernel starts its environment's R with
  `pixi run --environment`, so Pixi activates the environment, also on
  Windows. The kernels have no paths of this computer in them, so commit
  them with the project.

- It adds a `jupyter` task that starts JupyterLab with those kernels:
  `pixi_run("jupyter")`, or `pixi run jupyter` in a terminal.

rpix doesn't use the `ir` kernel that conda-forge's IRkernel brings, as
a kernel of that name in your own Jupyter folder, e.g. from
`IRkernel::installspec()`, would be used instead.

Run it again after adding an environment, to add that environment's
kernel.

## Usage

``` r
use_pixi_jupyter(path = NULL)
```

## Arguments

- path:

  The project. Defaults to the project of the running Pixi environment,
  or the working directory.

## Value

The path to the project's manifest, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
# Needs Pixi, and adds JupyterLab and IRkernel to the project
use_pixi_jupyter()
pixi_run("jupyter")
} # }
```
