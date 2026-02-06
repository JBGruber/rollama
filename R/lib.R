#' Ping server to see if Ollama is reachable
#'
#' @param silent suppress warnings and status (only return `TRUE`/`FALSE`).
#' @param version return version instead of `TRUE`.
#' @inheritParams query
#'
#' @return TRUE if server is running
#' @export
ping_ollama <- function(server = NULL, silent = FALSE, version = FALSE) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  out <- purrr::map(server, function(sv) {
    res <- try(
      {
        httr2::request(sv) |>
          httr2::req_url_path("api/version") |>
          httr2::req_perform() |>
          httr2::resp_body_json()
      },
      silent = TRUE
    )

    if (!methods::is(res, "try-error") && purrr::pluck_exists(res, "version")) {
      if (!silent) {
        cli::cli_inform(
          "{cli::col_green(cli::symbol$play)} Ollama (v{res$version}) is running at {.url {sv}}!"
        )
      }
      if (version) {
        return(res$version)
      }
      return(TRUE)
    } else {
      if (!silent) {
        cli::cli_alert_danger("Could not connect to Ollama at {.url {sv}}")
      }
      return(FALSE)
    }
  })
  invisible(unlist(out))
}


perform_reqs <- function(reqs, verbose) {
  model <- purrr::map_chr(reqs, c("body", "data", "model")) |>
    unique()
  pb <- FALSE
  if (!is.logical(verbose)) {
    pb <- verbose
  } else if (verbose) {
    pb <- list(
      clear = TRUE,
      format = c(
        "{cli::pb_spin} {getOption('model')} {?is/are} thinking about ",
        "{cli::pb_total - cli::pb_current}/{cli::pb_total} question{?s}",
        "[ETA: {cli::pb_eta}]"
      )
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
    throw_error(fails)
  }

  httr2::resps_successes(resps)
}


perform_req <- function(reqs, verbose) {
  if (verbose) {
    model <- purrr::map_chr(reqs, c("body", "data", "model")) |>
      unique()

    id <- cli::cli_progress_bar(
      format = "{cli::pb_spin} {model} {?is/are} thinking",
      clear = TRUE
    )

    # turn off errors since error messages can't be seen in sub-process
    req <- httr2::req_error(reqs[[1]], is_error = function(resp) FALSE)
    # httr2 > 1.2.0 uses weak references to redact tokens, which do not survive
    # into sub-processes
    req$headers <- httr2::req_get_headers(req, redacted = "reveal")
    rp <- callr::r_bg(
      httr2::req_perform,
      args = list(req = req),
      package = TRUE
    )

    while (rp$is_alive()) {
      cli::cli_progress_update(id = id)
      Sys.sleep(2 / 100)
    }
    resp <- rp$get_result()
    res <- httr2::resp_body_json(resp)
    if (purrr::pluck_exists(res, "error")) {
      cli::cli_abort(purrr::pluck(res, "error"))
    }
    return(list(resp))
  }

  reqs[[1]] |>
    httr2::req_error(body = function(resp) {
      httr2::resp_body_json(resp) |>
        purrr::pluck("error", .default = "unknown error")
    }) |>
    httr2::req_perform() |>
    list()
}


get_headers <- function() {
  agent <- the$agent
  if (is.null(agent)) {
    sess <- utils::sessionInfo()
    the$agent <- agent <- paste0(
      "rollama/",
      utils::packageVersion("rollama"),
      "(",
      sess$platform,
      ") ",
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
  purrr::modify_tree(tbl, leaf = function(x) {
    if (length(x) == 1L) {
      jsonlite::unbox(x)
    } else {
      x
    }
  })
}
