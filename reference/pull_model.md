# Pull, show and delete models

Pull, show and delete models

## Usage

``` r
pull_model(
  model = NULL,
  server = NULL,
  insecure = FALSE,
  background = FALSE,
  verbose = getOption("rollama_verbose", default = interactive())
)

show_model(model = NULL, server = NULL)

delete_model(model, server = NULL)

copy_model(model, destination = paste0(model, "-copy"), server = NULL)
```

## Arguments

- model:

  name of the model(s). Defaults to "llama3.1" when `NULL` (except in
  `delete_model`).

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

- insecure:

  allow insecure connections to the library. Only use this if you are
  pulling from your own library during development.

- background:

  download model(s) in background without blocking the session.

- verbose:

  Whether to print status messages to the Console. Either `TRUE`/`FALSE`
  or see
  [httr2::progress_bars](https://httr2.r-lib.org/reference/progress_bars.html).
  The default is to have status messages in interactive sessions. Can be
  changed with `options(rollama_verbose = FALSE)`.

- destination:

  name of the copied model.

## Value

(invisible) a tibble with information about the model (except in
`delete_model`)

## Details

- `pull_model()`: downloads model

- `show_model()`: displays information about a local model

- `copy_model()`: creates a model with another name from an existing
  model

- `delete_model()`: deletes local model

**Model names**: Model names follow a model:tag format, where model can
have an optional namespace such as example/model. Some examples are
orca-mini:3b-q4_1 and llama3.1:70b. The tag is optional and, if not
provided, will default to latest. The tag is used to identify a specific
version.

## Examples

``` r
if (FALSE) { # \dontrun{
# download a model and save information in an object
model_info <- pull_model("mixtral")
# after you pull, you can get the same information with:
model_info <- show_model("mixtral")
# pulling models from Hugging Face Hub is also possible
pull_model("https://huggingface.co/oxyapi/oxy-1-small-GGUF:Q2_K")
} # }
```
