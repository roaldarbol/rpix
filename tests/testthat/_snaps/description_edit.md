# remove_from_description() removes entries, and an empty field

    Code
      remove_from_description(entries_for(root, "praise"))
    Message
      i Imports in 'DESCRIPTION' doesn't list praise.

# description_entries() checks the type, the project and the packages

    Code
      description_entries("dplyr", NULL, "imports", path = root)
    Condition
      Error:
      ! `type` must be one of "Imports", "Depends", "Suggests", "LinkingTo", "Enhances", or "SystemRequirements".
    Code
      description_entries("conda::gdal", NULL, "Imports", path = root)
    Condition
      Error:
      ! "conda::gdal" isn't an R package, so it doesn't go in Imports.
      i For software the package needs, use `type = "SystemRequirements"`.

# SystemRequirements gets conda packages, after what it says already

    Code
      add_to_description(description_entries("conda::CMake", NULL,
        "SystemRequirements", path = root))
    Message
      i SystemRequirements in 'DESCRIPTION' lists "cmake" already.

# SystemRequirements takes conda packages, and the R fields R packages

    Code
      description_entries("dplyr", NULL, "SystemRequirements", path = root)
    Condition
      Error:
      ! SystemRequirements is for software outside R, and "dplyr" is an R package.
      i Give conda packages as `conda::gdal`, or R packages with another `type`, such as "Imports".
    Code
      description_entries("github::hadley/emo", NULL, "SystemRequirements", path = root)
    Condition
      Error:
      ! SystemRequirements is for software outside R, not R packages from GitHub.

