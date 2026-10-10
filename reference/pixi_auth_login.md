# Log in to private channels

**Experimental.** These may change, e.g. to pass the secret to Pixi on
standard input once it can read it from there. See
<https://github.com/roaldarbol/rpix/issues/97>.

Pixi needs credentials to install packages from private conda channels,
e.g. on prefix.dev, anaconda.org, Artifactory or S3. These functions run
`pixi auth`, which stores credentials in your system's keychain, or in
`~/.rattler/credentials.json`, for every Pixi project to use.

- `pixi_auth_login()` logs in to a host. It asks for the token or
  password with hidden input, so it isn't shown, or saved in your R
  history.

- `pixi_auth_logout()` removes the credentials for a host.

- `pixi_auth_status()` lists the hosts Pixi has credentials for, without
  the secrets.

rpix never shows or saves a secret itself. Pixi takes it as a
command-line argument, so while Pixi runs, other users on the same
computer could see it in the list of running processes.

For continuous integration, use the `auth-*` inputs of the setup-pixi
action instead. For more information, see
<https://pixi.prefix.dev/latest/deployment/authentication/>.

## Usage

``` r
pixi_auth_login(
  host,
  method = c("token", "password", "conda-token", "s3"),
  username = NULL
)

pixi_auth_logout(host)

pixi_auth_status()
```

## Arguments

- host:

  The host, such as `"prefix.dev"` or `"repo.example.com"`.

- method:

  How to log in:

  - `"token"`: a token, e.g. for prefix.dev.

  - `"password"`: a username and password (basic HTTP authentication),
    e.g. for Artifactory or Nexus.

  - `"conda-token"`: a token for anaconda.org or quetz.

  - `"s3"`: an access key ID and secret access key, for channels on S3.

- username:

  For `method = "password"`, the username. Asked for if not given.

## Value

- `pixi_auth_login()` and `pixi_auth_logout()`: the result of the Pixi
  call, invisibly, with any secret hidden.

- `pixi_auth_status()`: a data frame with a row per host, and the
  columns `host`, `method`, `username` and `source`.

## Examples

``` r
if (FALSE) { # \dontrun{
pixi_auth_login("prefix.dev")
pixi_auth_login("repo.example.com", method = "password", username = "me")
pixi_auth_status()
pixi_auth_logout("prefix.dev")
} # }
```
