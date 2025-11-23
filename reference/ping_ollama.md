# Ping server to see if Ollama is reachable

Ping server to see if Ollama is reachable

## Usage

``` r
ping_ollama(server = NULL, silent = FALSE, version = FALSE)
```

## Arguments

- server:

  URL to one or several Ollama servers (not the API). Defaults to
  "http://localhost:11434".

- silent:

  suppress warnings and status (only return `TRUE`/`FALSE`).

- version:

  return version instead of `TRUE`.

## Value

TRUE if server is running
