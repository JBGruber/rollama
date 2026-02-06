build_req_ollama <- function(
  model,
  msg,
  server,
  model_params,
  format,
  stream,
  template
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  if (!all(ping_ollama(server = server, silent = TRUE))) {
    ping_ollama(server = server)
  }
  check_model_installed(model, server = server)

  seed <- getOption("rollama_seed")
  if (!is.null(seed) && !purrr::pluck_exists(model_params, "seed")) {
    model_params <- append(model_params, list(seed = seed))
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
          messages = ms,
          stream = stream,
          options = model_params,
          format = format,
          template = template
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
        messages = ms,
        stream = stream,
        options = model_params,
        format = format,
        template = template
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


make_req <- function(req_data, server, endpoint, engine = "ollama") {
  r <- httr2::request(server) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_body_json(prep_req_data(req_data), auto_unbox = FALSE) |>
    # see https://github.com/JBGruber/rollama/issues/23
    httr2::req_options(
      timeout_ms = 1000 * 60 * 60 * 24,
      connecttimeout_ms = 1000 * 60 * 60 * 24
    )

  # Add engine-specific headers
  headers <- get_headers()
  if (engine == "openai") {
    api_key <- getOption("rollama_api_key")
    if (!is.null(api_key)) {
      headers <- c(headers, "Authorization" = paste("Bearer", api_key))
    } else {
      cli::cli_warn("No API key set. Use options(rollama_api_key = 'your-key')")
    }
  } else if (engine == "anthropic") {
    api_key <- getOption("rollama_api_key")
    anthropic_version <- getOption(
      "rollama_anthropic_version",
      default = "2023-06-01"
    )
    if (!is.null(api_key)) {
      headers <- c(
        headers,
        "x-api-key" = api_key,
        "anthropic-version" = anthropic_version
      )
    } else {
      cli::cli_warn("No API key set. Use options(rollama_api_key = 'your-key')")
    }
  }

  r <- r |> httr2::req_headers(!!!headers)
  return(r)
}


output_ollama <- function(res, output, reqs) {
  switch(
    output,
    "response" = res,
    "text" = purrr::map_chr(res, c("message", "content")),
    "list" = process2list(res, reqs),
    "data.frame" = process2df(res)
  )
}


### Open WebUI
build_req_openwebui <- function(
  model,
  msg,
  server,
  model_params,
  format,
  stream,
  template
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:3000")
  }
  seed <- getOption("rollama_seed")
  if (!is.null(seed) && !purrr::pluck_exists(model_params, "seed")) {
    model_params <- append(model_params, list(seed = seed))
  }
  # OpenWebUI is OpenAI-compatible, so this is nearly identical
  req_data <- purrr::map2(msg, model, function(ms, m) {
    req_body <- list(
      model = m,
      messages = ms,
      stream = stream
    )
    # Add model_params (temperature, top_p, etc.)
    if (!is.null(model_params)) {
      req_body <- append(req_body, model_params)
    }
    # Add response format if specified
    if (!is.null(format)) {
      req_body$response_format <- list(type = format)
    }
    req_body |>
      purrr::compact() |>
      make_req(
        server = sample(server, 1, prob = as_prob(names(server))),
        endpoint = "/api/chat/completions",
        engine = "openai"
      )
  })

  return(req_data)
}


output_openwebui <- function(res, output) {
  switch(
    output,
    "response" = res,
    "text" = purrr::map_chr(res, list("choices", 1, "message", "content")),
    "list" = process2list(res, reqs),
    "data.frame" = process2df(res)
  )
}


### OpenAI
build_req_openai <- function(
  model,
  msg,
  server,
  model_params,
  format,
  stream,
  template
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "gpt-4o")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "https://api.openai.com")
  }
  seed <- getOption("rollama_seed")
  if (!is.null(seed) && !purrr::pluck_exists(model_params, "seed")) {
    model_params <- append(model_params, list(seed = seed))
  }

  req_data <- purrr::map2(msg, model, function(ms, m) {
    req_body <- list(
      model = m,
      messages = ms,
      stream = stream
    )
    # Add model_params (temperature, top_p, etc.)
    if (!is.null(model_params)) {
      req_body <- append(req_body, model_params)
    }
    # Add response format if specified
    if (!is.null(format)) {
      req_body$response_format <- list(type = format)
    }
    req_body |>
      purrr::compact() |>
      make_req(
        server = sample(server, 1, prob = as_prob(names(server))),
        endpoint = "/v1/chat/completions",
        engine = "openai"
      )
  })
  return(req_data)
}


output_openai <- output_openwebui

### Anthropic
build_req_anthropic <- function(
  model,
  msg,
  server,
  model_params,
  format,
  stream,
  template
) {
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "claude-sonnet-4-5-20250929")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "https://api.anthropic.com")
  }

  # Extract system message if present
  extract_system <- function(messages) {
    system_msg <- NULL
    if (nrow(messages) > 0 && messages$role[1] == "system") {
      system_msg <- messages$content[1]
      messages <- messages[-1, ]
    }
    list(system = system_msg, messages = messages)
  }

  req_data <- purrr::map2(msg, model, function(ms, m) {
    extracted <- extract_system(ms)
    req_body <- list(
      model = m,
      messages = extracted$messages,
      max_tokens = purrr::pluck(model_params, "max_tokens", .default = 4096),
      stream = stream
    )
    # Add system prompt if present
    if (!is.null(extracted$system)) {
      req_body$system <- extracted$system
    }
    # Add other model_params (temperature, top_p, top_k, etc.)
    if (!is.null(model_params)) {
      params_to_add <- model_params[!names(model_params) %in% c("max_tokens")]
      if (length(params_to_add) > 0) {
        req_body <- append(req_body, params_to_add)
      }
    }
    # Note: Anthropic doesn't support format parameter the same way as Ollama
    if (!is.null(format) && format == "json") {
      cli::cli_alert_warning(
        "Anthropic API uses 'output_config' for structured JSON output. ",
        "Consider using model_params with output_config instead of format parameter."
      )
    }
    req_body |>
      purrr::compact() |>
      make_req(
        server = sample(server, 1, prob = as_prob(names(server))),
        endpoint = "/v1/messages",
        engine = "anthropic"
      )
  })

  return(req_data)
}


output_anthropic <- function(res, output, reqs) {
  switch(
    output,
    "response" = res,
    "text" = purrr::pluck(r, "choices", 1, "message", "content"),
    "list" = process2list(res, reqs),
    "data.frame" = process2df(res)
  )
}
