#' Pull, push, show and delete models
#'
#' @details
#' - `pull_model()`: downloads a model from the Ollama registry or Hugging Face
#' - `push_model()`: uploads a locally created model to the Ollama registry
#'   (ollama.com) so others can pull it. The model name must include your
#'   namespace (i.e. `"your_username/model_name"`). Before pushing you need to
#'   add your public key (`~/.ollama/id_ed25519.pub`) to your ollama.com account
#'   settings. This is mainly useful after `create_model()` — you build a custom
#'   model locally (e.g. with a system prompt, quantisation, or fine-tuned
#'   weights) and then share it with collaborators or the public. You can also
#'   push to a private/self-hosted registry by using a model name that starts
#'   with the registry host (e.g. `"registry.example.com/mymodel"`); set
#'   `insecure = TRUE` if that registry does not use HTTPS.
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
#' @param background download model(s) in background without blocking the session.
#' @param insecure allow insecure connections to the library. Only use this if
#'   you are pulling from your own library during development.
#' @param destination name of the copied model.
#' @param detailed when `TRUE`, the column `model_info` will contain much more
#'   detailed information about the model.
#' @inheritParams query
#'
#' @return (invisible) a tibble with information about the model (except in
#'   `delete_model` and `push_model`)
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
#' # create a custom model and share it on ollama.com
#' create_model("your_username/mario", from = "llama3.1",
#'              system = "You are Mario from Super Mario Bros.")
#' push_model("your_username/mario")
#' }
pull_model <- function(
  model = NULL,
  server = NULL,
  insecure = FALSE,
  background = FALSE,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }
  if (!all(ping_ollama(server = server, silent = TRUE))) {
    cli::cli_alert_danger("Could not connect to Ollama at {.url {server}}")
  }
  if (length(model) > 1L) {
    for (m in model) {
      pull_model(m, server, insecure, background, verbose)
    }
  }

  req <- httr2::request(server) |>
    httr2::req_url_path_append("/api/pull") |>
    httr2::req_body_json(list(model = model, insecure = insecure)) |>
    httr2::req_headers(!!!get_headers())

  if (verbose) {
    done <- stream_progress(req, verbose, background)
    cli::cli_process_done(.envir = the)
  } else {
    resp <- httr2::req_perform(req)
    done <- httr2::resp_status(resp) < 400L
  }

  if (done) {
    cli::cli_alert_success("model {model} pulled successfully!")
    return(invisible(show_model(model)))
  } else {
    cli::cli_alert_success("model {model} downloading in background")
  }
}


#' @rdname pull_model
#'
#' @note `push_model()` is intended for advanced users. It requires setup steps
#'   that must be completed outside of R: you need an account on
#'   \url{https://ollama.com}, and your Ollama public key
#'   (`~/.ollama/id_ed25519.pub` on Linux/macOS) must be registered in your
#'   account settings. The model name must be prefixed with your ollama.com
#'   username (e.g. `"your_username/model_name"`); pushing without a namespace
#'   will fail with a permission error. Unfortunately, more user-friendly
#'   guidance cannot be provided here as the setup process is managed entirely
#'   by Ollama outside of R.
#'
#' @export
push_model <- function(
  model,
  server = NULL,
  insecure = FALSE,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  req <- httr2::request(server) |>
    httr2::req_url_path_append("/api/push") |>
    httr2::req_body_json(list(model = model, insecure = insecure)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_headers(!!!get_headers())

  if (verbose) {
    done <- stream_progress(req, verbose, background = FALSE)
    cli::cli_process_done(.envir = the)
  } else {
    resp <- httr2::req_perform(req)
    done <- httr2::resp_status(resp) < 400L
  }

  if (done) {
    cli::cli_alert_success("model {model} pushed successfully!")
  }
  invisible(NULL)
}


#' @rdname pull_model
#' @export
show_model <- function(model = NULL, detailed = FALSE, server = NULL) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }
  if (length(model) != 1L) {
    cli::cli_abort("{.code model} needs to be one model name.")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/show") |>
    httr2::req_body_json(list(model = model, verbose = detailed)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    as_tibble_onerow()
}


#' Create a model from a Modelfile
#'
#' @param model name of the model to create
#' @param from existing model to create from
#' @param template prompt template to use for the model
#' @param license license string or list of licenses for the model
#' @param system system prompt to embed in the model
#' @param parameters key-value parameters for the model
#' @param messages message history to use for the model (array of ChatMessage objects)
#' @param quantize quantization level to apply (e.g. `"q4_K_M"`, `"q8_0"`)
#' @param stream stream status updates (default: `TRUE`)
#' @param ... additional arguments (currently unused)
#' @inheritParams query
#'
#' @details Custom models are the way to save your system message and model
#'   parameters in a dedicated shareable way. If you use `show_model()`, you can
#'   look at the configuration of a model in the column modelfile. To get more
#'   information and a list of valid parameters, check out
#'   <https://docs.ollama.com/modelfile>. Most
#'   options are also available through the `query` and `chat` functions, yet
#'   are not persistent over sessions.
#'
#'
#' @return (invisible) a tibble with information about the created model
#' @export
#'
#' @examplesIf ping_ollama(silent = TRUE)
#' create_model("mario", from = "llama3.1", system = "You are mario from Super Mario Bros.")
create_model <- function(
  model,
  from = NULL,
  template = NULL,
  license = NULL,
  system = NULL,
  parameters = NULL,
  messages = NULL,
  quantize = NULL,
  stream = TRUE,
  ...,
  server = NULL,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }
  if ("modelfile" %in% names(list(...))) {
    cli::cli_warn("the parameter modelfile is deprecated")
  }

  # flush progress
  the$str_prgs <- NULL
  req <- httr2::request(server) |>
    httr2::req_url_path_append("/api/create") |>
    httr2::req_method("POST") |>
    httr2::req_body_json(list(
      model = model,
      from = from,
      template = template,
      license = license,
      system = system,
      parameters = parameters,
      messages = messages,
      quantize = quantize,
      stream = stream
    )) |>
    httr2::req_headers(!!!get_headers())

  if (stream) {
    stream_progress(req, background = FALSE, verbose)
  } else {
    httr2::req_perform(req)
  }

  cli::cli_process_done(.envir = the)
  the$str_prgs <- NULL

  model_info <- show_model(model) # move here to test if model was created
  cli::cli_alert_success("model {model} created")
  invisible(model_info)
}


#' @rdname pull_model
#' @export
delete_model <- function(model, server = NULL) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/delete") |>
    httr2::req_method("DELETE") |>
    httr2::req_body_json(list(model = model)) |>
    httr2::req_error(body = function(resp) httr2::resp_body_json(resp)$error) |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform()

  cli::cli_alert_success("model {model} removed")
}


#' @rdname pull_model
#' @export
copy_model <- function(
  model,
  destination = paste0(model, "-copy"),
  server = NULL
) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/copy") |>
    httr2::req_body_json(list(source = model, destination = destination)) |>
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
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/tags") |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    purrr::pluck("models") |>
    purrr::map(\(x) purrr::list_flatten(x, name_spec = "{inner}")) |>
    dplyr::bind_rows()
}

#' List running models
#'
#' @inheritParams query
#'
#' @return a tibble of running models
#' @export
list_running_models <- function(server = NULL) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  httr2::request(server) |>
    httr2::req_url_path_append("/api/ps") |>
    httr2::req_headers(!!!get_headers()) |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE) |>
    purrr::pluck("models") |>
    tibble::as_tibble()
}
