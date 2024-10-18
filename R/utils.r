screen_answer <- function(x, model = NULL) {
  pars <- unlist(strsplit(x, "\n", fixed = TRUE))
  cli::cli_h1("Answer from {cli::style_bold({model})}")
  # "{i}" instead of i stops glue from evaluating code inside the answer
  for (i in pars) cli::cli_text("{i}")
}


#' Check if one or several models are installed on the server
#'
#' @param model names of one or several models as character vector.
#' @param auto_pull if FALSE, the default, asks before downloading models.
#' @inheritParams query
#'
#' @return invisible TRUE/FALSE
#' @export
check_model_installed <- function(model,
                                  auto_pull = FALSE,
                                  server = getOption("rollama_server",
                                                     default = "http://localhost:11434")) {
  for (sv in server) {
    models_df <- list_models(server = sv)
    model <- setdiff(model, models_df[["name"]])
    model_wo_vers <- gsub(":.*", "", models_df[["name"]])
    model <- setdiff(model, model_wo_vers)
    if (length(model) > 0L && !auto_pull) {
      if (interactive()) {
        cli::cli_alert_info("{sv}: Model{?s} {model} not installed on. Would you like to download {?it/them}?")
        auto_pull <- utils::askYesNo("")
      }
      if (!auto_pull) {
        cli::cli_abort("Model {model} not installed on {sv}.")
        return(invisible(FALSE))
      }
    }
    if (auto_pull) {
      for (m in model) {
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
  tibble::as_tibble(l)
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
