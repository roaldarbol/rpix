# pixi_search() looks for a Bioconductor package on bioconda

    Code
      pixi_search("limma")
    Message
      i limma isn't on conda-forge, but it's a Bioconductor package, so rpix searches bioconda.

# pixi_search() only shows an R package by its exact name

    Code
      pixi_search("faux")
    Condition
      Error in `pixi_search()`:
      ! There's no package r-faux.
      i Packages with similar names: r-fauxpas.

---

    Code
      pixi_search("faux")
    Condition
      Error in `pixi_search()`:
      ! There's no package r-faux.

# pixi_add() explains a package missing on one of the platforms

    Code
      invisible(capture.output(pixi_add("Rmpi")))
    Condition
      Error in `pixi_add()`:
      ! r-rmpi isn't on conda-forge for "win-64", one of the project's platforms.
      i Add it only for the platforms that have it, one at a time, e.g. `pixi_add("Rmpi", platform = "linux-64")`, or remove the platform with `pixi workspace platform remove win-64`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() explains packages that aren't built for the project's R

    Code
      invisible(capture.output(pixi_add(c("languageserver", "praise"))))
    Condition
      Error in `pixi_add()`:
      ! praise isn't built for the project's version of R yet.
      i conda-forge builds packages for a new version of R some time after it's out.
      i Use R 4.5, the newest it's built for: `pixi_add(c("r-base=4.5", "languageserver", "praise"))`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() suggests R in place of the project's, as valid R

    Code
      invisible(capture.output(pixi_add(packages)))
    Condition
      Error in `pixi_add()`:
      ! withr isn't built for the project's version of R yet.
      i conda-forge builds packages for a new version of R some time after it's out.
      i Use R 4.5, the newest it's built for: `pixi_add(c("r-base=4.5", "withr>=3.0.3", "cli>=3.6.6", "bioc::limma", "conda::gdal", "RColorBrewer>=1.1_3", "viridisLite>=0.4.3", "github::me/mypkg@main"))`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() explains that an old version isn't built for a newer R

    Code
      invisible(capture.output(pixi_add(c("dplyr", "ggplot2==3.4.4"))))
    Condition
      Error in `pixi_add()`:
      ! ggplot2 3.4.4 is only built for R 4.3 and older.
      i Old versions of packages aren't built for a newer R. Instead:
      * Use a newer ggplot2: `pixi_add(c("dplyr", "ggplot2"))`.
      * Build ggplot2 3.4.4 from source: `pixi_add(c("dplyr", "github::cran/ggplot2@3.4.4"))`.
      * Use R 4.3 for the whole project: `pixi_add(c("r-base=4.3", "dplyr", "ggplot2==3.4.4"))`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

---

    Code
      invisible(capture.output(pixi_add("ggplot2", versions = "3.4.4")))
    Condition
      Error in `pixi_add()`:
      ! ggplot2 3.4.4 is only built for R 4.3 and older.
      i Old versions of packages aren't built for a newer R. Instead:
      * Use a newer ggplot2: `pixi_add("ggplot2")`.
      * Use R 4.3 for the whole project: `pixi_add(c("r-base=4.3", "ggplot2=3.4.4"))`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() only offers a build from source for CRAN packages

    Code
      invisible(capture.output(pixi_add("bioc::limma==3.4.4")))
    Condition
      Error in `pixi_add()`:
      ! limma 3.4.4 is only built for R 4.3 and older.
      i Old versions of packages aren't built for a newer R. Instead:
      * Use a newer limma: `pixi_add("bioc::limma")`.
      * Use R 4.3 for the whole project: `pixi_add(c("r-base=4.3", "bioc::limma==3.4.4"))`.
      Caused by error:
      ! `pixi add r-x` failed with exit status 1.
      i See Pixi's output above.

# pixi_add() offers to build CRAN packages that aren't on conda-forge

    Code
      pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1"))
    Message
      ! fortunes isn't on conda-forge.
      i Pixi can build it from CRAN's source, at <https://github.com/cran/fortunes>, with its dependencies from conda-forge.

# pixi_add() says how to build them when it can't ask, or the answer is no

    Code
      pixi_add(c("praise", "fortunes==1.5-4", "cowsay>=1"))
    Condition
      Error in `pixi_add()`:
      ! fortunes and cowsay aren't on conda-forge.
      i Pixi can build them from CRAN's source: `pixi_add(c("github::cran/fortunes@1.5-4", "github::cran/cowsay"))`.

---

    Code
      pixi_add(c("fortunes", "cowsay>=1"))
    Message
      ! fortunes and cowsay aren't on conda-forge.
      i Pixi can build them from CRAN's source, at <https://github.com/cran/fortunes> and <https://github.com/cran/cowsay>, with their dependencies from conda-forge.
      i A version range doesn't apply to a build from source, so cowsay would be the latest version. Use `==` for a particular one.
    Condition
      Error in `pixi_add()`:
      ! Didn't add fortunes and cowsay.
      i Pixi can build them from CRAN's source: `pixi_add(c("github::cran/fortunes", "github::cran/cowsay"))`.

# pixi_add() doesn't offer it for packages that aren't on CRAN

    Code
      pixi_add("dplyrr")
    Condition
      Error in `pixi_add()`:
      ! dplyrr isn't on conda-forge or CRAN.
      i Did you mean dplyr?

---

    Code
      pixi_add(c("dplyrr", "zzqqxx", "praise"))
    Condition
      Error in `pixi_add()`:
      ! dplyrr and zzqqxx aren't on conda-forge or CRAN.
      i dplyrr: did you mean dplyr?

# pixi_add() explains, rather than offers, a build from source in a project with a date

    Code
      pixi_add(c("praise", "fortunes"), path = root)
    Condition
      Error in `pixi_add()`:
      ! fortunes isn't on conda-forge.
      i Pixi can't build it from source in this project: its date, "2025-06-01", hides the `pixi-build-r` that builds packages.
      i `exclude-newer` applies to Pixi's build backend too, and `pixi-build-r` 0.2.0 came out on 2026-10-14.

# ask_yes_no() asks, then offers Yes and No

    Code
      answer <- ask_yes_no("Would you like to?")
    Message
      ? Would you like to?

# pixi_add() finds Bioconductor packages on bioconda

    Code
      pixi_add(c("praise", "DESeq2>=1.40"))
    Message
      i DESeq2 isn't on conda-forge, but it's a Bioconductor package, so rpix adds it from bioconda.

