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

  out <- purrr::map_lgl(server, function(sv) {
    res <- try({
      httr2::request(sv) |>
        httr2::req_url_path("api/version") |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    }, silent = TRUE)

    if (!methods::is(res, "try-error") && purrr::pluck_exists(res, "version")) {
      if (!silent) cli::cli_inform(
        "{cli::col_green(cli::symbol$play)} Ollama (v{res$version}) is running at {.url {sv}}!"
      )
      return(TRUE)
    } else {
      if (!silent) {
        cli::cli_alert_danger("Could not connect to Ollama at {.url {sv}}")
      }
      return(FALSE)
    }
  })
  invisible(all(out))
}


build_req <- function(model,
                      msg,
                      server,
                      images,
                      model_params,
                      format,
                      template) {

  if (is.null(model)) model <- getOption("rollama_model", default = "llama3.1")
  if (is.null(server)) server <- getOption("rollama_server",
                                           default = "http://localhost:11434")
  seed <- getOption("rollama_seed")
  if (!is.null(seed) && !purrr::pluck_exists(model_params, "seed")) {
    model_params <- append(model_params, list(seed = seed))
  }
  check_model_installed(model, server = server)
  req_data <- purrr::map(msg, function(ms) {
    purrr::map(model, function(m) {
      list(model = m,
           messages = ms,
           stream = FALSE,
           options = model_params,
           format = format,
           template = template) |>
        purrr::compact() |> # remove NULL values
        make_req(server = sample(server, 1, prob = as_prob(names(server))),
                 endpoint = "/api/chat",
                 perform = FALSE)
    })
  }) |>
    unlist(recursive = FALSE)

  return(req_data)
}


make_req <- function(req_data, server, endpoint, perform = TRUE) {
  r <- httr2::request(server) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_body_json(prep_req_data(req_data), auto_unbox = FALSE) |>
    # turn off errors since error messages can't be seen in sub-process
    httr2::req_error(is_error = function(resp) FALSE) |>
    # see https://github.com/JBGruber/rollama/issues/23
    httr2::req_options(timeout_ms = 1000 * 60 * 60 * 24,
                       connecttimeout_ms = 1000 * 60 * 60 * 24) |>
    httr2::req_headers(!!!get_headers())
  if (perform) {
    r <- r |>
      httr2::req_perform() |>
      httr2::resp_body_json()
  }
  return(r)
}


perform_reqs <- function(reqs, verbose) {

  model <- purrr::map_chr(reqs, c("body", "data", "model")) |>
    unique()
  pb <- FALSE
  if (verbose) {
    pb <- list(
      clear = TRUE,
      format = c("{cli::pb_spin} {getOption('model')} {?is/are} thinking about ",
                 "{cli::pb_total - cli::pb_current}/{cli::pb_total} question{?s}")
    )
  }

  withr::with_options(list(cli.progress_show_after = 0, model = model), {
    resps <- httr2::req_perform_parallel(
      reqs = reqs,
      on_error = "continue",
      progress = pb
    )
  })

  fails <- httr2::resps_failures(resps) |>
    purrr::map_chr("message")

  # all fails
  if (length(fails) == length(reqs)) {
    cli::cli_abort(fails)
  } else if (length(fails) < length(reqs) && length(fails) > 0) {
    error_counts <- table(fails)
    for (f in names(error_counts)) {
      if (error_counts[f] > 2) {
        cli::cli_alert_danger("error ({error_counts[f]} times): {f}")
      } else {
        cli::cli_alert_danger("error: {f}")
      }
    }
    for (f in fails) {
      cli::cli_alert_danger(f)
    }
  }

  httr2::resps_successes(resps)
}


perform_req <- function(reqs, verbose) {

  if (verbose) {
    model <- purrr::map_chr(reqs, c("body", "data", "model")) |>
      unique()

    id <- cli::cli_progress_bar(format = "{cli::pb_spin} {model} {?is/are} thinking",
                                clear = TRUE)

    rp <- callr::r_bg(httr2::req_perform,
                      args = list(req = reqs[[1]]),
                      package = TRUE)

    while (rp$is_alive()) {
      cli::cli_progress_update(id = id)
      Sys.sleep(2 / 100)
    }
    return(list(rp$get_result()))
  }

  list(httr2::req_perform(reqs[[1]]))
}


get_headers <- function() {
  agent <- the$agent
  if (is.null(agent)) {
    sess <- utils::sessionInfo()
    the$agent <- agent <- paste0(
      "rollama/", utils::packageVersion("rollama"),
      "(", sess$platform, ") ",
      sess$R.version$version.string
    )
  }
  list(
    "Content-Type" = "application/json",
    "Accept" = "application/json",
    "User-Agent" = agent,
    # get additional headers from option (if set)
    getOption("rollama_headers")
  ) |>
    unlist()
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

  status <- strsplit(rawToChar(resp), "\n")[[1]]
  status <- grep("}$", x = status, value = TRUE) |>
    textConnection() |>
    jsonlite::stream_in(verbose = FALSE, simplifyVector = FALSE)

  status <- setdiff(status, the$str_prgs$pb_done)

  for (s in status) {
    status_message <- purrr::pluck(s, "status")
    if (!purrr::pluck_exists(s, "total")) {
      if (isTRUE(status_message == "success")) {
        cli::cli_progress_message("{cli::col_green(cli::symbol$tick)} success!")
      } else if (purrr::pluck_exists(s, "error")) {
        cli::cli_abort(purrr::pluck(s, "error"))
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
          the$str_prgs$done /
          (as.integer(Sys.time()) - as.integer(the$str_prgs$pb_start))
        if (is.numeric(the$str_prgs$speed))
          the$str_prgs$speed <- prettyunits::pretty_bytes(the$str_prgs$speed)
      } else {
        the$str_prgs$speed <- 1L
      }

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
