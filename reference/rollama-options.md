# rollama Options

The behaviour of `rollama` can be controlled through
[`options()`](https://rdrr.io/r/base/options.html). Specifically, the
options below can be set.

## Details

- rollama_server:

  default:

  :   `"http://localhost:11434"`

- rollama_model:

  default:

  :   `"llama3.1"`

- rollama_verbose:

  default:

  :   `TRUE`

- rollama_config:

  default:

  :   None

- rollama_seed:

  default:

  :   None

- rollama_cache_retries:

  default:

  :   `3`

## Examples

``` r
options(rollama_config = "You make answers understandable to a 5 year old")
```
