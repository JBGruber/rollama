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
#' orca-mini:3b-q4_1 and llama3.1:70b. The tag is optional and, if not provided,
#' will default to latest. The tag is used to identify a specific version.
#'
#' @param model name of the model(s). Defaults to "llama3.1" when `NULL` (except
#'   in `delete_model`).
#' @param insecure allow insecure connections to the library. Only use this if
#'   you are pulling from your own library during development.
#' @param destination name of the copied model.
#' @inheritParams query
#'
#' @return (invisible) a tibble with information about the model (except in
#'   `delete_model`)
#' @export
#'
#' @examples
#' \dontrun{
#' # download a model and save information in an object
#' model_info <- pull_model("mixtral")
#' # after you pull, you can get the same information with:
#' model_info <- show_model("mixtral")
#' # pulling models from Hugging Face Hub is also possible
#' pull_model("https://huggingface.co/oxyapi/oxy-1-small-GGUF:Q2_K")
#' }
pull_model <- function(model = NULL,
                       server = NULL,
                       insecure = FALSE,
                       verbose = getOption("rollama_verbose",
                                           default = interactive())) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama3.1")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  if (length(model) > 1L) {
    for (m in model) pull_model(m, server, insecure, verbose)
  }

  # flush progress
  the$str_prgs <- NULL
  req <- httr2::request(server) |>
    httr2::req_url_path_append("/api/pull") |>
    httr2::req_body_json(list(name = model, insecure = insecure)) |>
    httr2::req_headers(!!!get_headers())
  if (verbose) {
    httr2::req_perform_stream(req, callback = pgrs, buffer_kb = 0.1)
    cli::cli_process_done(.envir = the)
  } else {
    httr2::req_perform(req)
  }
  total <- try(as.integer(the$str_prgs$total), silent = TRUE)
  if (methods::is(total, "try-error")) {
    cli::cli_alert_success("model {model} pulled succesfully")
  } else {
    total <- prettyunits::pretty_bytes(total)
    cli::cli_alert_success("model {model} ({total}) pulled succesfully")
  }
  the$str_prgs <- NULL

  invisible(show_model(model))
}


#' @rdname pull_model
#' @export
show_model <- function(model = NULL, server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama3.1")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  if (length(model) != 1L) cli::cli_abort("model needs to be one model name.")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/show") |>
    httr2::req_body_json(list(name = model)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::list_flatten(name_spec = "{inner}") |>
    as_tibble_onerow()
}


#' Create a model from a Modelfile
#'
#' @param model name of the model to create
#' @param modelfile either a path to a model file to be read or the contents of
#'   the model file as a character vector.
#' @inheritParams query
#'
#' @details Custom models are the way to save your system message and model
#'   parameters in a dedicated shareable way. If you use `show_model()`, you can
#'   look at the configuration of a model in the column modelfile. To get more
#'   information and a list of valid parameters, check out
#'   <https://github.com/ollama/ollama/blob/main/docs/modelfile.md>. Most
#'   options are also available through the `query` and `chat` functions, yet
#'   are not persistent over sessions.
#'
#'
#' @return Nothing. Called to create a model on the Ollama server.
#' @export
#'
#' @examples
#' modelfile <- system.file("extdata", "modelfile.txt", package = "rollama")
#' \dontrun{create_model("mario", modelfile)}
#' modelfile <- "FROM llama3.1\nSYSTEM You are mario from Super Mario Bros."
#' \dontrun{create_model("mario", modelfile)}
create_model <- function(model, modelfile, server = NULL) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  if (isTRUE(file.exists(modelfile))) {
    modelfile <- readChar(modelfile, file.size(modelfile))
  } else if (length(modelfile) > 1) {
    modelfile <- paste0(modelfile, collapse = "\n")
  }

  # flush progress
  the$str_prgs <- NULL
  httr2::request(server) |>
    httr2::req_url_path_append("/api/create") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(list(name = model, modelfile = modelfile)) |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform_stream(callback = pgrs, buffer_kb = 0.1)

  cli::cli_process_done(.envir = the)
  the$str_prgs <- NULL

  model_info <- show_model(model) # move here to test if model was created
  cli::cli_alert_success("model {model} created")
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
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform()

  cli::cli_alert_success("model {model} removed")
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
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform()

  cli::cli_alert_success("model {model} copied to {destination}")
}


#' List models that are available locally.
#'
#' @inheritParams query
#'
#' @return a tibble of installed models
#' @export
list_models <- function(server = NULL) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  httr2::request(server) |>
    httr2::req_url_path_append("/api/tags") |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::pluck("models") |>
    purrr::map(\(x) purrr::list_flatten(x, name_spec = "{inner}")) |>
    dplyr::bind_rows()
}
