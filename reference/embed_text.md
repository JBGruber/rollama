# Generate Embeddings

Generate Embeddings

## Usage

``` r
embed_text(
  text,
  model = NULL,
  server = NULL,
  truncate = NULL,
  dimensions = NULL,
  keep_alive = NULL,
  model_params = NULL,
  verbose = getOption("rollama_verbose", default = interactive())
)
```

## Arguments

- text:

  text vector to generate embeddings for.

- model:

  which model to use. See <https://ollama.com/library> for options.
  Default is "llama3.1". Set option(rollama_model = "modelname") to
  change default for the current session. See
  [pull_model](https://jbgruber.github.io/rollama/reference/pull_model.md)
  for more details.

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

- truncate:

  whether to truncate the input to fit within the model's context length
  (`TRUE`/`FALSE`).

- dimensions:

  the desired number of dimensions in the embedding output. Only
  available for models that support it.

- keep_alive:

  controls how long the model is kept in memory after the request.
  Accepts a duration string such as `"5m"` or `"1h"`, `0` to unload
  immediately, or `-1` to keep the model loaded indefinitely.

- model_params:

  a named list of additional model parameters listed in the
  [documentation for the
  Modelfile](https://docs.ollama.com/modelfile#valid-parameters-and-values).

- verbose:

  Whether to print status messages to the Console (`TRUE`/`FALSE`). The
  default is to have status messages in interactive sessions. Can be
  changed with `options(rollama_verbose = FALSE)`.

## Value

a tibble with embeddings.

## Examples

``` r
if (FALSE) { # \dontrun{
embed_text(c(
  "Here is an article about llamas...",
  "R is a language and environment for statistical computing and graphics."))
} # }
```
