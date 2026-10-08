# Add pixi to PATH

`pixi_to_path()` checks if pixi's installation directory is in the
current PATH and adds it if not found. The function automatically
detects the operating system and uses the appropriate default
installation path for each platform.

## Usage

``` r
pixi_to_path()
```

## Value

Invisibly returns `NULL`. The function is called for its side effects of
modifying the PATH environment variable.

## Details

The function checks if the pixi binary directory is already present in
the PATH environment variable. If not found, it appends the default
installation directory:

- **macOS/Linux**: `~/.pixi/bin`

- **Windows**: `%USERPROFILE%\\.pixi\\bin`

This modification only affects the current R session.

## See also

[`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html),
[`Sys.getenv()`](https://rdrr.io/r/base/Sys.getenv.html),
[`Sys.info()`](https://rdrr.io/r/base/Sys.info.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Check if pixi is available and add to PATH if needed
pixi_to_path()

# Verify pixi is now available
system("pixi --version")
} # }
```
