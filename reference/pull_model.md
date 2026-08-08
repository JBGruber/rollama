# Pull, push, show and delete models

Pull, push, show and delete models

## Usage

``` r
pull_model(
  model = NULL,
  server = NULL,
  insecure = FALSE,
  background = FALSE,
  verbose = getOption("rollama_verbose", default = interactive())
)

push_model(
  model,
  server = NULL,
  insecure = FALSE,
  verbose = getOption("rollama_verbose", default = interactive())
)

show_model(model = NULL, detailed = FALSE, server = NULL)

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

- detailed:

  when `TRUE`, the column `model_info` will contain much more detailed
  information about the model.

- destination:

  name of the copied model.

## Value

(invisible) a tibble with information about the model, one row per model
(except in `delete_model` and `push_model`)

## Details

- `pull_model()`: downloads a model from the Ollama registry or Hugging
  Face

- `push_model()`: uploads a locally created model to the Ollama registry
  (ollama.com) so others can pull it. The model name must include your
  namespace (i.e. `"your_username/model_name"`). Before pushing you need
  to add your public key (`~/.ollama/id_ed25519.pub`) to your ollama.com
  account settings. This is mainly useful after
  [`create_model()`](https://jbgruber.github.io/rollama/reference/create_model.md)
  — you build a custom model locally (e.g. with a system prompt,
  quantisation, or fine-tuned weights) and then share it with
  collaborators or the public. You can also push to a
  private/self-hosted registry by using a model name that starts with
  the registry host (e.g. `"registry.example.com/mymodel"`); set
  `insecure = TRUE` if that registry does not use HTTPS.

- `show_model()`: displays information about a local model

- `copy_model()`: creates a model with another name from an existing
  model

- `delete_model()`: deletes local model

**Model names**: Model names follow a model:tag format, where model can
have an optional namespace such as example/model. Some examples are
orca-mini:3b-q4_1 and llama3.1:70b. The tag is optional and, if not
provided, will default to latest. The tag is used to identify a specific
version.

## Note

`push_model()` is intended for advanced users. It requires setup steps
that must be completed outside of R: you need an account on
<https://ollama.com>, and your Ollama public key
(`~/.ollama/id_ed25519.pub` on Linux/macOS) must be registered in your
account settings. The model name must be prefixed with your ollama.com
username (e.g. `"your_username/model_name"`); pushing without a
namespace will fail with a permission error. Unfortunately, more
user-friendly guidance cannot be provided here as the setup process is
managed entirely by Ollama outside of R.

## Examples

``` r
if (FALSE) { # \dontrun{
# download a model and save information in an object
model_info <- pull_model("mixtral")
# after you pull, you can get the same information with:
model_info <- show_model("mixtral")
# pulling models from Hugging Face Hub is also possible
pull_model("https://huggingface.co/oxyapi/oxy-1-small-GGUF:Q2_K")
# create a custom model and share it on ollama.com
create_model("your_username/mario", from = "llama3.1",
             system = "You are Mario from Super Mario Bros.")
push_model("your_username/mario")
} # }
```
