# Generate and format queries for a language model

`make_query` generates structured input for a language model, including
system prompt, user messages, and optional examples (assistant answers).

## Usage

``` r
make_query(
  text,
  prompt,
  template = "{prefix}{text}\n{prompt}\n{suffix}",
  system = NULL,
  prefix = NULL,
  suffix = NULL,
  examples = NULL
)
```

## Arguments

- text:

  A character vector of texts to be annotated.

- prompt:

  A string defining the main task or question to be passed to the
  language model.

- template:

  A string template for formatting user queries, containing placeholders
  like `{text}`, `{prefix}`, and `{suffix}`.

- system:

  An optional string to specify a system prompt.

- prefix:

  A prefix string to prepend to each user query.

- suffix:

  A suffix string to append to each user query.

- examples:

  A `tibble` with columns `text` and `answer`, representing example user
  messages and corresponding assistant responses.

## Value

A list of tibbles, one for each input `text`, containing structured rows
for system messages, user messages, and assistant responses.

## Details

The function supports the inclusion of examples, which are dynamically
added to the structured input. Each example follows the same format as
the primary user query.

## Examples

``` r
template <- "{prefix}{text}\n\n{prompt}{suffix}"
examples <- tibble::tribble(
  ~text, ~answer,
  "This movie was amazing, with great acting and story.", "positive",
  "The film was okay, but not particularly memorable.", "neutral",
  "I found this movie boring and poorly made.", "negative"
)
queries <- make_query(
  text = c("A stunning visual spectacle.", "Predictable but well-acted."),
  prompt = "Classify sentiment as positive, neutral, or negative.",
  template = template,
  system = "Provide a sentiment classification.",
  prefix = "Review: ",
  suffix = " Please classify.",
  examples = examples
)
print(queries)
#> [[1]]
#> # A tibble: 8 × 2
#>   role      content                                                           
#>   <chr>     <glue>                                                            
#> 1 system    Provide a sentiment classification.                               
#> 2 user      Review: This movie was amazing, with great acting and story.
#> 
#> Class…
#> 3 assistant positive                                                          
#> 4 user      Review: The film was okay, but not particularly memorable.
#> 
#> Classif…
#> 5 assistant neutral                                                           
#> 6 user      Review: I found this movie boring and poorly made.
#> 
#> Classify sentim…
#> 7 assistant negative                                                          
#> 8 user      Review: A stunning visual spectacle.
#> 
#> Classify sentiment as positiv…
#> 
#> [[2]]
#> # A tibble: 8 × 2
#>   role      content                                                           
#>   <chr>     <glue>                                                            
#> 1 system    Provide a sentiment classification.                               
#> 2 user      Review: This movie was amazing, with great acting and story.
#> 
#> Class…
#> 3 assistant positive                                                          
#> 4 user      Review: The film was okay, but not particularly memorable.
#> 
#> Classif…
#> 5 assistant neutral                                                           
#> 6 user      Review: I found this movie boring and poorly made.
#> 
#> Classify sentim…
#> 7 assistant negative                                                          
#> 8 user      Review: Predictable but well-acted.
#> 
#> Classify sentiment as positive…
#> 
if (ping_ollama()) { # only run this example when Ollama is running
  query(queries, stream = TRUE, output = "text")
}
#> ✖ Could not connect to Ollama at <http://localhost:11434>
```
