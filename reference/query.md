# Chat with a LLM through Ollama

Chat with a LLM through Ollama

## Usage

``` r
query(
  q,
  model = NULL,
  stream = TRUE,
  server = NULL,
  images = NULL,
  model_params = NULL,
  output = c("response", "text", "list", "data.frame", "httr2_response", "httr2_request"),
  format = NULL,
  tools = NULL,
  think = NULL,
  keep_alive = NULL,
  logprobs = FALSE,
  top_logprobs = NULL,
  cache = NULL,
  ...,
  verbose = getOption("rollama_verbose", default = interactive())
)

chat(
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
)
```

## Arguments

- q:

  the question as a character string or a conversation object.

- model:

  which model(s) to use. See <https://ollama.com/library> for options.
  Default is "llama3.1". Set `option(rollama_model = "modelname")` to
  change default for the current session. See
  [pull_model](https://jbgruber.github.io/rollama/reference/pull_model.md)
  for more details.

- stream:

  Logical. Should the answer be printed to the screen.

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

- images:

  path(s) to images (for multimodal models such as llava).

- model_params:

  a named list of additional model parameters listed in the
  [documentation for the
  Modelfile](https://docs.ollama.com/modelfile#valid-parameters-and-values)
  such as temperature. Use a seed and set the temperature to zero to get
  reproducible results (see examples).

- output:

  what the function should return. Possible values are "response",
  "text", "list", "data.frame", "httr2_response" or "httr2_request" or a
  function see details.

- format:

  the format to return a response in. Use `"json"` to request arbitrary
  JSON output or use
  [`create_schema()`](https://jbgruber.github.io/rollama/reference/create_schema.md)
  to request a specific structured output. See the [structured outputs
  article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
  for details.

- tools:

  a list of tools (functions) the model may call. Each tool should
  follow the Ollama tool schema with fields `type`, `function`
  (containing `name`, `description`, and `parameters`).

- think:

  logical. If `TRUE`, enables extended thinking / reasoning mode
  (supported by compatible models such as DeepSeek-R1).

- keep_alive:

  controls how long the model is kept in memory after the request.
  Accepts a duration string such as `"5m"` or `"1h"`, `0` to unload
  immediately, or `-1` to keep the model loaded indefinitely.

- logprobs:

  logical. If `TRUE`, the response includes log probabilities of the
  output tokens.

- top_logprobs:

  integer (0–20). Number of most-likely tokens to return log
  probabilities for at each output position. Requires `logprobs = TRUE`.

- cache:

  where to cache responses on disk so that long annotation pipelines can
  be resumed after an interruption. Two forms are accepted:

  - A **single directory path** (e.g. `"my_cache"`). Each response is
    stored as `{directory}/{md5_hash}.json`, where the hash is derived
    from the request content (model, messages, options). Re-running the
    same request always hits the same file, even across sessions.

  - A **character vector** with one explicit file path per request. Use
    this when you need to control file names yourself.

  Existing, valid cache files are loaded instead of re-querying Ollama.
  Corrupted or missing files are re-requested and then saved. Caching
  requires `stream = FALSE` (a warning is emitted and streaming is
  disabled automatically when `cache` is set). The `"httr2_response"`
  output type and custom output functions are not compatible with
  caching.

- ...:

  not used.

- verbose:

  Whether to print status messages to the Console. Either `TRUE`/`FALSE`
  or see
  [httr2::progress_bars](https://httr2.r-lib.org/reference/progress_bars.html).
  The default is to have status messages in interactive sessions. Can be
  changed with `options(rollama_verbose = FALSE)`.

## Value

list of objects set in output parameter.

## Details

`query` sends a single question to the API, without knowledge about
previous questions (only the config message is relevant). `chat` treats
new messages as part of the same conversation until
[new_chat](https://jbgruber.github.io/rollama/reference/chat_history.md)
is called.

To make the output reproducible, you can set a seed with
`options(rollama_seed = 42)`. As long as the seed stays the same, the
models will give the same answer, changing the seed leads to a different
answer.

For the output of `query`, there are a couple of options:

- `response`: the response of the Ollama server

- `text`: only the answer as a character vector

- `data.frame`: a data.frame containing model and response

- `list`: a list containing the prompt to Ollama and the response

- `httr2_response`: the response of the Ollama server including HTML
  headers in the `httr2` response format

- `httr2_request`: httr2_request objects in a list, in case you want to
  run them with
  [`httr2::req_perform()`](https://httr2.r-lib.org/reference/req_perform.html),
  [`httr2::req_perform_sequential()`](https://httr2.r-lib.org/reference/req_perform_sequential.html),
  or
  [`httr2::req_perform_parallel()`](https://httr2.r-lib.org/reference/req_perform_parallel.html)
  yourself.

- a custom function that takes the `httr2_response`(s) from the Ollama
  server as an input.

## Examples

``` r
if (FALSE) { # interactive()
# ask a single question
query("why is the sky blue?")

# hold a conversation
chat("why is the sky blue?")
chat("and how do you know that?")

# save the response to an object and extract the answer
resp <- query(q = "why is the sky blue?")
answer <- resp[[1]]$message$content

# or just get the answer directly
answer <- query(q = "why is the sky blue?", output = "text")

# besides the other output options, you can also supply a custom function
query_duration <- function(resp) {
nanosec <- purrr::map(resp, httr2::resp_body_json) |>
  purrr::map_dbl("total_duration")
  round(nanosec * 1e-9, digits = 2)
}
# this function only returns the number of seconds a request took
res <- query("why is the sky blue?", output = query_duration)
res

# ask question about images (to a multimodal model)
images <- c("https://avatars.githubusercontent.com/u/23524101?v=4", # remote
            "/path/to/your/image.jpg") # or local images supported
query(q = "describe these images",
      model = "llava",
      images = images[1]) # just using the first path as the second is not real

# set custom options for the model at runtime (rather than in create_model())
query("why is the sky blue?",
      model_params = list(
        num_keep = 5,
        seed = 42,
        num_predict = 100,
        top_k = 20,
        top_p = 0.9,
        min_p = 0.0,
        tfs_z = 0.5,
        typical_p = 0.7,
        repeat_last_n = 33,
        temperature = 0.8,
        repeat_penalty = 1.2,
        presence_penalty = 1.5,
        frequency_penalty = 1.0,
        mirostat = 1,
        mirostat_tau = 0.8,
        mirostat_eta = 0.6,
        penalize_newline = TRUE,
        numa = FALSE,
        num_ctx = 1024,
        num_batch = 2,
        num_gpu = 0,
        main_gpu = 0,
        low_vram = FALSE,
        vocab_only = FALSE,
        use_mmap = TRUE,
        use_mlock = FALSE,
        num_thread = 8
      ))

# use a seed to get reproducible results
query("why is the sky blue?", model_params = list(seed = 42))

# to set a seed for the whole session you can use
options(rollama_seed = 42)

# this might be interesting if you want to turn off the GPU and load the
# model into the system memory (slower, but most people have more RAM than
# VRAM, which might be interesting for larger models)
query("why is the sky blue?",
       model_params = list(num_gpu = 0))

# enable extended thinking / reasoning mode (supported models e.g. DeepSeek-R1)
query("what is 3 * 12?", model = "deepseek-r1", think = TRUE)

# use tools (function calling) — tool calling is a two-step process:
# 1. The model returns a tool_call (empty content) instead of a text answer.
# 2. You execute the function and send the result back so the model can
#    formulate a final answer.

# define the actual R function
add_numbers <- function(a, b) as.numeric(a) + as.numeric(b)

# describe it to the model
tools <- list(list(
  type = "function",
  `function` = list(
    name = "add_numbers",
    description = "Add two numbers together",
    parameters = list(
      type = "object",
      properties = list(
        a = list(type = "number", description = "First number"),
        b = list(type = "number", description = "Second number")
      ),
      required = list("a", "b")
    )
  )
))

# Step 1: model decides which tool to call and with which arguments
question <- "What is 4 + 7?"
resp <- query(question, model = "llama3.1", tools = tools, stream = FALSE)
tool_call <- resp[[1]]$message$tool_calls[[1]]

# Step 2: call the real function with the model-supplied arguments
result <- do.call(add_numbers, tool_call$`function`$arguments)

# Step 3: send the result back so the model can give a final answer
conversation <- data.frame(
  role    = c("user", "assistant", "tool"),
  content = c(question, "", as.character(result))
)
query(conversation, model = "llama3.1")

# Asking the same question to multiple models is also supported
query("why is the sky blue?", model = c("llama3.1", "orca-mini"))

# And if you have multiple Ollama servers in your network, you can send
# requests to them in parallel
if (ping_ollama(c("http://localhost:11434/",
                  "http://192.168.2.45:11434/"))) { # check if servers are running
  query("why is the sky blue?", model = c("llama3.1", "orca-mini"),
        server = c("http://localhost:11434/",
                   "http://192.168.2.45:11434/"))
}
}
```
