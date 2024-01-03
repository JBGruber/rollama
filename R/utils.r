# package environment
the <- new.env()

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

  the$str_prgs$stream_resp <- c(the$str_prgs$stream_resp, resp)
  resp <- the$str_prgs$stream_resp

  status <- strsplit(rawToChar(resp), "\n")[[1]] |>
    grep("}$", x = _, value = TRUE) |>
    textConnection() |>
    jsonlite::stream_in(verbose = FALSE, simplifyVector = FALSE)

  status <- setdiff(status, the$str_prgs$pb_done)

  for (s in status) {

    if (!purrr::pluck_exists(s, "total")) {
      cli::cli_progress_step(purrr::pluck(s, "status"), .envir = the)
    } else {
      the$str_prgs$f <- sub("pulling ", "", purrr::pluck(s, "status"))
      the$str_prgs$done <- purrr::pluck(s, "completed", .default = 0L)
      the$str_prgs$total <-  purrr::pluck(s, "total", .default = 0L)
      if (!isTRUE(the$str_prgs$pb == the$str_prgs$f)) {
        cli::cli_progress_bar(
          name = the$str_prgs$f,
          type = "download",
          format = paste0(
            "{cli::pb_spin} Downloading {str_prgs$f} ",
            "[{str_prgs$done}/{str_prgs$total}] ETA:{cli::pb_eta}"
          ),
          format_done = paste0(
            "{cli::col_green(cli::symbol$tick)} Downloaded f ",
            "in {cli::pb_elapsed}."
          ),
          total = the$str_prgs$total,
          .envir = the
        )
        the$str_prgs$pb <- the$str_prgs$f
      } else {
        if ( the$str_prgs$total > the$str_prgs$done) {
          cli::cli_progress_update(force = TRUE, .envir = the)
        } else {
          cli::cli_process_done(.envir = the)
          the$str_prgs$pb <- NULL
        }
      }
    }
    the$str_prgs$pb_done <- append(the$str_prgs$pb_done, list(s))
  }
  TRUE
}
