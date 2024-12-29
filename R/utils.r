screen_answer <- function(x, model = NULL) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer from {cli::style_bold({model})}")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
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
check_model_installed <- function(model,
                                  check_only = FALSE,
                                  auto_pull = FALSE,
                                  server = getOption("rollama_server",
                                                     default = "http://localhost:11434")) {

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
        auto_pull <- utils::askYesNo(cli::cli_text(msg))
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
        message = purrr::pluck(resp, "message", "content")
      )
    )
  })
}


# process responses to data.frame
process2df <- function(resps) {
  tibble::tibble(
    model = purrr::map_chr(resps, "model"),
    role = purrr::map_chr(resps, c("message", "role")),
    response = purrr::map_chr(resps, c("message", "content"))
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
      cli::cli_abort("Names must be parsable to a numeric vector of probability weights")
    }
    return(out)
  }
  return(x)
}


check_conversation <- function(msg) {
  if (!"user" %in% msg$role && nchar(msg$content) > 0)
    cli::cli_abort(paste("If you supply a conversation object, it needs at",
                         "least one user message. See {.help query}."))
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
