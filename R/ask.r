#' Chat with a LLM through Oolama
#'
#' @param q the question.
#' @param model which model to use. See <https://ollama.ai/library>
#' @param screen Logical. Should the answer be printed to the screen.
#' @param server URL to an Oolama server (not the API)
#'
#' @return an httr2 response
#' @export
#'
#' @examples
#' \dontrun{
#' ask("why is the sky blue?")
#' }
ask <- function(q,
                model = "llama2",
                screen = TRUE,
                server = "http://localhost:11434") {

  msg <- list(model = "mistral",
              messages = data.frame(role = "user",
                                    content = q),
              stream = FALSE)

  if (interactive()) cli::cli_progress_step("{model} is thinking {cli::pb_spin}")

  rp <- callr::r_bg(make_req,
                    args = list(msg = msg,
                                server = server),
                    package = TRUE)

  if (interactive()) while (rp$is_alive()) {
    cli::cli_progress_update()
    Sys.sleep(2 / 100)
  }

  resp <- rp$get_result()

  if (interactive()) cli::cli_progress_done()

  if (screen) {
    screen_answer(purrr::pluck(resp, "message", "content"))
  }
  invisible(resp)
}

make_req <- function(msg, server) {
  httr2::request(server) |>
    httr2::req_url_path_append("/api/chat") |>
    httr2::req_body_json(msg) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
}

screen_answer <- function(x) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
}


