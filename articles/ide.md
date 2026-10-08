# Using rpix with an IDE

Most R users work in an IDE rather than a terminal: RStudio, Positron or
VS Code. Install the IDE as usual; most IDEs aren’t available as conda
packages, or not in recent versions. Then point it at the R in your
project’s Pixi environment.

## RStudio

RStudio picks its R when it starts, so start it from the project’s
environment, in a terminal in the project folder:

- [Windows](#tabset-1-1)
- [macOS](#tabset-1-2)
- [Linux](#tabset-1-3)

&nbsp;

- ``` sh
  pixi run rstudio
  ```

``` sh
pixi run open -a rstudio
```

``` sh
pixi run rstudio
```

On macOS,
[`rpix::restart_rstudio_with_pixi()`](https://roald-arboel.com/rpix/reference/restart_rstudio_with_pixi.md)
does this from a running RStudio.

To save typing, add a task to `pixi.toml`. On macOS:

``` toml
[tasks]
rstudio = "open -a rstudio"
```

Then `pixi run rstudio` starts RStudio.

## Positron

Positron can find the R in Pixi environments with its
`positron.r.interpreters.pixiDiscovery` setting, which is experimental.
You can also list the environment’s R yourself with
`positron.r.customBinaries`. See [Discovering R
installations](https://positron.posit.co/r-installations.html) in
Positron’s documentation. Then pick that R in Positron’s interpreter
picker.

## VS Code

The [R
extension](https://marketplace.visualstudio.com/items?itemName=REditorSupport.r)
uses the R in its `r.rpath.windows`, `r.rpath.mac` or `r.rpath.linux`
setting. Set it to the environment’s R, at `.pixi/envs/default/bin/R` in
your project on macOS and Linux.

The extension also needs the languageserver package in the environment:

``` r

rpix::pixi_add("languageserver")
```

## Check

In the IDE’s R console, [`R.home()`](https://rdrr.io/r/base/Rhome.html)
should be inside the project’s `.pixi/envs/` folder.
