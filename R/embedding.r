#' Generate Embeddings
#'
#' @param text text vector to generate embeddings for.
#' @param model which model to use. See <https://ollama.com/library> for
#'   options. Default is "llama3.1". Set option(rollama_model = "modelname") to
#'   change default for the current session. See \link{pull_model} for more
#'   details.
#' @param truncate whether to truncate the input to fit within the model's
#'   context length (\code{TRUE}/\code{FALSE}).
#' @param dimensions the desired number of dimensions in the embedding output.
#'   Only available for models that support it.
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
embed_text <- function(
  text,
  model = NULL,
  server = NULL,
  truncate = NULL,
  dimensions = NULL,
  keep_alive = NULL,
  model_params = NULL,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }
  check_model_installed(model, server = server)

  if (verbose) {
    cli::cli_progress_step("Embedding {length(text)} text{?s}")
  }

  req <- list(
    model = model,
    input = as.list(text),
    truncate = truncate,
    dimensions = dimensions,
    keep_alive = keep_alive,
    options = model_params
  ) |>
    purrr::compact() |>
    make_req(server = server, endpoint = "/api/embed")

  resp <- httr2::req_perform(req)

  if (httr2::resp_content_type(resp) != "application/json") {
    cli::cli_alert_danger("Request did not return embeddings")
    return(invisible(NULL))
  }

  embeddings <- httr2::resp_body_json(resp) |>
    purrr::pluck("embeddings")

  out <- purrr::map(embeddings, function(emd) {
    names(emd) <- paste0("dim_", seq_along(emd))
    tibble::as_tibble(emd)
  }) |>
    dplyr::bind_rows()
  return(out)
}
