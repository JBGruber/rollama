# Create a model from a Modelfile

Create a model from a Modelfile

## Usage

``` r
create_model(
  model,
  from = NULL,
  template = NULL,
  license = NULL,
  system = NULL,
  parameters = NULL,
  messages = NULL,
  quantize = NULL,
  stream = TRUE,
  ...,
  server = NULL,
  verbose = getOption("rollama_verbose", default = interactive())
)
```

## Arguments

- model:

  name of the model to create

- from:

  existing model to create from

- template:

  prompt template to use for the model

- license:

  license string or list of licenses for the model

- system:

  system prompt to embed in the model

- parameters:

  key-value parameters for the model

- messages:

  message history to use for the model (array of ChatMessage objects)

- quantize:

  quantization level to apply (e.g. `"q4_K_M"`, `"q8_0"`)

- stream:

  stream status updates (default: `TRUE`)

- ...:

  additional arguments (currently unused)

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

- verbose:

  Whether to print status messages to the Console. Either `TRUE`/`FALSE`
  or see
  [httr2::progress_bars](https://httr2.r-lib.org/reference/progress_bars.html).
  The default is to have status messages in interactive sessions. Can be
  changed with `options(rollama_verbose = FALSE)`.

## Value

(invisible) a tibble with information about the created model

## Details

Custom models are the way to save your system message and model
parameters in a dedicated shareable way. If you use
[`show_model()`](https://jbgruber.github.io/rollama/reference/pull_model.md),
you can look at the configuration of a model in the column modelfile. To
get more information and a list of valid parameters, check out
<https://github.com/ollama/ollama/blob/main/docs/modelfile.md>. Most
options are also available through the `query` and `chat` functions, yet
are not persistent over sessions.

## Examples

``` r
if (FALSE) { # ping_ollama(silent = TRUE)
create_model("mario", from = "llama3.1", system = "You are mario from Super Mario Bros.")
}
```
