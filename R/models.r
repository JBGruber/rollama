#' Pull, show and delete models
#'
#' @details
#' - `pull_model()`: downloads model
#' - `show_model()`: displays information about a local model
#' - `copy_model()`: creates a model with another name from an existing model
#' - `delete_model()`: deletes local model
#'
#' **Model names**: Model names follow a model:tag format, where model can have
#' an optional namespace such as example/model. Some examples are
#' orca-mini:3b-q4_1 and llama2:70b. The tag is optional and, if not provided,
#' will default to latest. The tag is used to identify a specific version.
#'
#' @param model name of the model. Defaults to "llama2" when `NULL` (except in
#'   `delete_model`).
#' @param destination name of the copied model.
#' @inheritParams query
#'
#' @return (invisible) a tibble with information about the model (except in
#'   `delete_model`)
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
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/pull") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_perform_stream(callback = pgrs, buffer_kb = 0.1)

  cli::cli_process_done(.envir = the)
  the$str_prgs <- NULL

  invisible(show_model(model))
}


#' @rdname pull_model
#' @export
show_model <- function(model = NULL, server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/show") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::list_flatten(name_spec = "{inner}") |>
    tibble::as_tibble()
}


#' Create a model from a Modelfile
#'
#' @param model name of the model to create
#' @param modelfile either a path to a model file to be read or the contents of
#'   the model file as a character vector.
#' @inheritParams query
#'
#' @details Custom models are the way to change paramters in Ollama. If you use
#' `show_model()`, you can look at the configuration of a model in the column
#' modelfile. To get more information and a list of valid parameters, check out
#' <https://github.com/jmorganca/ollama/blob/main/docs/modelfile.md>.
#'
#'
#' @return Nothing. Called to create a model on the Ollama server.
#' @export
#'
#' @examples
#' modelfile <- system.file("extdata", "modelfile.txt", package = "rollama")
#' \dontrun{create_model("mario", modelfile)}
#' modelfile <- "FROM llama2\nSYSTEM You are mario from Super Mario Bros."
#' \dontrun{create_model("mario", modelfile)}
create_model <- function(model, modelfile, server = NULL) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  if (file.exists(modelfile)) {
    modelfile <- readChar(modelfile, file.size(modelfile))
  } else if (length(modelfile) > 1) {
    modelfile <- paste0(modelfile, collapse = "\n")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/create") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(list(name = model, modelfile = modelfile)) |>
    httr2::req_perform_stream(callback = pgrs, buffer_kb = 0.1)

  cli::cli_process_done(.envir = the)
  the$str_prgs <- NULL

  model_info <- show_model(model) # move here to test if model was created
  cli::cli_progress_message(
    "{cli::col_green(cli::symbol$tick)} model {model} created"
  )
  invisible(model_info)
}


#' @rdname pull_model
#' @export
delete_model <- function(model, server = NULL) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/delete") |>
    httr2::req_method("DELETE") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_perform()

  cli::cli_progress_message(
    "{cli::col_green(cli::symbol$tick)} model {model} removed"
  )
}


#' @rdname pull_model
#' @export
copy_model <- function(model,
                       destination = paste0(model, "-copy"),
                       server = NULL) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/copy") |>
    httr2::req_body_json(list(source = model,
                              destination = destination)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_perform()

  cli::cli_progress_message(
    "{cli::col_green(cli::symbol$tick)} model {model} copied to {destination}"
  )
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
