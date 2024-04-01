screen_answer <- function(x, model = NULL) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer from {cli::style_bold({model})}")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
}
