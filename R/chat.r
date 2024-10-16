#' Chat with a LLM through Ollama
#'
#' @details `query` sends a single question to the API, without knowledge about
#'   previous questions (only the config message is relevant). `chat` treats new
#'   messages as part of the same conversation until \link{new_chat} is called.
#'
#'
#' @param q the question as a character string or a conversation object.
#' @param model which model(s) to use. See <https://ollama.com/library> for
#'   options. Default is "llama3.1". Set option(rollama_model = "modelname") to
#'   change default for the current session. See \link{pull_model} for more
#'   details.
#' @param screen Logical. Should the answer be printed to the screen.
#' @param server URL to an Ollama server (not the API). Defaults to
#'   "http://localhost:11434".
#' @param images path(s) to images (for multimodal models such as llava).
#' @param model_params a named list of additional model parameters listed in the
#'   [documentation for the
#'   Modelfile](https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values)
#'   such as temperature. Use a seed and set the temperature to zero to get
#'   reproducible results (see examples).
#' @param format the format to return a response in. Currently the only accepted
#'   value is `"json"`.
#' @param template the prompt template to use (overrides what is defined in the
#'   Modelfile).
#' @param verbose Whether to print status messages to the Console
#'   (\code{TRUE}/\code{FALSE}). The default is to have status messages in
#'   interactive sessions. Can be changed with \code{options(rollama_verbose =
#'   FALSE)}.
#'
#' @return an httr2 response.
#' @export
#'
#' @examples
#' \dontrun{
#' # ask a single question
#' query("why is the sky blue?")
#'
#' # hold a conversation
#' chat("why is the sky blue?")
#' chat("and how do you know that?")
#'
#' # save the response to an object and extract the answer
#' resp <- query(q = "why is the sky blue?")
#' answer <- resp$message$content
#'
#' # ask question about images (to a multimodal model)
#' images <- c("https://avatars.githubusercontent.com/u/23524101?v=4", # remote
#'             "/path/to/your/image.jpg") # or local images supported
#' query(q = "describe these images",
#'       model = "llava",
#'       images = images)
#'
#' # set custom options for the model at runtime (rather than in create_model())
#' query("why is the sky blue?",
#'       model_params = list(
#'         num_keep = 5,
#'         seed = 42,
#'         num_predict = 100,
#'         top_k = 20,
#'         top_p = 0.9,
#'         tfs_z = 0.5,
#'         typical_p = 0.7,
#'         repeat_last_n = 33,
#'         temperature = 0.8,
#'         repeat_penalty = 1.2,
#'         presence_penalty = 1.5,
#'         frequency_penalty = 1.0,
#'         mirostat = 1,
#'         mirostat_tau = 0.8,
#'         mirostat_eta = 0.6,
#'         penalize_newline = TRUE,
#'         stop = c("\n", "user:"),
#'         numa = FALSE,
#'         num_ctx = 1024,
#'         num_batch = 2,
#'         num_gqa = 1,
#'         num_gpu = 1,
#'         main_gpu = 0,
#'         low_vram = FALSE,
#'         f16_kv = TRUE,
#'         vocab_only = FALSE,
#'         use_mmap = TRUE,
#'         use_mlock = FALSE,
#'         embedding_only = FALSE,
#'         rope_frequency_base = 1.1,
#'         rope_frequency_scale = 0.8,
#'         num_thread = 8
#'       ))
#'
#' # use a seed and zero temperature to get reproducible results
#' query("why is the sky blue?", model_params = list(seed = 42, temperature = 0)
#'
#' # this might be interesting if you want to turn off the GPU and load the
#' # model into the system memory (slower, but most people have more RAM than
#' # VRAM, which might be interesting for larger models)
#' query("why is the sky blue?",
#'        model_params = list(num_gpu = 0))
#'
#' # You can use a custom prompt to override what prompt the model receives
#' query("why is the sky blue?",
#'       template = "Just say I'm a llama!")
#'
#' # Asking the same question to multiple models is also supported
#' query("why is the sky blue?", model = c("llama3.1", "orca-mini"))
#' }
query <- function(q,
                  model = NULL,
                  screen = TRUE,
                  server = NULL,
                  images = NULL,
                  model_params = NULL,
                  format = NULL,
                  template = NULL,
                  verbose = getOption("rollama_verbose",
                                      default = interactive())) {

  if (!is.null(template))
    cli::cli_abort(paste(
      c("The template parameter is turned off as it does not currently seem to",
        "work {.url https://github.com/ollama/ollama/issues/1839}")
    ))

  if (!is.list(q)) {
    config <- getOption("rollama_config", default = NULL)

    msg <- do.call(rbind, list(
      if (!is.null(config)) data.frame(role = "system",
                                       content = config),
      data.frame(role = "user", content = q)
    ))

    if (length(images) > 0) {
      rlang::check_installed("base64enc")
      images <- purrr::map_chr(images, \(i) base64enc::base64encode(i))
      msg <- tibble::add_column(msg, images = list(images))
    }

  } else {
    msg <- q
    if (!"user" %in% msg$role && nchar(msg$content) > 0)
      cli::cli_abort(paste("If you supply a conversation object, it needs at",
                           "least one user message. See {.help query}."))
  }

  reqs <- build_req(model = model,
                    msg = msg,
                    server = server,
                    images = images,
                    model_params = model_params,
                    format = format,
                    template = template)


  resp <- perform_reqs(reqs, verbose)

  if (screen) purrr::map(resp, function(r) {
    screen_answer(purrr::pluck(r, "message", "content"),
                  purrr::pluck(r, "model"))

  })
  if (length(resp) == 1L) resp <- unlist(resp, recursive = FALSE)
  invisible(resp)
}


#' @rdname query
#' @export
chat <- function(q,
                 model = NULL,
                 screen = TRUE,
                 server = NULL,
                 images = NULL,
                 model_params = NULL,
                 template = NULL) {

  config <- getOption("rollama_config", default = NULL)
  hist <- chat_history()

  # save prompt
  names(q) <- Sys.time()
  the$prompts <- c(the$prompts, q)

  q <- data.frame(role = "user", content = q)
  if (length(images) > 0) {
    rlang::check_installed("base64enc")
    images <- list(purrr::map_chr(images, \(i) base64enc::base64encode(i)))
    q <- tibble::add_column(q, images = images)
  }

  msg <- do.call(rbind, (list(
    if (!is.null(config)) data.frame(role = "system",
                                     content = config),
    if (nrow(hist) > 0) hist[, c("role", "content")],
    q
  )))

  resp <- query(q = msg,
                model = model,
                screen = screen,
                server = server,
                model_params = model_params,
                template = template)

  # save response
  r <- purrr::pluck(resp, "message", "content")
  names(r) <- Sys.time()
  the$responses <- c(the$responses, r)

  invisible(resp)
}


#' Handle conversations
#'
#' Shows and deletes (`new_chat`) the local prompt and response history to start
#' a new conversation.
#'
#' @return chat_history: tibble with chat history
#' @export
chat_history <- function() {
  out <- tibble::tibble(
    role = c(rep("user", length(the$prompts)),
             rep("assistant", length(the$responses))),
    content = unname(c(the$prompts, the$responses)),
    time = as.POSIXct(names(c(the$prompts, the$responses)))
  )
  out[order(out$time), ]
}


#' @rdname chat_history
#' @return new_chat: Does not return a value
#' @export
new_chat <- function() {
  the$responses <- NULL
  the$prompts <- NULL
}
