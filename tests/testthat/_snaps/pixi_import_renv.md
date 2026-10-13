# pixi_import_renv() adds the packages the project uses, and turns renv off

    Code
      result <- pixi_import_renv()
    Message
      ! Not on conda-forge, so not added: notonconda.
      i Pixi can build it from CRAN's source: `pixi_add("github::cran/notonconda")`.
      i Built mypkg and ghdep from source, which is experimental.
      ! In a subfolder of a GitHub repository, which rpix can't add yet, so not added: subpkg.
      ! Not from CRAN, Bioconductor or GitHub, so not added: labpkg.
      ! Not on conda-forge or bioconda, so not added: unipkg and biocmissing.
      v Turned renv off: removed `source("renv/activate.R")` from '.Rprofile'.
      i Delete 'renv.lock' and the 'renv' folder when you no longer need them.

# pixi_import_renv() offers to build CRAN packages that aren't on conda-forge

    Code
      result <- pixi_import_renv(versions = "exact")
    Message
      ! notonconda isn't on conda-forge.
      i Pixi can build it from CRAN's source, at <https://github.com/cran/notonconda>, with its dependencies from conda-forge.
      i Built notonconda, mypkg, and ghdep from source, which is experimental.
      ! In a subfolder of a GitHub repository, which rpix can't add yet, so not added: subpkg.
      ! Not from CRAN, Bioconductor or GitHub, so not added: labpkg.
      ! Not on conda-forge or bioconda, so not added: unipkg and biocmissing.
      v Turned renv off: removed `source("renv/activate.R")` from '.Rprofile'.
      i Delete 'renv.lock' and the 'renv' folder when you no longer need them.

# pixi_import_renv() says how to build them if the answer is no

    Code
      result <- pixi_import_renv(deactivate = FALSE)
    Message
      ! notonconda isn't on conda-forge.
      i Pixi can build it from CRAN's source, at <https://github.com/cran/notonconda>, with its dependencies from conda-forge.
      ! Didn't add notonconda.
      i Pixi can build it from CRAN's source: `pixi_add("github::cran/notonconda")`.
      i Built mypkg and ghdep from source, which is experimental.
      ! In a subfolder of a GitHub repository, which rpix can't add yet, so not added: subpkg.
      ! Not from CRAN, Bioconductor or GitHub, so not added: labpkg.
      ! Not on conda-forge or bioconda, so not added: unipkg and biocmissing.

# pixi_import_renv() can leave versions, R and renv alone

    Code
      pixi_import_renv(versions = "none", deactivate = FALSE, dry_run = TRUE)
    Message
      ! Not on conda-forge, so not added: notonconda.
      i Pixi can build it from CRAN's source: `pixi_add("github::cran/notonconda")`.
      i Would build mypkg and ghdep from source, which is experimental.
      ! In a subfolder of a GitHub repository, which rpix can't add yet, so not added: subpkg.
      ! Not from CRAN, Bioconductor or GitHub, so not added: labpkg.
      ! Not on conda-forge or bioconda, so not added: unipkg and biocmissing.

---

    Code
      pixi_import_renv(dry_run = TRUE)
    Message
      ! Not on conda-forge, so not added: notonconda.
      i Pixi can build it from CRAN's source: `pixi_add("github::cran/notonconda")`.
      i Would build mypkg and ghdep from source, which is experimental.
      ! In a subfolder of a GitHub repository, which rpix can't add yet, so not added: subpkg.
      ! Not from CRAN, Bioconductor or GitHub, so not added: labpkg.
      ! Not on conda-forge or bioconda, so not added: unipkg and biocmissing.
      i Would remove `source("renv/activate.R")` from '.Rprofile'.

