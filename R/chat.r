#' Chat with a LLM through Oolama
#'
#' @details `query` sends a single question to the API, without knowledge about
#'   previous questions (only the config message is relevant). `chat` treats new
#'   messages as part of the same conversation until \link{new_chat} is called.
#'
#'
#' @param q the question as a character string or a conversation object.
#' @param model which model to use. See <https://ollama.ai/library> for options.
#'   Default is "llama2". Set option(rollama_model = "modelname") to change
#'   default for the current session.
#' @param screen Logical. Should the answer be printed to the screen.
#' @param server URL to an Oolama server (not the API). Defaults to
#'   "http://localhost:11434".
#'
#' @return an httr2 response
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
#' }
query <- function(q,
                  model = NULL,
                  screen = TRUE,
                  server = NULL) {

  if (!is.list(q)) {
    config <- getOption("rollama_config", default = NULL)
    msg <- do.call(rbind, list(
      if (!is.null(config)) data.frame(role = "system",
                                       content = config),
      data.frame(role = "user", content = q)
    ))
  } else {
    msg <- q
    if (!"user" %in% msg$role && nchar(msg$content) > 0)
      cli::cli_abort(paste("If you supply a conversation object, it needs at",
                            "least one user message. See {.help query}."))
  }

  resp <- build_req(model = model, msg = msg, server = server)
  if (screen) screen_answer(purrr::pluck(resp, "message", "content"))
  invisible(resp)
}


#' @rdname query
#' @export
chat <- function(q,
                 model = NULL,
                 screen = TRUE,
                 server = NULL) {

  config <- getOption("rollama_config", default = NULL)
  hist <- c(rbind(the$prompts, the$responses))

  # save prompt
  the$prompts <- c(the$prompts, q)

  msg <- do.call(rbind, (list(
    if (!is.null(config)) data.frame(role = "system",
                                     content = config),
    if (length(hist) > 0) data.frame(role = c("user", "assistant"),
                                     content = hist),
    data.frame(role = "user", content = q)
  )))
  resp <- query(q = msg, model = model, screen = screen, server = server)

  # save response
  the$responses <- c(the$responses, purrr::pluck(resp, "message", "content"))

  invisible(resp)
}


#' Start a new conversation
#'
#' Deletes the local prompt and response history to start a new conversation.
#'
#' @return Does not return a value
#' @export
new_chat <- function() {
  the$responses <- NULL
  the$prompts <- NULL
}
