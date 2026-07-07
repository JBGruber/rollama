#' Chat with a LLM through Ollama
#'
#' @details `query` sends a single question to the API, without knowledge about
#'   previous questions (only the config message is relevant). `chat` treats new
#'   messages as part of the same conversation until [new_chat] is called.
#'
#'   To make the output reproducible, you can set a seed with
#'   `options(rollama_seed = 42)`. As long as the seed stays the same, the
#'   models will give the same answer, changing the seed leads to a different
#'   answer.
#'
#'   For the output of `query`, there are a couple of options:
#'
#'   - `response`: the response of the Ollama server
#'   - `text`: only the answer as a character vector
#'   - `data.frame`: a data.frame containing model and response
#'   - `list`: a list containing the prompt to Ollama and the response
#'   - `httr2_response`: the response of the Ollama server including HTML
#'      headers in the `httr2` response format
#'   - `httr2_request`: httr2_request objects in a list, in case you want to run
#'      them with [httr2::req_perform()], [httr2::req_perform_sequential()], or
#'      [httr2::req_perform_parallel()] yourself.
#'   - a custom function that takes the `httr2_response`(s) from the Ollama
#'      server as an input.
#'
#'
#' @param q the question as a character string or a conversation object.
#' @param model which model(s) to use. See <https://ollama.com/library> for
#'   options. Default is "llama3.1". Set `option(rollama_model = "modelname")` to
#'   change default for the current session. See [pull_model] for more
#'   details.
#' @param stream Logical. Should the answer be printed to the screen.
#' @param server URL to one or several Ollama servers (not the API). Defaults to
#'   "http://localhost:11434".
#' @param images path(s) to images (for multimodal models such as llava). A
#'   plain character vector of paths/URLs is attached to every query as-is
#'   (e.g. to ask about several images at once). To annotate several images
#'   individually with the same prompt, pass a **list** instead, e.g.
#'   `images = as.list(paths)`: each list element is then paired up with `q`
#'   (recycling whichever of the two has length 1) to produce one query per
#'   image.
#' @param model_params a named list of additional model parameters listed in the
#'   [documentation for the
#'   Modelfile](https://docs.ollama.com/modelfile#valid-parameters-and-values)
#'   such as temperature. Use a seed and set the temperature to zero to get
#'   reproducible results (see examples).
#' @param output what the function should return. Possible values are
#'   "response", "text", "list", "data.frame", "httr2_response" or
#'   "httr2_request" or a function see details.
#' @param format the format to return a response in. Use `"json"` to request
#'   arbitrary JSON output or use [create_schema()] to request a specific
#'   structured output. See the [structured outputs article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
#'   for details.
#' @param logprobs logical. If `TRUE`, the response includes log probabilities
#'   of the output tokens.
#' @param top_logprobs integer (0–20). Number of most-likely tokens to return
#'   log probabilities for at each output position. Requires `logprobs = TRUE`.
#' @param tools a list of tools (functions) the model may call. Each tool
#'   should follow the Ollama tool schema with fields `type`, `function`
#'   (containing `name`, `description`, and `parameters`).
#' @param think logical. If `TRUE`, enables extended thinking / reasoning
#'   mode (supported by compatible models such as DeepSeek-R1).
#' @param keep_alive controls how long the model is kept in memory after the
#'   request. Accepts a duration string such as `"5m"` or `"1h"`, `0` to
#'   unload immediately, or `-1` to keep the model loaded indefinitely.
#' @param cache where to cache responses on disk so that long annotation
#'   pipelines can be resumed after an interruption. Two forms are accepted:
#'   \itemize{
#'     \item A **single directory path** (e.g. `"my_cache"`). Each response is
#'       stored as `{directory}/{md5_hash}.json`, where the hash is derived from
#'       the request content (model, messages, options). Re-running the same
#'       request always hits the same file, even across sessions.
#'     \item A **character vector** with one explicit file path per request.
#'       Use this when you need to control file names yourself.
#'   }
#'   Existing, valid cache files are loaded instead of re-querying Ollama.
#'   Corrupted or missing files are re-requested and then saved. Caching
#'   requires `stream = FALSE` (a warning is emitted and streaming is disabled
#'   automatically when `cache` is set). The `"httr2_response"` output type
#'   and custom output functions are not compatible with caching.
#' @param ... not used.
#' @param verbose Whether to print status messages to the Console. Either
#'   `TRUE`/`FALSE` or see [httr2::progress_bars]. The default is to have status
#'   messages in interactive sessions. Can be changed with
#'   `options(rollama_verbose = FALSE)`.
#'
#' @return list of objects set in output parameter.
#' @export
#'
#' @examplesIf interactive()
#' # ask a single question
#' query("why is the sky blue?")
#'
#' # hold a conversation
#' chat("why is the sky blue?")
#' chat("and how do you know that?")
#'
#' # save the response to an object and extract the answer
#' resp <- query(q = "why is the sky blue?")
#' answer <- resp[[1]]$message$content
#'
#' # or just get the answer directly
#' answer <- query(q = "why is the sky blue?", output = "text")
#'
#' # besides the other output options, you can also supply a custom function
#' query_duration <- function(resp) {
#' nanosec <- purrr::map(resp, httr2::resp_body_json) |>
#'   purrr::map_dbl("total_duration")
#'   round(nanosec * 1e-9, digits = 2)
#' }
#' # this function only returns the number of seconds a request took
#' res <- query("why is the sky blue?", output = query_duration)
#' res
#'
#' # ask question about images (to a multimodal model)
#' images <- c("https://avatars.githubusercontent.com/u/23524101?v=4", # remote
#'             "/path/to/your/image.jpg") # or local images supported
#' query(q = "describe these images",
#'       model = "llava",
#'       images = images[1]) # just using the first path as the second is not real
#'
#' # annotate several images individually with the same prompt by passing a
#' # list: this issues one query per image instead of one query about all of
#' # them
#' query(q = "describe this image",
#'       model = "llava",
#'       images = as.list(images[1])) # again, just the one real path
#'
#' # set custom options for the model at runtime (rather than in create_model())
#' query("why is the sky blue?",
#'       model_params = list(
#'         num_keep = 5,
#'         seed = 42,
#'         num_predict = 100,
#'         top_k = 20,
#'         top_p = 0.9,
#'         min_p = 0.0,
#'         tfs_z = 0.5,
#'         typical_p = 0.7,
#'         repeat_last_n = 33,
#'         temperature = 0.8,
#'         repeat_penalty = 1.2,
#'         presence_penalty = 1.5,
#'         frequency_penalty = 1.0,
#'         mirostat = 1,
#'         mirostat_tau = 0.8,
#'         mirostat_eta = 0.6,
#'         penalize_newline = TRUE,
#'         numa = FALSE,
#'         num_ctx = 1024,
#'         num_batch = 2,
#'         num_gpu = 0,
#'         main_gpu = 0,
#'         low_vram = FALSE,
#'         vocab_only = FALSE,
#'         use_mmap = TRUE,
#'         use_mlock = FALSE,
#'         num_thread = 8
#'       ))
#'
#' # use a seed to get reproducible results
#' query("why is the sky blue?", model_params = list(seed = 42))
#'
#' # to set a seed for the whole session you can use
#' options(rollama_seed = 42)
#'
#' # this might be interesting if you want to turn off the GPU and load the
#' # model into the system memory (slower, but most people have more RAM than
#' # VRAM, which might be interesting for larger models)
#' query("why is the sky blue?",
#'        model_params = list(num_gpu = 0))
#'
#' # enable extended thinking / reasoning mode (supported models e.g. DeepSeek-R1)
#' query("what is 3 * 12?", model = "deepseek-r1", think = TRUE)
#'
#' # use tools (function calling) — tool calling is a two-step process:
#' # 1. The model returns a tool_call (empty content) instead of a text answer.
#' # 2. You execute the function and send the result back so the model can
#' #    formulate a final answer.
#'
#' # define the actual R function
#' add_numbers <- function(a, b) as.numeric(a) + as.numeric(b)
#'
#' # describe it to the model
#' tools <- list(list(
#'   type = "function",
#'   `function` = list(
#'     name = "add_numbers",
#'     description = "Add two numbers together",
#'     parameters = list(
#'       type = "object",
#'       properties = list(
#'         a = list(type = "number", description = "First number"),
#'         b = list(type = "number", description = "Second number")
#'       ),
#'       required = list("a", "b")
#'     )
#'   )
#' ))
#'
#' # Step 1: model decides which tool to call and with which arguments
#' question <- "What is 4 + 7?"
#' resp <- query(question, model = "llama3.1", tools = tools, stream = FALSE)
#' tool_call <- resp[[1]]$message$tool_calls[[1]]
#'
#' # Step 2: call the real function with the model-supplied arguments
#' result <- do.call(add_numbers, tool_call$`function`$arguments)
#'
#' # Step 3: send the result back so the model can give a final answer
#' conversation <- data.frame(
#'   role    = c("user", "assistant", "tool"),
#'   content = c(question, "", as.character(result))
#' )
#' query(conversation, model = "llama3.1")
#'
#' # Asking the same question to multiple models is also supported
#' query("why is the sky blue?", model = c("llama3.1", "orca-mini"))
#'
#' # And if you have multiple Ollama servers in your network, you can send
#' # requests to them in parallel
#' if (ping_ollama(c("http://localhost:11434/",
#'                   "http://192.168.2.45:11434/"))) { # check if servers are running
#'   query("why is the sky blue?", model = c("llama3.1", "orca-mini"),
#'         server = c("http://localhost:11434/",
#'                    "http://192.168.2.45:11434/"))
#' }
query <- function(
  q,
  model = NULL,
  stream = TRUE,
  server = NULL,
  images = NULL,
  model_params = NULL,
  output = c(
    "response",
    "text",
    "list",
    "data.frame",
    "httr2_response",
    "httr2_request"
  ),
  format = NULL,
  tools = NULL,
  think = NULL,
  keep_alive = NULL,
  logprobs = FALSE,
  top_logprobs = NULL,
  cache = NULL,
  ...,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  # for backwards compatibility
  if ("screen" %in% names(list(...))) {
    stream <- list(...)$screen
  }
  if (!is.function(output)) {
    output <- match.arg(output)
  }
  if (is.null(model)) {
    model <- getOption("rollama_model", default = "llama3.1")
  }
  if (is.null(server)) {
    server <- getOption("rollama_server", default = "http://localhost:11434")
  }

  # q can be a string, a data.frame, or list of data.frames
  if (is.character(q)) {
    config <- getOption("rollama_config", default = NULL)

    # a plain vector of images is attached as-is to every query (e.g. to
    # compare several images in one message). A list of images is paired
    # up with q instead, so each element becomes its own query (e.g. to
    # annotate several images with the same prompt).
    if (is.list(images)) {
      n <- max(length(q), length(images))
      if (!length(q) %in% c(1L, n) || !length(images) %in% c(1L, n)) {
        cli::cli_abort(
          "{.arg q} and {.arg images} must have compatible lengths (equal \\
           length, or one of them of length 1)."
        )
      }
      q <- rep_len(q, n)
      images_list <- rep_len(images, n)
    } else {
      images_list <- rep_len(list(images), length(q))
    }

    msg <- purrr::map2(q, images_list, function(q, images) {
      msg <- do.call(
        rbind,
        list(
          if (!is.null(config)) data.frame(role = "system", content = config),
          data.frame(role = "user", content = q)
        )
      )

      if (length(images) > 0) {
        rlang::check_installed("base64enc")
        images <- purrr::map_chr(images, \(i) base64enc::base64encode(i))
        msg <- tibble::add_column(msg, images = list(images))
      }
      msg
    })
  } else if (is.data.frame(q)) {
    msg <- list(check_conversation(q))
  } else {
    msg <- purrr::map(q, check_conversation)
  }

  if (!is.null(cache)) {
    if (is.function(output) || identical(output, "httr2_response")) {
      cli::cli_abort(c(
        "Caching is not compatible with {.code output = \"httr2_response\"} or \\
         a custom output function.",
        "i" = "Use a standard output type such as {.val text} or \\
               {.val data.frame} when {.arg cache} is set."
      ))
    }
    if (stream) {
      cli::cli_alert_info(
        "{.arg cache} requires {.code stream = FALSE}. Disabling streaming."
      )
      stream <- FALSE
    }
  }

  reqs <- build_req(
    model = model,
    msg = msg,
    server = server,
    model_params = model_params,
    format = format,
    stream = stream,
    tools = tools,
    think = think,
    keep_alive = keep_alive,
    logprobs = logprobs,
    top_logprobs = top_logprobs
  )

  if (identical(output, "httr2_request")) {
    return(invisible(reqs))
  }

  if (!all(ping_ollama(server = server, silent = TRUE))) {
    cli::cli_alert_danger("Could not connect to Ollama at {.url {server}}")
  }
  check_model_installed(model, server = server)

  res <- NULL
  resps <- NULL

  cache_paths <- resolve_cache_paths(cache, reqs)

  if (!is.null(cache_paths)) {
    resps <- perform_reqs_with_cache(reqs, cache_paths, verbose)
  } else if (stream) {
    if (is.function(output) | identical(output, "httr2_response")) {
      resps <- perform_reqs(reqs, verbose)
      res <- purrr::map(resps, httr2::resp_body_json)
      purrr::walk(res, function(r) {
        screen_answer(
          purrr::pluck(r, "message", "content"),
          purrr::pluck(r, "model")
        )
      })
    } else {
      res <- purrr::map(reqs, stream_answer)
    }
  } else {
    if (length(reqs) > 1L) {
      resps <- perform_reqs(reqs, verbose)
    } else {
      resps <- perform_req(reqs, verbose)
    }
  }

  if (is.function(output)) {
    return(invisible(output(resps)))
  }

  if (identical(output, "httr2_response")) {
    return(invisible(resps))
  }

  if (is.null(res)) {
    res <- purrr::map(resps, httr2::resp_body_json)
  }

  out <- switch(
    output,
    "response" = res,
    "text" = purrr::map_chr(res, c("message", "content")),
    "list" = process2list(res, reqs),
    "data.frame" = process2df(res)
  )
  invisible(out)
}


#' @rdname query
#' @export
chat <- function(
  q,
  model = NULL,
  stream = TRUE,
  server = NULL,
  images = NULL,
  model_params = NULL,
  tools = NULL,
  think = NULL,
  keep_alive = NULL,
  logprobs = NULL,
  top_logprobs = NULL,
  ...,
  verbose = getOption("rollama_verbose", default = interactive())
) {
  config <- getOption("rollama_config", default = NULL)
  hist <- chat_history()

  # save prompt
  names(q) <- Sys.time()
  the$prompts <- c(the$prompts, q)

  q <- data.frame(role = "user", content = q)
  if (length(images) > 0) {
    rlang::check_installed("base64enc")
    images <- list(purrr::map_chr(images, \(i) base64enc::base64encode(i)))
    q <- tibble::add_column(q, images = images)
  }

  msg <- do.call(
    rbind,
    (list(
      if (!is.null(config)) data.frame(role = "system", content = config),
      if (nrow(hist) > 0) hist[, c("role", "content")],
      q
    ))
  )

  resp <- query(
    q = msg,
    model = model,
    stream = stream,
    server = server,
    model_params = model_params,
    tools = tools,
    think = think,
    keep_alive = keep_alive,
    logprobs = logprobs,
    top_logprobs = top_logprobs,
    ...,
    verbose = verbose
  )

  # save response
  r <- purrr::pluck(resp, 1, "message", "content")
  names(r) <- Sys.time()
  the$responses <- c(the$responses, r)

  invisible(resp)
}


#' Handle conversations
#'
#' Shows and deletes (`new_chat`) the local prompt and response history to start
#' a new conversation.
#'
#' @return chat_history: tibble with chat history
#' @export
chat_history <- function() {
  out <- tibble::tibble(
    role = c(
      rep("user", length(the$prompts)),
      rep("assistant", length(the$responses))
    ),
    content = unname(c(the$prompts, the$responses)),
    time = as.POSIXct(names(c(the$prompts, the$responses)))
  )
  out[order(out$time), ]
}


#' @rdname chat_history
#' @return new_chat: Does not return a value
#' @export
new_chat <- function() {
  the$responses <- NULL
  the$prompts <- NULL
}


#' Generate and format queries for a language model
#'
#' `make_query` generates structured input for a language model, including
#' system prompt, user messages, and optional examples (assistant answers).
#'
#' @details The function supports the inclusion of examples, which are
#'   dynamically added to the structured input. Each example follows the same
#'   format as the primary user query.
#'
#' @param text A character vector of texts to be annotated.
#' @param prompt A string defining the main task or question to be passed to the
#'   language model.
#' @param template A string template for formatting user queries, containing
#'   placeholders like `{text}`, `{prefix}`, and `{suffix}`.
#' @param system An optional string to specify a system prompt.
#' @param prefix A prefix string to prepend to each user query.
#' @param suffix A suffix string to append to each user query.
#' @param examples A `tibble` with columns `text` and `answer`, representing
#'   example user messages and corresponding assistant responses.
#'
#' @return A list of tibbles, one for each input `text`, containing structured
#'   rows for system messages, user messages, and assistant responses.
#' @export
#'
#' @examples
#' template <- "{prefix}{text}\n\n{prompt}{suffix}"
#' examples <- tibble::tribble(
#'   ~text, ~answer,
#'   "This movie was amazing, with great acting and story.", "positive",
#'   "The film was okay, but not particularly memorable.", "neutral",
#'   "I found this movie boring and poorly made.", "negative"
#' )
#' queries <- make_query(
#'   text = c("A stunning visual spectacle.", "Predictable but well-acted."),
#'   prompt = "Classify sentiment as positive, neutral, or negative.",
#'   template = template,
#'   system = "Provide a sentiment classification.",
#'   prefix = "Review: ",
#'   suffix = " Please classify.",
#'   examples = examples
#' )
#' print(queries)
#' if (ping_ollama()) { # only run this example when Ollama is running
#'   query(queries, stream = TRUE, output = "text")
#' }
make_query <- function(
  text,
  prompt,
  template = "{prefix}{text}\n{prompt}\n{suffix}",
  system = NULL,
  prefix = NULL,
  suffix = NULL,
  examples = NULL
) {
  rlang::check_installed("glue")

  # Process each input text
  queries <- lapply(text, function(txt) {
    # Initialize structured query
    full_query <- tibble::tibble(role = character(), content = character())

    # Add system message if provided
    if (!is.null(system)) {
      full_query <- full_query |>
        dplyr::add_row(role = "system", content = system)
    }

    # Add examples if provided
    if (!is.null(examples)) {
      examples <- tibble::as_tibble(examples) |>
        dplyr::rowwise() |>
        dplyr::mutate(
          user_content = glue::glue(
            template,
            text = text,
            prompt = prompt,
            prefix = prefix,
            suffix = suffix,
            .null = ""
          )
        ) |>
        dplyr::ungroup()

      for (i in seq_len(nrow(examples))) {
        full_query <- full_query |>
          dplyr::add_row(role = "user", content = examples$user_content[i]) |>
          dplyr::add_row(role = "assistant", content = examples$answer[i])
      }
    }

    # Add main user query
    main_query <- glue::glue(
      template,
      text = txt,
      prompt = prompt,
      prefix = prefix,
      suffix = suffix,
      .null = ""
    )
    full_query <- full_query |>
      dplyr::add_row(role = "user", content = main_query)

    return(full_query)
  })

  return(queries)
}
