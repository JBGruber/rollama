#' Pull a new model
#'
#' @param model name of the model. "llama2" by default.
#' @inheritParams query
#'
#' @return TRUE, if model was pulled successfully.
#' @export
#'
#' @examples
#' \dontrun{
#' pull_model("mixtral")
#' }
pull_model <- function(model = NULL, server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server", default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/pull") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_perform_stream(callback = pgrs, buffer_kb = 8L)

  invisible(TRUE)
}

