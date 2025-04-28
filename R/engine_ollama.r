build_req_ollama <- function(model,
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
  if (length(msg) != length(model)) {
    if (length(model) > 1L)
      cli::cli_alert_info(c(
        "The number of queries is unequal to the number of models you supplied.",
        "We assume you want to run each query with each model"
      ))
    req_data <- purrr::map(msg, function(ms) {
      purrr::map(model, function(m) {
        list(
          model = m,
          messages = ms,
          stream = FALSE,
          options = model_params,
          format = format,
          template = template
        ) |>
          purrr::compact() |> # remove NULL values
          make_req_ollama_ollama(
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
        messages = ms,
        stream = FALSE,
        options = model_params,
        format = format,
        template = template
      ) |>
        purrr::compact() |> # remove NULL values
        make_req_ollama_ollama(
          server = sample(server, 1, prob = as_prob(names(server))),
          endpoint = "/api/chat"
        )
    })
  }

  return(req_data)
}


make_req_ollama <- function(req_data, server, endpoint) {
  r <- httr2::request(server) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_body_json(prep_req_data(req_data), auto_unbox = FALSE) |>
    # see https://github.com/JBGruber/rollama/issues/23
    httr2::req_options(timeout_ms = 1000 * 60 * 60 * 24,
                       connecttimeout_ms = 1000 * 60 * 60 * 24) |>
    httr2::req_headers(!!!get_headers())
  return(r)
}

processitem2list_ollama <- function(resp, req) {
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
}
