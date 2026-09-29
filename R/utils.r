screen_answer <- function(x, model = NULL) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer from {cli::style_bold({model})}")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) {
    cli::cli_text("{i}")
  }
}


#' Check if one or several models are installed on the server
#'
#' @param model names of one or several models as character vector.
#' @param check_only only return TRUE/FALSE and don't download models.
#' @param auto_pull if FALSE, the default, asks before downloading models.
#' @inheritParams query
#'
#' @return invisible TRUE/FALSE
#' @export
check_model_installed <- function(
  model,
  check_only = FALSE,
  auto_pull = FALSE,
  server = NULL
) {
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }
  model <- sub("^([^:]+)$", "\\1:latest", model)
  for (sv in server) {
    models_df <- list_models(server = sv)
    mdl <- setdiff(model, models_df[["name"]])

    if (length(mdl) > 0L) {
      if (check_only) {
        return(invisible(FALSE))
      }
      if (interactive() && !auto_pull) {
        msg <- c(
          "{cli::col_cyan(cli::symbol$info)}",
          " Model{?s} {.emph {mdl}} not installed on {sv}.",
          " Would you like to download {?it/them}?"
        )
        cli::cli_text(msg)
        auto_pull <- utils::askYesNo("Download?")
      }
      if (!auto_pull) {
        cli::cli_abort("Model {mdl} not installed on {sv}.")
        return(invisible(FALSE))
      }
    }
    if (auto_pull) {
      for (m in mdl) {
        pull_model(m, server = sv)
      }
    }
  }
  return(invisible(TRUE))
}


# process responses to list
process2list <- function(resps, reqs) {
  purrr::map2(resps, reqs, function(resp, req) {
    list(
      request = list(
        model = purrr::pluck(req, "body", "data", "model"),
        role = purrr::pluck(req, "body", "data", "messages", "role"),
        message = purrr::pluck(req, "body", "data", "messages", "content")
      ),
      response = list(
        model = purrr::pluck(resp, "model"),
        role = purrr::pluck(resp, "message", "role"),
        message = purrr::pluck(resp, "message", "content"),
        thinking = purrr::pluck(resp, "message", "thinking"),
        tool_calls = purrr::pluck(resp, "message", "tool_calls")
      )
    )
  })
}


# process responses to data.frame
process2df <- function(resps) {
  tibble::tibble(
    model = purrr::map_chr(resps, "model"),
    role = purrr::map_chr(resps, c("message", "role")),
    response = purrr::map_chr(resps, c("message", "content")),
    thinking = purrr::map_chr(
      resps,
      purrr::pluck,
      "message",
      "thinking",
      .default = NA_character_
    ),
    tool_calls = purrr::map(
      resps,
      purrr::pluck,
      "message",
      "tool_calls",
      .default = list(NULL)
    )
  )
}


# makes sure list can be turned into tibble
as_tibble_onerow <- function(l) {
  l <- purrr::map(l, function(c) {
    if (length(c) != 1) {
      return(list(c))
    }
    return(c)
  })
  # .name_repair required for older versions of Ollama
  tibble::as_tibble(l, .name_repair = "minimal")
}


as_prob <- function(x) {
  if (!is.null(x)) {
    out <- try(as.numeric(x), silent = TRUE)
    if (methods::is(out, "try-error")) {
      cli::cli_abort(
        "Names must be parsable to a numeric vector of probability weights"
      )
    }
    return(out)
  }
  return(x)
}


check_conversation <- function(msg) {
  if (!"user" %in% msg$role && nchar(msg$content) > 0) {
    cli::cli_abort(paste(
      "If you supply a conversation object, it needs at",
      "least one user message. See {.help query}."
    ))
  }
  return(msg)
}

throw_error <- function(fails) {
  error_counts <- table(fails)
  for (f in names(error_counts)) {
    if (error_counts[f] > 2) {
      cli::cli_alert_danger("error ({error_counts[f]} times): {f}")
    } else {
      cli::cli_alert_danger("error: {f}")
    }
  }
}


# Compute a stable hash for a request. The hash is taken over the request body
# as JSON (always UTF-8) so that file names are the same across sessions,
# locales, R versions and machines. Fields that do not change the answer are
# left out.
req_hash <- function(req) {
  data <- req$body$data
  data$keep_alive <- NULL
  data$stream <- NULL
  json <- jsonlite::toJSON(
    data,
    auto_unbox = FALSE,
    digits = NA,
    null = "null"
  )
  md5_string(enc2utf8(as.character(json)))
}


# Hash used by rollama <= 0.3.1. It depends on deparse() and therefore on the
# locale and R version. Only kept to migrate existing cache directories.
req_hash_legacy <- function(req) {
  md5_string(paste(req$body$data, collapse = "\n"))
}


md5_string <- function(x) {
  tmp <- tempfile()
  on.exit(unlink(tmp))
  writeBin(charToRaw(x), tmp)
  unname(tools::md5sum(tmp))
}


# Resolve cache paths from the cache argument and the list of requests.
# Returns NULL when cache is NULL, a character vector of file paths otherwise.
resolve_cache_paths <- function(cache, reqs) {
  if (is.null(cache)) {
    return(NULL)
  }

  if (length(cache) == 1L && tools::file_ext(cache) == "") {
    if (!dir.exists(cache)) {
      dir.create(cache, recursive = TRUE)
      cli::cli_inform("Created cache directory {.path {cache}}")
    }
    hashes <- purrr::map_chr(reqs, req_hash)
    paths <- file.path(cache, paste0(hashes, ".json"))
    migrate_legacy_cache(cache, paths, reqs)
    return(paths)
  }

  if (length(cache) == length(reqs)) {
    return(as.character(cache))
  }

  cli::cli_abort(c(
    "{.arg cache} length mismatch.",
    "i" = "Supply a single directory path or a character vector with one \\
           path per request ({length(reqs)} expected, {length(cache)} given)."
  ))
}


# Rename cache files written by rollama <= 0.3.1 (see req_hash_legacy()) to the
# current file names so existing cache directories keep working.
migrate_legacy_cache <- function(cache, paths, reqs) {
  todo <- which(!file.exists(paths) & !duplicated(paths))
  if (
    length(todo) == 0L ||
      length(list.files(cache, pattern = "\\.json$")) == 0L
  ) {
    return(invisible(0L))
  }
  legacy <- file.path(
    cache,
    paste0(purrr::map_chr(reqs[todo], req_hash_legacy), ".json")
  )
  found <- file.exists(legacy)
  renamed <- file.rename(legacy[found], paths[todo][found])
  if (any(renamed)) {
    cli::cli_inform(
      "Renamed {sum(renamed)} cache file{?s} in {.path {cache}} to the new \\
       naming scheme."
    )
  }
  invisible(sum(renamed))
}


read_cache <- function(path) {
  content <- readBin(path, what = "raw", n = file.info(path)$size)
  httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json; charset=utf-8"),
    body = content
  )
}


# TRUE when the file exists and contains a chat response. Error responses from
# Ollama (e.g. {"error": "..."}) are valid JSON but do not count as cached.
check_cache_valid <- function(path) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  tryCatch(
    {
      resp <- jsonlite::read_json(path)
      is.list(resp) && !is.null(resp$message) && is.null(resp$error)
    },
    error = function(e) FALSE
  )
}


# Describe why requests did not leave a valid cache file. Ollama's error
# message is taken from the file httr2 wrote the error response to.
cache_failures <- function(resps, paths) {
  purrr::map2_chr(resps, paths, function(resp, path) {
    msg <- if (!is.null(resp$parent)) {
      conditionMessage(resp$parent)
    } else if (inherits(resp, "condition")) {
      conditionMessage(resp)
    } else {
      "Response is not a valid chat response."
    }
    err <- tryCatch(jsonlite::read_json(path)$error, error = function(e) NULL)
    if (is.character(err)) {
      msg <- paste(msg, err)
    }
    gsub("\\s*\n\\s*", " ", cli::ansi_strip(msg))
  })
}


# Escape braces so cli does not try to interpolate text from responses.
cli_escape <- function(x) {
  x <- gsub("{", "{{", x, fixed = TRUE)
  gsub("}", "}}", x, fixed = TRUE)
}
