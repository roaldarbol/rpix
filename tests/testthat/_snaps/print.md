# tasks print by feature, with what they need

    Code
      tasks_df()
    Output
      -- Tasks -----------------------------------------------------------------------
      
      default feature (default, r44)
      test    Run the tests
      render  quarto render {{ file }} (args: file; after: test)
      
      r44 feature (r44)
      check   Check the package, with a description long enough to wrap onto a second
              line of the console
      
      r44 environment
      inline  (after: test)
    Code
      tasks_df()[1:2, ]
    Output
      -- Tasks -----------------------------------------------------------------------
      test    Run the tests
      render  quarto render {{ file }} (args: file; after: test)
    Code
      tasks_df()[0, ]
    Output
      -- Tasks -----------------------------------------------------------------------
      No tasks.
    Code
      tasks_df()[, c("name", "command", "description", "feature")]
    Output
      -- Tasks -----------------------------------------------------------------------
      
      default feature
      test    Run the tests
      render  quarto render {{ file }}
      
      r44 feature
      check   Check the package, with a description long enough to wrap onto a second
              line of the console
      
       environment
      inline  

# environments print one per line

    Code
      envs
    Output
      -- Environments ----------------------------------------------------------------
      default  default (on linux-64, osx-arm64)
      r44      r44, test (solve group: main; on linux-64)

# packages print as a table, cut short when there are many

    Code
      packages_df(3)
    Output
      -- r44 environment: 3 packages, 2 in pixi.toml ---------------------------------
        Package  Version  R package  Channel
      * r-pkg01  1.0      pkg01      conda-forge
        r-pkg02  1.0      pkg02      conda-forge
      * r-pkg03  1.0      pkg03      conda-forge
      * in pixi.toml
    Code
      packages_df(31)
    Output
      -- r44 environment: 31 packages, 16 in pixi.toml -------------------------------
        Package  Version  R package  Channel
      * r-pkg01  1.0      pkg01      conda-forge
        r-pkg02  1.0      pkg02      conda-forge
      * r-pkg03  1.0      pkg03      conda-forge
        r-pkg04  1.0      pkg04      conda-forge
      * r-pkg05  1.0      pkg05      conda-forge
        r-pkg06  1.0      pkg06      conda-forge
      * r-pkg07  1.0      pkg07      conda-forge
        r-pkg08  1.0      pkg08      conda-forge
      * r-pkg09  1.0      pkg09      conda-forge
        r-pkg10  1.0      pkg10      conda-forge
      * r-pkg11  1.0      pkg11      conda-forge
        r-pkg12  1.0      pkg12      conda-forge
      * r-pkg13  1.0      pkg13      conda-forge
        r-pkg14  1.0      pkg14      conda-forge
      * r-pkg15  1.0      pkg15      conda-forge
        r-pkg16  1.0      pkg16      conda-forge
      * r-pkg17  1.0      pkg17      conda-forge
        r-pkg18  1.0      pkg18      conda-forge
      * r-pkg19  1.0      pkg19      conda-forge
        r-pkg20  1.0      pkg20      conda-forge
      ... and 11 more. See them all with `print(x, n = Inf)`.
      * in pixi.toml
    Code
      print(packages_df(31), n = Inf)
    Output
      -- r44 environment: 31 packages, 16 in pixi.toml -------------------------------
        Package  Version  R package  Channel
      * r-pkg01  1.0      pkg01      conda-forge
        r-pkg02  1.0      pkg02      conda-forge
      * r-pkg03  1.0      pkg03      conda-forge
        r-pkg04  1.0      pkg04      conda-forge
      * r-pkg05  1.0      pkg05      conda-forge
        r-pkg06  1.0      pkg06      conda-forge
      * r-pkg07  1.0      pkg07      conda-forge
        r-pkg08  1.0      pkg08      conda-forge
      * r-pkg09  1.0      pkg09      conda-forge
        r-pkg10  1.0      pkg10      conda-forge
      * r-pkg11  1.0      pkg11      conda-forge
        r-pkg12  1.0      pkg12      conda-forge
      * r-pkg13  1.0      pkg13      conda-forge
        r-pkg14  1.0      pkg14      conda-forge
      * r-pkg15  1.0      pkg15      conda-forge
        r-pkg16  1.0      pkg16      conda-forge
      * r-pkg17  1.0      pkg17      conda-forge
        r-pkg18  1.0      pkg18      conda-forge
      * r-pkg19  1.0      pkg19      conda-forge
        r-pkg20  1.0      pkg20      conda-forge
      * r-pkg21  1.0      pkg21      conda-forge
        r-pkg22  1.0      pkg22      conda-forge
      * r-pkg23  1.0      pkg23      conda-forge
        r-pkg24  1.0      pkg24      conda-forge
      * r-pkg25  1.0      pkg25      conda-forge
        r-pkg26  1.0      pkg26      conda-forge
      * r-pkg27  1.0      pkg27      conda-forge
        r-pkg28  1.0      pkg28      conda-forge
      * r-pkg29  1.0      pkg29      conda-forge
        r-pkg30  1.0      pkg30      conda-forge
      * r-pkg31  1.0      pkg31      conda-forge
      * in pixi.toml
    Code
      packages_df(0)
    Output
      -- r44 environment: 0 packages, 0 in pixi.toml ---------------------------------

# explicit packages are bold with colours

    Code
      packages_df(2)
    Output
      -- [1mr44[22m environment: 2 packages, 1 in pixi.toml ---------------------------------
      [90mPackage  Version  R package  Channel[39m
      [1mr-pkg01  1.0      pkg01      conda-forge[22m
      r-pkg02  1.0      pkg02      conda-forge
      [90mPackages in pixi.toml are in bold.[39m

# printing falls back to data frames without the columns it needs

    Code
      tasks_df()[, c("name", "command")]
    Output
          name                       command
      1   test Rscript -e 'devtools::test()'
      2 render      quarto render {{ file }}
      3  check                   R CMD check
      4 inline                          <NA>
    Code
      packages_df(2)[, c("name", "version")]
    Output
           name version
      1 r-pkg01     1.0
      2 r-pkg02     1.0

# info prints Pixi, the project and its environments

    Code
      info
    Output
      -- Pixi ------------------------------------------------------------------------
      Version   0.81.0
      Platform  osx-arm64
      Cache     /cache
      
      -- Project ---------------------------------------------------------------------
      Name      demo
      Manifest  /demo/pixi.toml
      
      -- default environment ---------------------------------------------------------
      Features      default
      Dependencies  r-base, r-cli
      Tasks         check, test
      Channels      conda-forge
      Platforms     linux-64, osx-arm64
      Location      /demo/.pixi/envs/default
      
      -- r44 environment -------------------------------------------------------------
      Features      r44
      Solve group   main
      Dependencies  r-base
      Channels      conda-forge
      Platforms     linux-64
      Location      /demo/.pixi/envs/r44

---

    Code
      info
    Output
      -- Pixi ------------------------------------------------------------------------
      Version   0.81.0
      Platform  osx-arm64
      Cache     /cache

