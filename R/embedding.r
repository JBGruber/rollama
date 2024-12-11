#' Generate Embeddings
#'
#' @param text text vector to generate embeddings for.
#' @param model which model to use. See <https://ollama.com/library> for
#'   options. Default is "llama3.1". Set option(rollama_model = "modelname") to
#'   change default for the current session. See \link{pull_model} for more
#'   details.
#' @param model_params a named list of additional model parameters listed in the
#'   [documentation for the
#'   Modelfile](https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values).
#' @param verbose Whether to print status messages to the Console
#'   (\code{TRUE}/\code{FALSE}). The default is to have status messages in
#'   interactive sessions. Can be changed with \code{options(rollama_verbose =
#'   FALSE)}.
#' @inheritParams query
#'
#' @return a tibble with embeddings.
#' @export
#'
#' @examples
#' \dontrun{
#' embed_text(c(
#'   "Here is an article about llamas...",
#'   "R is a language and environment for statistical computing and graphics."))
#' }
embed_text <- function(text,
                       model = NULL,
                       server = NULL,
                       model_params = NULL,
                       verbose = getOption("rollama_verbose",
                                           default = interactive())) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama3.1")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  check_model_installed(model, server = server)

  pb <- FALSE
  if (verbose) pb <- list(
    format = "{cli::pb_spin} embedding text {cli::pb_current} / {cli::pb_total} ({cli::pb_rate}) {cli::pb_eta}",
    format_done = "{cli::col_green(cli::symbol$tick)} embedded {cli::pb_total} texts {cli::col_silver('[', cli::pb_elapsed, ']')}",
    clear = FALSE
  )

  reqs <- purrr::map(text, function(t) {
    list(model = model,
         prompt = t,
         stream = FALSE,
         model_params = model_params) |>
      purrr::compact() |>
      make_req(server = server,
               endpoint = "/api/embeddings")
  })

  resps <- httr2::req_perform_parallel(reqs, progress = pb)

  out <- purrr::map(resps, function(resp) {
    if (httr2::resp_content_type(resp) == "application/json") {
      emd <- httr2::resp_body_json(resp) |>
        purrr::pluck("embedding")
      names(emd) <- paste0("dim_", seq_along(emd))
      tibble::as_tibble(emd)
    } else {
      cli::cli_alert_danger("Request did not return embeddings")
    }
  }) |>
    dplyr::bind_rows()
  return(out)
}
