# Troubleshooting

Read this when something fails, after `pixi run Rscript -e 'rpix::pixi_sitrep()'` (or the user's own `rpix::pixi_sitrep()` in their IDE), to match what it, rpix or Pixi said. Messages are quoted as rpix prints them, so search for a phrase. The user-facing guide is [Troubleshooting](https://roald-arboel.com/rpix/articles/troubleshooting.md).

## Pixi and the project

- **"Could not find Pixi."** Pixi isn't installed, or isn't on the `PATH` or in `~/.pixi/bin`. Ask before installing it (`setup-and-sharing.md`). Installed somewhere unusual: `options(rpix.pixi_path = "/path/to/pixi")`.
- **"Could not find a Pixi project."** rpix looks for `pixi.toml`, or a `pyproject.toml` with `[tool.pixi]`, in the working directory and the folders above it. Change directory, or set the project up with `use_pixi()`.
- **"pixi.lock isn't up to date with pixi.toml."** `pixi.toml` changed since the lock was written. `pixi lock` or `pixi install`, then commit both. In CI, setup-pixi with `locked: true` fails the same way.
- **First `pixi run` or `pixi install` seems stuck:** it's downloading R and every package. Give it minutes, and don't start a second Pixi command on the same project meanwhile.

## Adding packages

- **"Some packages couldn't be found."** The name, or a missing `bioc::` or `conda::` prefix: the procedure in `SKILL.md`, and `packages.md`.
- **"... isn't built for the project's version of R yet."** conda-forge, or bioconda, hasn't built the package for this R. The message names the newest R it's built for; pinning R is the user's call.
- **"... isn't on conda-forge."** followed by a `pixi_add("github::cran/...")` call: printed from a script, where rpix doesn't ask. Building from source is experimental: ask, then run the call it printed.
- **"... isn't fully installed: Pixi didn't run its install script."** A package, typically Bioconductor annotation or data, whose install script Pixi skipped. The message gives both commands; running them is the user's call (`packages.md`).
- **"... refused access (401)" or "(403)":** a private channel. The user logs in with `pixi_auth_login("<host>")` in their own R.
- **"Pixi couldn't build ..., so pixi.toml is as it was."** A source build failed; Pixi's output above it says why. Common causes: a dependency that is itself only on GitHub, a Bioconductor dependency, a system library R doesn't bring along, or an `exclude-newer` date older than the build backend.
- **"Pixi couldn't solve the project with packages as of ..."** from `pixi_set_date()`: the project pins versions newer than the date.
- **`install.packages()` fails with "... adds packages with Pixi, which can't use ..."** In the environment's R, `install.packages()` goes through `pixi_add()`, which takes package names only, not `lib` or `type`. `repos` is ignored, and package files go to `utils::install.packages()`, unrecorded. Use `pixi_add()` with the package's name or reference.

## R

- **`there is no package called 'x'`.** In this order: `x` isn't in `pixi.toml` (`pixi_scan()` lists what the code uses that `pixi.toml` lacks); `x` is one of R's recommended packages, which conda-forge's R leaves out (MASS, Matrix, lattice, survival, mgcv, nlme, boot, cluster, codetools...), so add it; the code ran in another R (a bare `Rscript`, or an IDE not set up); `x` is a Bioconductor data package installed without its data.
- **"This R isn't from the project's Pixi environment, so it doesn't use the project's packages."** at startup: something started another R in the project, e.g. a double-clicked `.Rproj` or a bare `R`. Start R with `pixi run R`, or set the IDE up (`setup-and-sharing.md`).
- **R crashes ("segfault", "R is aborting now") loading a package:** a package built for another R. `R.home()` must be inside `.pixi/envs/`, and `.libPaths()` must not list libraries outside the project. A personal library there means the environment lacks `conda-ecosystem-user-package-isolation` (an environment made with `default_feature = FALSE` needs its own; see `environments.md`), or R started without activation and without the project's `.Rprofile` block. A `# Pixi R library setup` block in `.Rprofile` comes from rpix 0.3.0 or earlier: `use_pixi()` removes it from the project's; one in `~/.Rprofile` the user removes.
- **RStudio uses another R:** RStudio picks its R when it starts. Set up with `use_pixi_rstudio()`, close RStudio, and start it with `pixi run rstudio`.
- **"The specified procedure could not be found" loading a compiled package on Windows:** an older copy of a DLL it needs, usually because two packages in the environment install the same file and the older one won, e.g. Strawberry Perl's MinGW runtime (perl comes in with freetds or pymssql). `pixi_sitrep()` lists such files; `pixi_tree("perl", invert = TRUE)` shows what brings perl in; drop it or move it to an environment without R.
- **R doesn't start in VS Code on Windows:** there, the environment's R needs activation. Start VS Code with `pixi run code .`.
- **Positron doesn't offer "R (Pixi: default)":** run "Interpreter: Discover All Interpreters" from the Command Palette, or restart Positron after `use_pixi_positron()`.

## pixi_sitrep() warnings

- **"This R isn't from a Pixi environment."** or **"This R is from another project's Pixi environment"**: the R it ran in isn't this project's. From a shell, run it with `pixi run`.
- **"The environment isn't activated."**: R was started directly, as IDEs do, and the `.Rprofile` block didn't run. Check the block is there (`use_pixi()` adds it) and rpix is installed in the environment.
- **"Libraries from outside the project:"** or **"Loaded from outside the project:"**: see the crash entry above.
- **"Installed without Pixi, so not in pixi.toml: ..."**: something installed these behind Pixi's back, so collaborators and CI don't get them. Add each with `pixi_add()` so the project records it.
- **"DESCRIPTION needs ..., which isn't in the default environment in pixi.toml."** (in a package): `pixi_import_description()`, or `pixi_add()` them.
- **"Older than DESCRIPTION asks for: ..."**: `pixi_update()` them, or raise their constraints in `pixi.toml`.
- **"... files are installed by more than one package"**: only one copy can be there, so a package may not work. `pixi_tree("<package>", invert = TRUE)` shows what brings a package in; drop it, or move it to another environment.
- **"The package's builds include ..."**: add them to `.Rbuildignore`, as the message shows.
