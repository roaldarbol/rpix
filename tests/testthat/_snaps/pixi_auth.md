# pixi_auth_login() asks for a token, and hides it

    Code
      pixi_auth_login("prefix.dev")
    Message
      v Logged in to "prefix.dev".

# pixi_auth_login() needs an interactive session

    Code
      pixi_auth_login("prefix.dev")
    Condition
      Error in `pixi_auth_login()`:
      ! `pixi_auth_login()` asks for a secret, so it needs an interactive R session.
      i In continuous integration, use the `auth-*` inputs of the setup-pixi action.

# ask_secret() needs askpass, and something entered

    Code
      ask_secret("Token:")
    Condition
      Error:
      ! Asking for a secret without showing it needs the askpass package.
      i Add it with `pixi_add("askpass")`.

