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
          httr2::req_url_path_append("api/version") |>
          httr2::req_headers(!!!get_headers()) |>
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


build_req <- function(
  model,
  msg,
  server,
  model_params,
  format,
  stream,
  tools = NULL,
  think = NULL,
  keep_alive = NULL,
  logprobs = NULL,
  top_logprobs = NULL
) {
  seed <- getOption("rollama_seed")
  if (!is.null(seed) && !purrr::pluck_exists(model_params, "seed")) {
    model_params <- append(model_params, list(seed = seed))
  }
  if (!is.null(format)) {
    format <- as_json_schema(format)
  }

  if (length(msg) != length(model)) {
    if (length(model) > 1L) {
      cli::cli_alert_info(c(
        "The number of queries is unequal to the number of models you supplied.",
        "We assume you want to run each query with each model"
      ))
    }
    req_data <- purrr::map(msg, function(ms) {
      purrr::map(model, function(m) {
        list(
          model = m,
          messages = msg_to_list(ms),
          stream = stream,
          options = model_params,
          format = format,
          tools = tools,
          think = think,
          keep_alive = keep_alive,
          logprobs = logprobs,
          top_logprobs = top_logprobs
        ) |>
          purrr::compact() |> # remove NULL values
          make_req(
            server = sample(server, 1, prob = as_prob(names(server))),
            endpoint = "/api/chat"
          )
      })
    }) |>
      unlist(recursive = FALSE)
  } else {
    req_data <- purrr::map2(msg, model, function(ms, m) {
      list(
        model = m,
        messages = msg_to_list(ms),
        stream = stream,
        options = model_params,
        format = format,
        tools = tools,
        think = think,
        keep_alive = keep_alive,
        logprobs = logprobs,
        top_logprobs = top_logprobs
      ) |>
        purrr::compact() |> # remove NULL values
        make_req(
          server = sample(server, 1, prob = as_prob(names(server))),
          endpoint = "/api/chat"
        )
    })
  }

  return(req_data)
}


make_req <- function(req_data, server, endpoint) {
  r <- httr2::request(server) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_body_json(prep_req_data(req_data), auto_unbox = FALSE) |>
    # see https://github.com/JBGruber/rollama/issues/23
    httr2::req_options(
      timeout_ms = 1000 * 60 * 60 * 24,
      connecttimeout_ms = 1000 * 60 * 60 * 24
    ) |>
    httr2::req_headers(!!!get_headers())
  return(r)
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

perform_reqs_with_cache <- function(
  reqs,
  cache_paths,
  verbose,
  retries = getOption("rollama_cache_retries", default = 3L)
) {
  valid <- purrr::map_lgl(cache_paths, check_cache_valid)

  model <- purrr::map_chr(reqs, c("body", "data", "model")) |>
    unique()
  pb <- FALSE
  if (!is.logical(verbose)) {
    pb <- verbose
  } else if (verbose) {
    n_cached <- sum(valid)
    n_run <- sum(!valid & !duplicated(cache_paths))
    if (n_cached > 0L && n_run > 0L) {
      cli::cli_alert_info(
        "Loading {n_cached} cached response{?s}, running {n_run} new request{?s}."
      )
    } else if (n_cached > 0L) {
      cli::cli_alert_info("Loading all {n_cached} response{?s} from cache.")
    }
    pb <- list(
      clear = TRUE,
      format = c(
        "{cli::pb_spin} {getOption('model')} {?is/are} thinking about ",
        "{cli::pb_total - cli::pb_current}/{cli::pb_total} question{?s}",
        "[ETA: {cli::pb_eta}]"
      )
    )
  }
  attempt <- 0L
  repeat {
    # identical requests share a cache file, so only the first one is run
    # instead of having several requests write to the same file at once
    todo <- which(!valid & !duplicated(cache_paths))
    if (length(todo) == 0L) {
      break
    }
    withr::with_options(list(cli.progress_show_after = 0, model = model), {
      resps <- httr2::req_perform_parallel(
        reqs = reqs[todo],
        paths = cache_paths[todo],
        on_error = "continue",
        progress = pb
      )
    })

    ok <- purrr::map_lgl(cache_paths[todo], check_cache_valid)
    fails <- cache_failures(resps[!ok], cache_paths[todo][!ok])
    # remove error responses and partial downloads so they are never mistaken
    # for answers, e.g., when the cache directory is shared with other machines
    unlink(cache_paths[todo][!ok])
    valid <- valid | cache_paths %in% cache_paths[todo][ok]

    # httr2 catches the first interrupt and returns NULL for requests that did
    # not run, so stop here instead of starting them again
    if (any(purrr::map_lgl(resps, is.null))) {
      cli::cli_abort(c(
        "Interrupted.",
        "i" = "{sum(valid)} of {length(valid)} responses are cached. Run the \\
               same call again to continue."
      ))
    }

    if (all(ok)) {
      break
    }
    if (attempt >= retries) {
      counts <- table(fails)
      reasons <- cli_escape(paste0(
        names(counts),
        ifelse(counts > 1L, paste0(" (", counts, " times)"), "")
      ))
      names(reasons) <- rep("x", length(reasons))
      cli::cli_abort(c(
        "{sum(!ok)} request{?s} failed after {retries} retr{?y/ies}:",
        reasons,
        "i" = "{sum(valid)} of {length(valid)} responses are cached. Run the \\
               same call again to retry only the failed requests."
      ))
    }
    attempt <- attempt + 1L
    cli::cli_alert_warning(
      "{sum(!ok)} request{?s} failed, retrying (attempt {attempt} of {retries})."
    )
  }

  purrr::map(cache_paths, read_cache)
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
    # fields that must stay a JSON array even at length 1 (e.g. a single
    # image) are marked with I() by msg_to_list() and left untouched here
    if (inherits(x, "AsIs")) {
      return(unclass(x))
    }
    if (length(x) == 1L) {
      jsonlite::unbox(x)
    } else {
      x
    }
  })
}


# Turn a conversation data.frame/tibble (one row per ChatMessage) into a list
# of message objects, one per row, with unset fields (e.g. images, tool_calls)
# dropped instead of sent as JSON null. A plain data.frame is a leaf as far as
# purrr::modify_tree() is concerned, so scalar values nested inside list
# columns like `tool_calls` (e.g. `tool_calls[[1]]$function$name`) would never
# get unboxed by prep_req_data() and would serialise as one-element arrays;
# turning each row into an ordinary list fixes that.
msg_to_list <- function(msg) {
  purrr::pmap(msg, function(...) {
    row <- purrr::compact(list(...))
    if (!is.null(row$images)) {
      row$images <- I(row$images)
    }
    row
  })
}
