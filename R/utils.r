# package environment
the <- new.env()

#' Ping server to see if Ollama is reachable
#'
#' @param silent suppress warnings and status (only return `TRUE`/`FALSE`).
#' @inheritParams query
#'
#' @return TRUE if server is running
#' @export
ping_ollama <- function(server = NULL, silent = FALSE) {

  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  res <- try({
    httr2::request(server) |>
      httr2::req_perform() |>
      httr2::resp_body_string()
  }, silent = TRUE)

  if (!methods::is(res, "try-error") & res == "Ollama is running") {
    if (!silent) cli::cli_inform(
      "{cli::col_green(cli::symbol$play)} {res} at {.url {server}}!"
    )
    invisible(TRUE)
  } else {
    if (!silent) {
      cli::cli_alert_danger("Could not connect to Ollama at {.url {server}}")
      print(res)
    }
    invisible(FALSE)
  }

}


build_req <- function(model, msg, server, images, model_params, template) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama2")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")

  req_data <- list(model = model,
                   messages = msg,
                   stream = FALSE,
                   options = model_params,
                   template = template) |>
    purrr::compact()

  if (getOption("rollama_verbose", default = interactive())) {
    cli::cli_progress_step("{model} is thinking {cli::pb_spin}")
    rp <- callr::r_bg(make_req,
                      args = list(req_data = req_data,
                                  server = server,
                                  endpoint = "/api/chat"),
                      package = TRUE)
    while (rp$is_alive()) {
      cli::cli_progress_update()
      Sys.sleep(2 / 100)
    }
    resp <- rp$get_result()
    cli::cli_progress_done()
  } else {
    resp <- make_req(req_data, server, "/api/chat")
  }

  if (!is.null(resp$error)) {
    if (grepl("model.+not found, try pulling it first", resp$error)) {
      resp$error <- paste(resp$error, "with {.code pull_model(\"{model}\")}")
    }
    cli::cli_abort(resp$error)
  }

  return(resp)
}


make_req <- function(req_data, server, endpoint) {
  httr2::request(server) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_body_json(prep_req_data(req_data), auto_unbox = FALSE) |>
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


# the requirements for the data are a little weird as boxes can only show up in
# very particular places in the json string.
prep_req_data <- function(tbl) {
  if (purrr::pluck_exists(tbl, "options")) {
    tbl$options <- purrr::map(tbl$option, jsonlite::unbox)
  }
  purrr::map(tbl, function(x) {
    if (!is.list(x)) {
      jsonlite::unbox(x)
    } else {
      x
    }
  })
}


# function to display progress in streaming operations
pgrs <- function(resp) {
  if (!getOption("rollama_verbose", default = interactive())) return(TRUE)
  the$str_prgs$stream_resp <- c(the$str_prgs$stream_resp, resp)
  resp <- the$str_prgs$stream_resp

  status <- strsplit(rawToChar(resp), "\n")[[1]] |>
    grep("}$", x = _, value = TRUE) |>
    textConnection() |>
    jsonlite::stream_in(verbose = FALSE, simplifyVector = FALSE)

  status <- setdiff(status, the$str_prgs$pb_done)

  for (s in status) {
    status_message <- purrr::pluck(s, "status")
    if (!purrr::pluck_exists(s, "total")) {
      if (status_message == "success") {
        cli::cli_progress_message("{cli::col_green(cli::symbol$tick)} success!")
      } else {
        cli::cli_progress_step(purrr::pluck(s, "status"), .envir = the)
      }
    } else {
      the$str_prgs$f <- sub("pulling ", "", purrr::pluck(s, "status"))
      the$str_prgs$done <- purrr::pluck(s, "completed", .default = 0L)
      the$str_prgs$total <-  purrr::pluck(s, "total", .default = 0L)
      the$str_prgs$done_pct <-
        paste(round(the$str_prgs$done / the$str_prgs$total * 100, 0), "%")
      if (the$str_prgs$done != the$str_prgs$total) {
        the$str_prgs$speed <-
          prettyunits::pretty_bytes(
            the$str_prgs$done /
              (as.integer(Sys.time()) - as.integer(the$str_prgs$pb_start))
          )
      } else the$str_prgs$speed <- 1L

      if (!isTRUE(the$str_prgs$pb == the$str_prgs$f)) {
        cli::cli_progress_bar(
          name = the$str_prgs$f,
          type = "download",
          format = paste0(
            "{cli::pb_spin} downloading {str_prgs$f} ",
            "({str_prgs$done_pct} of {prettyunits::pretty_bytes(str_prgs$total)}) ",
            "at {str_prgs$speed}/s"
          ),
          format_done = paste0(
            "{cli::col_green(cli::symbol$tick)} downloaded {str_prgs$f}"
          ),
          .envir = the
        )
        the$str_prgs$pb <- the$str_prgs$f
        the$str_prgs$pb_start <- Sys.time()
      } else {
        if (the$str_prgs$total > the$str_prgs$done) {
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

