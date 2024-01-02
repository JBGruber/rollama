#' Pull a new model or show more information about it
#'
#' @param model name of the model. "llama2" by default.
#' @inheritParams query
#'
#' @return (invisible) a tibble with information about the model
#' @export
#'
#' @examples
#' \dontrun{
#' model_info <- pull_model("mixtral")
#' # after you pull, you can get the same information with:
#' model_info <- show_model("mixtral")
#' }
pull_model <- function(model = NULL, server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server", default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/pull") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_perform_stream(callback = pgrs, buffer_kb = 8L)

  invisible(show_model(model))
}

#' @rdname pull_model
#' @export
show_model <- function(model = NULL, server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server", default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/show") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::list_flatten(name_spec = "{inner}") |>
    tibble::as_tibble()
}


#' List models that are available locally.
#'
#' @return a tibble of installed models
#' @export
list_models <- function() {
  httr2::request(server) |>
    httr2::req_url_path_append("/api/tags") |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::pluck("models") |>
    purrr::map(\(x) purrr::list_flatten(x, name_spec = "{inner}")) |>
    dplyr::bind_rows()
}
