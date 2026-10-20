# pixi_sitrep() reports them, and Strawberry Perl's runtime

    Code
      show_clobbered(clobbered_files(root))
    Message
      ! 1 file is installed by more than one package. Only one copy can be there, so the other package may not work.
      * 'Library/bin/libstdc++-6.dll' in "default": perl's copy, over libstdcxx's
        To see what brings a package in, e.g. perl, run `rpix::pixi_tree("perl",
        invert = TRUE)`.
      x In "default", Strawberry Perl's MinGW runtime is there in place of conda-forge's, so compiled R packages can fail to load on Windows, with The specified procedure could not be found.
        Find what brings perl in with `rpix::pixi_tree("perl", invert = TRUE)`, and
        drop it, or move it to an environment without R. See
        <https://github.com/conda-forge/perl-feedstock/issues/89>.

# show_clobbered() shows ten files, and how many more

    Code
      show_clobbered(many)
    Message
      ! 12 files are installed by more than one package. Only one copy can be there, so the other package may not work.
      * 'bin/tool1' in "default": a's copy, over b's
      * 'bin/tool2' in "default": a's copy, over b's
      * 'bin/tool3' in "default": a's copy, over b's
      * 'bin/tool4' in "default": a's copy, over b's
      * 'bin/tool5' in "default": a's copy, over b's
      * 'bin/tool6' in "default": a's copy, over b's
      * 'bin/tool7' in "default": a's copy, over b's
      * 'bin/tool8' in "default": a's copy, over b's
      * 'bin/tool9' in "default": a's copy, over b's
      * 'bin/tool10' in "default": a's copy, over b's
        And 2 more.
        To see what brings a package in, e.g. a, run `rpix::pixi_tree("a", invert =
        TRUE)`.

