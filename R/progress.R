stream_answer <- function(req) {
  cli::cli_h1("Answer from {cli::style_bold({req$body$data$model})}")
  conn <- httr2::req_perform_connection(req)
  on.exit(close(conn))
  line <- answer <- character()
  repeat {
    resp <- httr2::resp_stream_lines(conn, lines = 1L) |>
      jsonlite::fromJSON()
    # for debugging
    # resp <- httr2::resp_stream_lines(conn, lines = 1L)
    # write(resp, "resp.json", append = TRUE)
    # resp <- jsonlite::fromJSON(resp)
    line <- c(line, purrr::pluck(resp, "message", "content"))
    if (!any(grepl("\n", line))) {
      cat("\r", line, sep = "")
    } else {
      cat("\r", line, sep = "")
      answer <- c(answer, line)
      line <- character()
    }
    if (httr2::resp_stream_is_complete(conn)) break
  }
  # to make the output the same as non-streaming
  answer <- c(answer, line)
  n_last <- length(purrr::pluck(resp, "message", "content"))
  purrr::pluck(resp, "message", "content", n_last) <- paste(
    answer,
    collapse = ""
  )
  return(resp)
}


stream_progress <- function(req, verbose, background, ...) {
  # set up connection
  the$str_prgs$pb_start <- Sys.time()
  conn <- httr2::req_perform_connection(req)
  on.exit(close(conn))

  # just set up connection and leave
  if (background) {
    return(invisible(FALSE))
  }

  # stream line by line until done
  repeat {
    status <- httr2::resp_stream_lines(conn, lines = 1)
    if (process_status(status, verbose)) break
  }
  return(invisible(TRUE))
}


# function to display progress in streaming operations
process_status <- function(status, verbose) {
  if (!getOption("rollama_verbose", default = interactive())) {
    # return FALSE to not break the loop
    return(FALSE)
  }
  # for debugging
  # write(status, file = "status.txt", append = TRUE)
  status <- try(jsonlite::fromJSON(status), silent = TRUE)
  if (methods::is(status, "try-error")) {
    return(FALSE)
  }

  status_message <- purrr::pluck(status, "status")
  # if total is missing, it's a step update or error
  if (!purrr::pluck_exists(status, "total")) {
    if (isTRUE(status_message == "success")) {
      if (verbose) {
        cli::cli_progress_message("{cli::col_green(cli::symbol$tick)} success!")
      }
      return(TRUE)
    } else if (purrr::pluck_exists(status, "error")) {
      cli::cli_abort("{purrr::pluck(status, \"error\")}")
    } else {
      if (verbose) cli::cli_progress_step(purrr::pluck(status, "status"))
    }
    return(FALSE)
  }

  layer <- sub("pulling ", "", purrr::pluck(status, "status"))
  done <- purrr::pluck(status, "completed", .default = 0L)
  total <- purrr::pluck(status, "total", .default = 0L)
  done_pct <- paste(round(done / total * 100, 0), "%")
  if (done != total) {
    speed <- tryCatch(
      {
        passed <- as.integer(Sys.time()) - as.integer(the$str_prgs$pb_start)
        as.integer(done / passed)
      },
      error = function(e) 0L,
      warning = function(w) 0L
    )
    if (!is.integer(speed)) speed <- 0
  } else {
    speed <- 0L
  }

  # copy some values to package env
  the$str_prgs$done_pct <- done_pct
  the$str_prgs$total <- total
  the$str_prgs$speed <- speed
  the$str_prgs$layer <- layer

  # if there is a total, it's a download update
  # if the layer is different from the last pb update, create a new pb
  if (!isTRUE(the$str_prgs$current_pb == layer)) {
    cli::cli_progress_bar(
      name = the$str_prgs$f,
      type = "download",
      format = paste0(
        "{cli::pb_spin} downloading {str_prgs$f} ",
        "({str_prgs$done_pct} of {prettyunits::pretty_bytes(str_prgs$total)}) ",
        "at {prettyunits::pretty_bytes(str_prgs$speed)}/s"
      ),
      format_done = paste0(
        "{cli::col_green(cli::symbol$tick)} downloaded {str_prgs$current_pb}"
      ),
      .envir = the
    )
    the$str_prgs$current_pb <- layer
    the$str_prgs$pb_start <- Sys.time()
  } else {
    if (total > done) {
      if (verbose) cli::cli_progress_update(force = TRUE, .envir = the)
    } else {
      if (verbose) {
        cli::cli_process_done(.envir = the)
      }
      the$str_prgs$current_pb <- NULL
    }
  }
  return(FALSE)
}
