# pixi_import_renv() adds the packages the project uses, and turns renv off

    Code
      result <- pixi_import_renv()
    Message
      ! Not from CRAN or Bioconductor, so not added: mypkg.
      ! Not on conda-forge or bioconda, so not added: notonconda.
      v Turned renv off: removed `source("renv/activate.R")` from '.Rprofile'.
      i Delete 'renv.lock' and the 'renv' folder when you no longer need them.

# pixi_import_renv() can leave versions, R and renv alone

    Code
      pixi_import_renv(versions = "none", deactivate = FALSE, dry_run = TRUE)
    Message
      ! Not from CRAN or Bioconductor, so not added: mypkg.
      ! Not on conda-forge or bioconda, so not added: notonconda.

---

    Code
      pixi_import_renv(dry_run = TRUE)
    Message
      ! Not from CRAN or Bioconductor, so not added: mypkg.
      ! Not on conda-forge or bioconda, so not added: notonconda.
      i Would remove `source("renv/activate.R")` from '.Rprofile'.

