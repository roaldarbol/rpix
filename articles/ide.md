# Using rpix with an IDE

Most R users work in an IDE rather than a terminal: RStudio, Positron or
VS Code, or an editor such as Emacs, Neovim or Zed. Install the IDE as
usual (see [Installing the IDEs](#installing-the-ides)). Then let rpix
point it at the R in your project’s Pixi environment, when you set the
project up:

``` r

rpix::use_pixi(ide = "positron")
```

or later, for one IDE at a time, with
[`use_pixi_rstudio()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
[`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
[`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
[`use_pixi_emacs()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md),
[`use_pixi_neovim()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
or
[`use_pixi_zed()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md).
For Jupyter notebooks, see [Jupyter](#jupyter).

Some settings are a matter of taste, such as VS Code’s R console. rpix
asks about them as it sets the IDE up. To answer in advance, e.g. in a
script, give them as arguments, also to
[`use_pixi()`](https://roald-arboel.com/rpix/reference/use_pixi.md):

``` r

rpix::use_pixi(ide = "vscode", console = "arf")
```

Whichever IDE you use,
[`rpix::pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md)
checks that it runs the project’s R, and suggests fixes if it doesn’t.

## Installing the IDEs

Install the IDE as you’d install any program. conda-forge has the
command-line editors, and direnv, in recent versions, so Pixi can
install them for you as your own tools, outside any project, with
`pixi global install`:

| IDE | Install | With Pixi |
|----|----|----|
| RStudio | [posit.co/download/rstudio-desktop](https://posit.co/download/rstudio-desktop/) |  |
| Positron | [positron.posit.co/download](https://positron.posit.co/download.html) |  |
| VS Code | [code.visualstudio.com/download](https://code.visualstudio.com/download) |  |
| Emacs | [gnu.org/software/emacs/download](https://www.gnu.org/software/emacs/download.html) | `pixi global install emacs` |
| Neovim | [neovim.io/doc/install](https://neovim.io/doc/install/) | `pixi global install nvim` |
| Zed | [zed.dev/download](https://zed.dev/download) | `pixi global install zed` |
| direnv, for Emacs, Neovim and Zed | [direnv.net/docs/installation](https://direnv.net/docs/installation.html) | `pixi global install direnv` |

- **Neovim’s package is `nvim`.** conda-forge’s `neovim` is its Python
  client, without the editor.
- **RStudio** is on conda-forge too, as `rstudio-desktop`, but in a
  version from 2024; install it from Posit instead.
- **Commands:** rpix’s setups for Emacs, Neovim and Zed, and for VS Code
  on Windows, say when the editor’s command (`emacs`, `nvim`, `zed`,
  `code`) isn’t on the `PATH`. An app can be installed without it: Zed’s
  comes from its **zed: install cli** command, and VS Code’s from
  **Shell Command: Install ‘code’ command in PATH**, on macOS.
  `pixi global install` puts the commands in `~/.pixi/bin`, which is on
  the `PATH`.
- **direnv** also needs hooking into your shell once, which
  `pixi global install` doesn’t do: see [direnv’s
  instructions](https://direnv.net/docs/hook.html).

## Positron

### Set up

``` r

rpix::use_pixi_positron()
```

This turns on Positron’s discovery of R in Pixi environments, and makes
the R from the project’s default environment Positron’s default for the
project, in `.vscode/settings.json`. `default_r = FALSE` leaves the
default out.

### Every day

Open the project, and Positron (2026.10 or later) starts its R. With an
older Positron, or `use_pixi_positron(default_r = FALSE)`, pick **R
(Pixi: default)** in the interpreter picker once; Positron remembers it
for the project. Either way, the environment is activated when R starts,
on Windows too.

The default’s path is for the operating system
[`use_pixi_positron()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
ran on. On another one, Positron ignores it, so collaborators there pick
**R (Pixi: default)** once.

### Another environment

Each of the project’s environments is listed as its own R, e.g. **R
4.4.3 (Pixi: r44)**. Pick it in the interpreter picker, or run
`rpix::pixi_switch("r44")`, which looks for interpreters again and opens
the picker.

### If something’s off

- **Positron starts another R.** Positron prefers the R you last picked
  in the project over the default. If you used another R there before
  setting up Pixi, pick **R (Pixi: default)** once.
- **R (Pixi: default) isn’t listed.** Positron may still show the R
  installations it found before, even in a new project. Run
  **Interpreter: Discover All Interpreters** from the Command Palette.
  Restart Positron if you’ve only just turned on discovery.

## RStudio

### Set up

For a new project, use RStudio’s **File \> New Project \> New Directory
\> Project with Pixi**. It does what `use_pixi(ide = "rstudio")` does,
for the version of R you pick (4.5 by default: conda-forge has no R
packages for R 4.6 yet), and makes the project a git repository if you
ask.

For a project you have already, run in RStudio:

``` r

rpix::use_pixi(ide = "rstudio")   # or rpix::use_pixi_rstudio() in a Pixi project
```

This adds an `rstudio` task to `pixi.toml`, and creates an `.Rproj` file
if the project doesn’t have one. Both ways need rpix in the R that
RStudio runs.

RStudio also applies its own “Create a git repository” and “Use renv
with this project” to templates, as you last left them in its New
Project dialog, without showing them. renv clashes with Pixi, as both
manage the project’s packages, so turn it off: run
`rstudioapi::writeRStudioPreference("new_proj_use_renv", FALSE)` (or
`.rs.api.writeRStudioPreference(...)` without rstudioapi), or create one
project with it unticked. RStudio only saves the checkbox when a project
is created, not when the dialog is cancelled. If renv got into a
project, rpix says so, and that
[`rpix::pixi_import_renv()`](https://roald-arboel.com/rpix/reference/pixi_import_renv.md)
turns it off.

### Every day

Open the project in RStudio as usual, e.g. from its recent projects or
by double-clicking the `.Rproj` file. RStudio picks its R when it
starts, so it opens the project in your usual R. Once it’s ready, rpix
asks:

    ? Reopen this project in a new RStudio, with its Pixi R?
    1: Yes
    2: No

Yes starts a new RStudio with the environment’s R, in the project, after
installing the environment if it isn’t yet, and closes this one.
**Addins \> Open with the project’s Pixi R**, or
[`rpix::pixi_switch()`](https://roald-arboel.com/rpix/reference/pixi_switch.md),
does the same later. To stop the question, set `RPIX_OFFER_SWITCH=false`
in your `~/.Renviron`.

From a terminal, `pixi run rstudio` in the project folder starts RStudio
with the environment’s R straight away. On Windows, the task expects
RStudio in `C:/Program Files/RStudio`; if it’s somewhere else, change
the path in `pixi.toml`.

### Addins

rpix adds these to RStudio’s **Addins** menu:

- **Open with the project’s Pixi R:** a new RStudio with the
  environment’s R (pick the environment if there are several).
- **Add packages…:** the selected packages, or the code’s, or those you
  name.
- **Add the packages this file uses:** those the active file uses and
  `pixi.toml` lacks.
- **Install the environment:** e.g. after a `git pull`.
- **Run a task…:** one of the project’s tasks.
- **Open pixi.toml**.
- **Situation report:**
  [`pixi_sitrep()`](https://roald-arboel.com/rpix/reference/pixi_sitrep.md).

They’re there when rpix is installed in the R that RStudio runs. To give
one a keyboard shortcut, use **Tools \> Modify Keyboard Shortcuts**.

### Another environment

From RStudio, run:

``` r

rpix::pixi_switch("r44")
```

This starts a new RStudio with the environment’s R, in the project. The
first time, it can take a while to open. Close the old one when you’re
done with it. **Addins \> Open with the project’s Pixi R** does the
same, and asks which environment.

From a terminal, `pixi run --environment test rstudio` works too, for
environments that include the default feature, which the task belongs
to.

### If something’s off

- **RStudio uses another R, and rpix didn’t ask.** rpix isn’t installed
  in the R that RStudio runs, so nothing can ask. Install it there, or
  use `pixi run rstudio` from a terminal.

## VS Code

### Set up

``` r

rpix::use_pixi_vscode()
```

This adds the languageserver package to the environment, with the R
extension’s sess (how it talks to R) and jgd (its plots), and points the
[R
extension](https://marketplace.visualstudio.com/items?itemName=REditorSupport.r)
at the environment’s R, in the project’s `.vscode/settings.json`. It
works the same in the editors based on VS Code, such as VSCodium, Cursor
and Windsurf: they read the same settings, and get the R extension from
[Open VSX](https://open-vsx.org/extension/REditorSupport/r). A project
set up once works in all of them.

sess and jgd aren’t on conda-forge yet, so they come from
[rpix-forge](https://prefix.dev/channels/rpix-forge), a channel rpix
adds to the project after conda-forge. The extension only uses a sess
built from its own release, so when the extension is newer than
rpix-forge’s sess, it offers to install its bundled copy: accept. It
installs into a library of its own, and the packages sess needs are
there already.

### Another console

The R extension’s console can be [arf](https://github.com/eitsupi/arf)
or [radian](https://github.com/randy3k/radian), instead of R.
[`use_pixi_vscode()`](https://roald-arboel.com/rpix/reference/use_pixi_ide.md)
asks which, or takes it as an argument:

``` r

rpix::use_pixi_vscode(console = "arf")
```

This adds arf to the environment, and points `r.consolePath` at it, with
`r.consoleArgs` telling it to start the environment’s R.

### Every day

Open the project folder in VS Code. The R extension uses the
environment’s R, and the project’s `.Rprofile` activates the
environment.

On Windows, the environment’s R only starts when the environment is
activated, because it needs the environment’s `Library\bin` folder on
the `PATH`. So start VS Code from the project’s environment:

``` sh
pixi run code .
```

For VSCodium, Cursor or Windsurf, use `codium`, `cursor` or `windsurf`
instead of `code`.

### Another environment

Run `rpix::pixi_switch("r44")`. It changes `r.executablePath` and
`r.consolePath` in `.vscode/settings.json` to the environment’s R,
`${workspaceFolder}/.pixi/envs/r44/bin/R`. With arf or radian as the
console, it keeps the default environment’s console, and points it at
the environment’s R. Then run **Developer: Reload Window** from the
Command Palette.

On Windows, start VS Code with `pixi run --environment r44 code .`
instead (or `codium`, `cursor` or `windsurf`). The console then has to
be in that environment too.

### If something’s off

- **The R extension can’t find R.** Check that the environment is
  installed (`pixi install`), and that the paths in
  `.vscode/settings.json` exist.
- **Positron and VS Code share `.vscode/settings.json`.** Each ignores
  the other’s settings, so a project can be set up for both.

## Emacs, Neovim and Zed

These editors start R, and languageserver, from the `PATH`.
[direnv](https://direnv.net) puts the environment’s on it whenever
you’re in the project’s folder.

### Set up

Install direnv once (see [Installing the IDEs](#installing-the-ides)),
and hook it into your shell. Then, in the project:

``` r

rpix::use_pixi_emacs()   # or use_pixi_neovim(), use_pixi_zed()
```

This adds the languageserver package to the environment, and a `.envrc`
file that activates the environment
([`rpix::use_pixi_direnv()`](https://roald-arboel.com/rpix/reference/use_pixi_direnv.md)
writes just the file). direnv only loads a `.envrc` you’ve allowed, and
again after it changes: rpix offers to allow it, or run `direnv allow`
in the project.

Each editor loads direnv in its own way:

- **Emacs:** install the [envrc](https://github.com/purcell/envrc)
  package and turn on `(envrc-global-mode)`. ESS, and languageserver
  through eglot or lsp-mode, then use the project’s R.
- **Neovim:** start Neovim from a shell with [direnv’s
  hook](https://direnv.net/docs/hook.html), or use a direnv plugin such
  as [direnv.vim](https://github.com/direnv/direnv.vim).
  [R.nvim](https://github.com/R-nvim/R.nvim) and languageserver then use
  the project’s R.
- **Zed:** Zed loads direnv by itself. Install its R extension:
  languageserver then uses the project’s R, and so does R in Zed’s
  terminal.

On Windows, direnv is rarely available, and the environment’s R only
starts when the environment is activated. Start the editor from the
environment instead: `pixi run emacs`, `pixi run nvim` or
`pixi run zed .`.

### Another environment

Run `rpix::pixi_switch("r44")`. It points `.envrc` at that environment.
Reload direnv in the editor (in Emacs, `M-x envrc-reload`; in Neovim,
start it again from the project; in Zed, reopen the project), then
restart R.

## Jupyter

**Experimental:** this may still change. See
[\#184](https://github.com/roaldarbol/rpix/issues/184).

### Set up

``` r

rpix::use_pixi_jupyter()   # or use_pixi(ide = "jupyter")
```

This:

- adds IRkernel to each environment with R (and, where an environment
  has Python, ipykernel);
- writes a kernel for each of those environments into the project, in
  `.jupyter/kernels/`, named e.g. “R (Pixi: default)”. A kernel starts
  its environment’s R with `pixi run`, so it gets the activated
  environment on every platform. The kernels hold no paths of your
  computer, so commit them;
- adds JupyterLab in an environment of its own, `jupyter`, so your R
  environments don’t get Python and JupyterLab;
- adds a `jupyter` task that starts JupyterLab with the project’s
  kernels.

### Every day

``` r

rpix::pixi_run("jupyter")
```

starts JupyterLab. Open a notebook, and pick one of the “(Pixi: …)”
kernels.

rpix doesn’t use the `ir` kernel that comes with conda-forge’s IRkernel:
a kernel of that name in your own Jupyter folder, such as one from
`IRkernel::installspec()`, would be used instead, with another R.

### Another environment

Run
[`rpix::use_pixi_jupyter()`](https://roald-arboel.com/rpix/reference/use_pixi_jupyter.md)
again after adding an environment: it writes that environment’s kernel
too.

### Other editors

VS Code, Positron and other editors that run notebooks look for kernels
in Jupyter’s own folders, not in `.jupyter/kernels/`. That they find the
project’s kernels when the folder is on `JUPYTER_PATH` is not yet tried.

## The message at startup

If you start R in a Pixi project with an R that isn’t from the project’s
environment, e.g. your usual R, the project’s `.Rprofile` says so, as
long as rpix is installed in that R:

    ! This R isn't from the project's Pixi environment, so it doesn't use the project's packages.
    ℹ Open the project in an IDE set up with `rpix::use_pixi(ide = ...)`, or start R with `pixi run R`. See https://roald-arboel.com/rpix/articles/ide.html.

In RStudio, it asks to reopen the project with the environment’s R
instead (see [RStudio](#rstudio)).

Your usual R can’t use the environment’s packages: they’re built for the
environment’s R, and loading them can crash another R. So rpix doesn’t
try; start the environment’s R instead, as above.

## Check

In the IDE’s R console, [`R.home()`](https://rdrr.io/r/base/Rhome.html)
should be inside the project’s `.pixi/envs/` folder:

``` r

R.home()
#> [1] "/path/to/project/.pixi/envs/default/lib/R"
```
