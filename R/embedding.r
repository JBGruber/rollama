#' Generate Embeddings
#'
#' @param text text vector to generate embeddings for.
#' @inheritParams query
#'
#' @return a tibble with embeddings.
#' @export
#'
#' @examples
#' \dontrun{
#' embed_text(c("Here is an article about llamas...",
#'              "R is a language and environment for statistical computing and graphics."))
#' }
embed_text <- function(text,
                       model = NULL,
                       server = NULL) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server", default = "http://localhost:11434")
  spinner <- getOption("rollama_spinner", default = interactive())

  purrr::map(seq_along(text), function(i) {
    req_data <- list(model = model,
                     prompt = text[i],
                     stream = FALSE)

    if (spinner) {
      cli::cli_progress_step("{cli::pb_spin} {model} is embedding text {i}", )
      rp <- callr::r_bg(make_req,
                        args = list(req_data = req_data,
                                    server = server,
                                    endpoint = "/api/embeddings"),
                        package = TRUE)
      while (rp$is_alive()) {
        cli::cli_progress_update()
        Sys.sleep(2 / 100)
      }
      resp <- rp$get_result()
      cli::cli_progress_done()
    } else {
      resp <- make_req(req_data, server, "/api/embeddings")
    }

    if (!is.null(resp$error)) {
      if (grepl("model.+not found, try pulling it first", resp$error)) {
        resp$error <- paste(resp$error, "with {.code pull_model(\"{model}\")}")
      }
      cli::cli_abort(resp$error)
    }
    names(resp$embedding) <- paste0("dim_", seq_along(resp$embedding))
    tibble::as_tibble(resp$embedding)
  }) |>
    dplyr::bind_rows()

}
