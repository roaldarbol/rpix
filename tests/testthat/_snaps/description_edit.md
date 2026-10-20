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
      ! `type` must be one of "Imports", "Depends", "Suggests", "LinkingTo", or "Enhances".
    Code
      description_entries("conda::gdal", NULL, "Imports", path = root)
    Condition
      Error:
      ! "conda::gdal" isn't an R package, so it can't go in 'DESCRIPTION'.
      i Add it without `type`.

