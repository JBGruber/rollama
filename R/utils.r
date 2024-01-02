# package environment
the <- new.env(parent = emptyenv())

build_req <- function(model, msg, server) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server", default = "http://localhost:11434")
  spinner <- getOption("rollama_spinner", default = interactive())

  req_data <- list(model = model,
                   messages = msg,
                   stream = FALSE)

  if (spinner) {
    cli::cli_progress_step("{model} is thinking {cli::pb_spin}")
    rp <- callr::r_bg(make_req,
                      args = list(req_data = req_data,
                                  server = server),
                      package = TRUE)
    while (rp$is_alive()) {
      if (interactive()) cli::cli_progress_update()
      Sys.sleep(2 / 100)
    }
    resp <- rp$get_result()
    if (interactive()) cli::cli_progress_done()
  } else {
    resp <- make_req(req_data, server)
  }

  if (!is.null(resp$error)) {
    if (grepl("model.+not found, try pulling it first", resp$error)) {
      resp$error <- paste(resp$error, "with {.code pull_model(\"{model}\")}")
    }
    cli::cli_abort(resp$error)
  }

  return(resp)
}


make_req <- function(req_data, server) {
  httr2::request(server) |>
    httr2::req_url_path_append("/api/chat") |>
    httr2::req_body_json(req_data) |>
    # turn off errors since error messages can't be seen in sub-process
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
}


screen_answer <- function(x) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
}


# function to display progress in streaming operations
pgrs <- function(resp) {
  rawToChar(resp) |>
    cat()
  TRUE
}
