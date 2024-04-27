screen_answer <- function(x, model = NULL) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer from {cli::style_bold({model})}")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
}


#' Check if one or several models are installed on the server
#'
#' @param model names of one or several models as character vector.
#' @param auto_pull if FALSE, the default, asks before downloading models.
#' @inheritParams query
#'
#' @return invisible TRUE/FALSE
#' @export
check_model_installed <- function(model, auto_pull = FALSE, server = NULL) {
  models_df <- list_models(server = server)
  model <- setdiff(model, models_df$name)
  model_wo_vers <- gsub(":.*", "", models_df$name)
  model <- setdiff(model, model_wo_vers)
  if (length(model) > 0L && !auto_pull) {
    cli::cli_alert_info("Model{?s} {model} not installed. Would you like to download {?it/them}?")
    if (interactive()) auto_pull <- utils::askYesNo("")
    if (!auto_pull) {
      cli::cli_abort("Model{?s} {model} not installed.")
      invisible(FALSE)
    }
  }
  if (auto_pull) {
    for (m in model) {
      pull_model(m, server = server)
    }
  }
  invisible(TRUE)
}
