# Generate Embeddings

Generate Embeddings

## Usage

``` r
embed_text(
  text,
  model = NULL,
  server = NULL,
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

- model_params:

  a named list of additional model parameters listed in the
  [documentation for the
  Modelfile](https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values).

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
