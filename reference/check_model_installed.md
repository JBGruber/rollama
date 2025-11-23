# Check if one or several models are installed on the server

Check if one or several models are installed on the server

## Usage

``` r
check_model_installed(
  model,
  check_only = FALSE,
  auto_pull = FALSE,
  server = NULL
)
```

## Arguments

- model:

  names of one or several models as character vector.

- check_only:

  only return TRUE/FALSE and don't download models.

- auto_pull:

  if FALSE, the default, asks before downloading models.

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

## Value

invisible TRUE/FALSE
