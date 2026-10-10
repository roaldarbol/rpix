# R's interactive(), as a function of rpix's own so tests can mock it
is_interactive <- function() {
  interactive()
}

# Ask a yes/no question, after saying what will happen, as
# rlang::check_installed() does: the question, then a numbered menu. Esc or 0
# count as no.
ask_yes_no <- function(question) {
  cli::cli_text("{cli::col_cyan('?')} {question}")
  utils::menu(c("Yes", "No")) == 1
}
