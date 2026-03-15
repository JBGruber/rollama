# Using Structured Outputs

Structured outputs are an efficient way to constrain models to return
specific, machine-readable information. This is especially useful for
annotation and information extraction tasks where you need results that
can be immediately parsed and used downstream in your analysis.

The key idea: instead of asking the model in plain English to “please
respond in JSON”, you pass a formal JSON Schema alongside your prompt.
Ollama uses this schema to constrain the model’s token sampling – a
technique called *constrained decoding* or *grammar-based sampling* – so
that the output is **always** valid JSON matching your schema. In other
words, before each token is sampled, Ollama derives the set of tokens
that are valid at the current position in the output (e.g. `{` at the
very start of a JSON object, or only digits and `"` inside a number
field). All other tokens in the vocabulary – tens of thousands of them –
have their logit score set to −∞, which collapses their probability to 0
after the softmax step. Sampling then happens entirely within the valid
subset, guaranteeing compliance with the schema without any post-hoc
filtering. This is more reliable than prompt engineering alone, where
models can drift from the requested format.

``` r
library(rollama)
```

## Defining a Schema

The
[`create_schema()`](https://jbgruber.github.io/rollama/reference/create_schema.md)
function lets you build a schema by combining named type declarations.
Each field maps to a JSON Schema primitive:

| rollama function                                                                  | R equivalent  | JSON Schema type       |
|-----------------------------------------------------------------------------------|---------------|------------------------|
| [`type_string()`](https://jbgruber.github.io/rollama/reference/create_schema.md)  | `character`   | `"string"`             |
| [`type_boolean()`](https://jbgruber.github.io/rollama/reference/create_schema.md) | `logical`     | `"boolean"`            |
| [`type_integer()`](https://jbgruber.github.io/rollama/reference/create_schema.md) | `integer`     | `"integer"`            |
| [`type_number()`](https://jbgruber.github.io/rollama/reference/create_schema.md)  | `double`      | `"number"`             |
| `type_enum(values)`                                                               | `factor`      | `"string"` with `enum` |
| `type_array(items)`                                                               | vector / list | `"array"`              |
| `type_object(...)`                                                                | named list    | `"object"`             |

Here is a schema that captures country-level information:

``` r
country_schema <- create_schema(
  name = type_string(description = "Name of the country"),
  capital = type_string(description = "Name of the capital"),
  population = type_number(
    description = "Number of inhabitants, convert to absolute numbers"
  ),
  # Note that description is optional
  continent = type_enum(
    values = c(
      "Asia",
      "Africa",
      "North America",
      "South America",
      "Antarctica",
      "Europe",
      "Oceania"
    )
  ),
  nato_member = type_boolean(),
  official_languages = type_array(
    items = type_string(),
    description = "Official languages"
  )
)
country_schema
#> <rollama structured output schema>
#> ├─object: <NULL> (required)
#> └─properties
#>   ├─string: <name:  Name of the country >  (required)
#>   ├─string: <capital:  Name of the capital >  (required)
#>   ├─number: <population:  Number of inhabitants, convert t... >  (required)
#>   ├─enum: <continent>, <one_of: "Asia", "Africa", "North America...>  (required)
#>   ├─boolean: <nato_member>  (required)
#>   └─array: <official_languages:  Official languages >  (required)
#>     └─items
#>       └─string: (required)
```

Printing the schema gives a readable tree view of its structure.

## Extracting Information from Text

Pass the schema to the `format` argument of
[`query()`](https://jbgruber.github.io/rollama/reference/query.md). The
model will fill in every field declared in the schema from the supplied
text:

``` r
input_text <- "Canada is a country in North America. With a population of over 41 million, it has widely varying population densities, with the majority residing in its urban areas and large areas being sparsely populated. Its capital is Ottawa and its three largest metropolitan areas are Toronto, Montreal, and Vancouver. Canada is officially bilingual (English and French). It is a member of the North Atlantic Treaty Organization (NATO)."

res <- make_query(
  input_text,
  prompt = "Extract information about the country from the text below. Do not make things up. Convert numbers into their full numeric form.",
  template = "{prompt}\n\nTEXT:\n\n{text}"
) |>
  query(
    model = "llama3.2:1b",
    format = country_schema,
    output = "text",
    stream = FALSE
  )
```

Because the output is guaranteed to be valid JSON, you can parse it
directly:

``` r
jsonlite::fromJSON(res) |>
  tibble::as_tibble()
#> # A tibble: 2 × 6
#>   name   capital population continent     nato_member official_languages
#>   <chr>  <chr>        <int> <chr>         <lgl>       <chr>             
#> 1 Canada Ottawa    41000000 North America TRUE        English           
#> 2 Canada Ottawa    41000000 North America TRUE        French
```

## Batch Extraction

[`make_query()`](https://jbgruber.github.io/rollama/reference/make_query.md)
accepts a vector of texts, and
[`query()`](https://jbgruber.github.io/rollama/reference/query.md)
accepts lists of queries, so you can run structured extraction over many
texts in a single pipeline:

``` r
country_texts <- c(
  "Germany is a country in Central Europe. Its capital is Berlin and it has a population of about 84 million people. Germany is a founding member of NATO and the official language is German.",
  "Brazil is the largest country in South America, with a population of around 215 million. The capital is Brasília. Portuguese is the official language. Brazil is not a member of NATO.",
  "Japan is an island nation in East Asia with approximately 125 million inhabitants. Its capital is Tokyo. Japanese is the official language. Japan is not a NATO member."
)

queries <- make_query(
  country_texts,
  prompt = "Extract information about the country from the text. Do not make things up. Convert numbers into their full numeric form.",
  template = "{prompt}\n\nTEXT:\n\n{text}"
)

results <- query(
  queries,
  model = "llama3.2:1b",
  format = country_schema,
  output = "text",
  screen = FALSE,
  stream = FALSE
)
#> 
⠙ llama3.2:1b is thinking about 3/3 questions[ETA: ?]

⠹ llama3.2:1b is thinking about 2/3 questions[ETA: 2s]

⠸
#> llama3.2:1b is thinking about 1/3 questions[ETA: 1s]


# Parse all results at once
countries_df <- purrr::map(results, jsonlite::fromJSON) |>
  purrr::map(\(x) {
    tibble::as_tibble(lapply(x, \(v) if (length(v) > 1) list(v) else v))
  }) |>
  dplyr::bind_rows()

countries_df
#> # A tibble: 3 × 6
#>   name    capital  population continent     nato_member official_languages
#>   <chr>   <chr>         <int> <chr>         <lgl>       <chr>             
#> 1 Germany Berlin     84000000 Europe        TRUE        german            
#> 2 Brazil  Brasília        215 South America FALSE       Portuguese        
#> 3 Japan   Tokyo     125000000 Asia          FALSE       Japanese
```

## Nested Objects

For more complex structures,
[`type_object()`](https://jbgruber.github.io/rollama/reference/create_schema.md)
can be nested to represent hierarchical data. Here is a schema for a
scientific paper that contains a nested author object:

``` r
paper_schema <- create_schema(
  title = type_string(description = "Title of the paper"),
  year = type_integer(description = "Publication year"),
  authors = type_array(
    description = "List of authors",
    items = type_object(
      name = type_string(description = "Full name of the author"),
      affiliation = type_string(description = "Institutional affiliation")
    )
  ),
  keywords = type_array(
    items = type_string(),
    description = "Key topics covered by the paper"
  ),
  open_access = type_boolean(
    description = "Whether the paper is freely available"
  )
)

paper_text <- "We present 'Attention Is All You Need' (2017) by Ashish Vaswani (Google Brain), Noam Shazeer (Google Brain), and Illia Polosukhin (Google Research). The paper introduces the Transformer architecture and covers topics such as attention mechanisms, neural machine translation, and sequence modelling. The paper is freely available on arXiv."

make_query(
  paper_text,
  prompt = "Extract the bibliographic information from the text below.",
  template = "{prompt}\n\nTEXT:\n\n{text}"
) |>
  query(
    model = "llama3.2:1b",
    format = paper_schema,
    output = "text",
    stream = FALSE
  ) |>
  jsonlite::fromJSON()
#> 
⠙ llama3.2:1b is thinking

⠹ llama3.2:1b is thinking

⠸ llama3.2:1b is thinking

#> $title
#> [1] "Attention Is All You Need"
#> 
#> $year
#> [1] 2017
#> 
#> $authors
#>               name     affiliation
#> 1   Ashish Vaswani    Google Brain
#> 2     Noam Shazeer    Google Brain
#> 3 Illia Polosukhin Google Research
#> 
#> $keywords
#> [1] "Transformer architecture"   "attention mechanisms"       "neural machine translation"
#> [4] "sequence modelling"        
#> 
#> $open_access
#> [1] TRUE
```

## Image-Based Extraction

Structured outputs work seamlessly with multimodal models. Instead of
getting a free-text description of an image, you can extract structured
data from it directly.

First, pull a vision-capable model:

``` r
pull_model("llama3.2-vision")
#> ℹ pulling manifest
#> ✔ pulling manifest [9ms]
#> 
#> ℹ verifying sha256 digest
#> ✔ verifying sha256 digest [3ms]
#> 
#> ℹ writing manifest
#> ✔ writing manifest [4ms]
#> ✔ success!
#> ✔ model llama3.2-vision pulled succesfully!
```

Define a schema for the visual attributes you want to extract:

``` r
image_schema <- create_schema(
  subject = type_string(description = "Main subject or object in the image"),
  style = type_enum(
    values = c(
      "photograph",
      "illustration",
      "diagram",
      "chart",
      "logo",
      "other"
    ),
    description = "Visual style of the image"
  ),
  dominant_colors = type_array(
    items = type_string(),
    description = "Up to three dominant colors"
  ),
  background = type_string(description = "Description of the background"),
  text_present = type_boolean(description = "Whether the image contains text"),
  mood = type_enum(
    values = c("professional", "playful", "serious", "neutral", "dramatic"),
    description = "Overall mood or tone of the image"
  )
)
```

Then query the model with both the image and the schema:

``` r
logo_url <- "https://raw.githubusercontent.com/JBGruber/rollama/master/man/figures/logo.png"

res_image <- query(
  q = "Analyse this image and fill in the structured fields.",
  model = "llama3.2-vision",
  images = logo_url,
  format = image_schema,
  output = "text",
  stream = FALSE
)


jsonlite::fromJSON(res_image) |>
  tibble::as_tibble()
#> # A tibble: 3 × 6
#>   subject style dominant_colors background text_present mood   
#>   <chr>   <chr> <chr>           <chr>      <lgl>        <chr>  
#> 1 Rollama logo  white           blue       TRUE         playful
#> 2 Rollama logo  blue            blue       TRUE         playful
#> 3 Rollama logo  green           blue       TRUE         playful
```

## Alternative Ways to Provide Structured Outputs

If you find `rollama`s structured output types and schema creation
confusing (let us know, but also) just use the schema creation that
seems most natural to you.

### Create as a list

``` r
country_schema_list <- list(
  type = "object",
  properties = list(
    name = list(type = "string", description = "Name of the country"),
    capital = list(type = "string", description = "Name of the capital"),
    population = list(
      type = "number",
      description = "Number of inhabitants, convert to absolute numbers"
    ),
    continent = list(
      type = "string",
      enum = list(
        "Asia",
        "Africa",
        "North America",
        "South America",
        "Antarctica",
        "Europe",
        "Oceania"
      )
    ),
    nato_member = list(type = "boolean"),
    official_languages = list(
      type = "array",
      items = list(type = "string"),
      description = "Official languages"
    )
  ),
  required = list(
    "name",
    "capital",
    "population",
    "continent",
    "nato_member",
    "official_languages"
  ),
  additionalProperties = FALSE
)
q <- make_query(
  input_text,
  prompt = "Extract information about the country from the text below. Do not make things up. Convert numbers into their full numeric form.",
  template = "{prompt}\n\nTEXT:\n\n{text}"
)
query(
  q,
  model = "llama3.2:1b",
  format = country_schema_list,
  output = "text"
)
#> 
#> ── Answer from llama3.2:1b ───────────────────────────────────────────────────────────────────────────────────────────
#> 
#> {
#>  "name": "Canada",
#>  "capital": "Ottawa",
#>  "population": 41000000, "continent": "North America",
#>  "nato_member": true,
#>  "official_languages": ["English", "French"] 
#> }
```

### Create as json string

``` r
country_schema_json <- '{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Name of the country"
    },
    "capital": {
      "type": "string",
      "description": "Name of the capital"
    },
    "population": {
      "type": "number",
      "description": "Number of inhabitants, convert to absolute numbers"
    },
    "continent": {
      "type": "string",
      "enum": [
        "Asia",
        "Africa",
        "North America",
        "South America",
        "Antarctica",
        "Europe",
        "Oceania"
      ]
    },
    "nato_member": {
      "type": "boolean"
    },
    "official_languages": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Official languages"
    }
  },
  "required": [
    "name",
    "capital",
    "population",
    "continent",
    "nato_member",
    "official_languages"
  ],
  "additionalProperties": false
}'
query(
  q,
  model = "llama3.2:1b",
  format = country_schema_json,
  output = "text"
)
#> 
#> ── Answer from llama3.2:1b ───────────────────────────────────────────────────────────────────────────────────────────
#> 
#> {"name": "Canada", "capital": "Ottawa", "population": 41000000, "continent": "North America", "nato_member": true, "official_languages": ["English", "French"]}
```

### Using ellmer

The `ellmer` package introduces it’s own type system, which has the same
names for most types. Attaching the package thus issues a warning.
However, `rollama` handles the duplicated function names under the hood
and you can use the types as expected (beware of the `ellmer::chat()`
function, however, which works quite differently from
[`rollama::chat()`](https://jbgruber.github.io/rollama/reference/query.md))

``` r
library(ellmer)
#> 
#> Attaching package: 'ellmer'
#> The following objects are masked from 'package:rollama':
#> 
#>     chat, type_array, type_boolean, type_enum, type_integer, type_number, type_object, type_string
country_schema_ellmer <- type_object(
  name = type_string(description = "Name of the country"),
  capital = type_string(description = "Name of the capital"),
  population = type_number(
    description = "Number of inhabitants, convert to absolute numbers"
  ),
  # Note that description is optional
  continent = type_enum(
    values = c(
      "Asia",
      "Africa",
      "North America",
      "South America",
      "Antarctica",
      "Europe",
      "Oceania"
    )
  ),
  nato_member = type_boolean(),
  official_languages = type_array(
    items = type_string(),
    description = "Official languages"
  )
)
country_schema_ellmer
#> <ellmer::TypeObject>
#>  @ description          : NULL
#>  @ required             : logi TRUE
#>  @ properties           :List of 6
#>  .. $ name              : <ellmer::TypeBasic>
#>  ..  ..@ description: chr "Name of the country"
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ type       : chr "string"
#>  .. $ capital           : <ellmer::TypeBasic>
#>  ..  ..@ description: chr "Name of the capital"
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ type       : chr "string"
#>  .. $ population        : <ellmer::TypeBasic>
#>  ..  ..@ description: chr "Number of inhabitants, convert to absolute numbers"
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ type       : chr "number"
#>  .. $ continent         : <ellmer::TypeEnum>
#>  ..  ..@ description: NULL
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ values     : chr [1:7] "Asia" "Africa" "North America" "South America" ...
#>  .. $ nato_member       : <ellmer::TypeBasic>
#>  ..  ..@ description: NULL
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ type       : chr "boolean"
#>  .. $ official_languages: <ellmer::TypeArray>
#>  ..  ..@ description: chr "Official languages"
#>  ..  ..@ required   : logi TRUE
#>  ..  ..@ items      : <ellmer::TypeBasic>
#>  .. .. .. @ description: NULL
#>  .. .. .. @ required   : logi TRUE
#>  .. .. .. @ type       : chr "string"
#>  @ additional_properties: logi FALSE
```

``` r
query(
  q,
  model = "llama3.2:1b",
  format = country_schema_ellmer,
  output = "text"
)
#> 
#> ── Answer from llama3.2:1b ───────────────────────────────────────────────────────────────────────────────────────────
#> 
#> {
#>  "name": "Canada",
#>  "capital": "Ottawa",
#>  "population": 41000000, "continent": "North America",
#>  "nato_member": true,
#>  "official_languages": ["English", "French"] 
#> }
```

### Using tidyllm

Like `ellmer`, `tidyllm` uses its own system to define structured
outputs. Once again, the output schema is compatible with `rollama` yet
[`chat()`](https://jbgruber.github.io/rollama/reference/query.md) and
[`list_models()`](https://jbgruber.github.io/rollama/reference/list_models.md)
are masked as `tidyllm` defines these functions as well.

``` r
library(tidyllm)
#> 
#> Attaching package: 'tidyllm'
#> The following object is masked from 'package:ellmer':
#> 
#>     chat
#> The following objects are masked from 'package:rollama':
#> 
#>     chat, list_models
#> The following object is masked from 'package:stats':
#> 
#>     embed
country_schema_tidyllm <- field_object(
  name = field_chr(.description = "Name of the country"),
  capital = field_chr(.description = "Name of the capital"),
  population = field_dbl(
    .description = "Number of inhabitants, convert to absolute numbers"
  ),
  continent = field_fct(
    .levels = c(
      "Asia",
      "Africa",
      "North America",
      "South America",
      "Antarctica",
      "Europe",
      "Oceania"
    )
  ),
  nato_member = field_lgl(),
  official_languages = field_chr(
    .description = "Official languages",
    .vector = TRUE
  )
)
country_schema_tidyllm
#> <tidyllm::tidyllm_field>
#>  @ type       : chr "object"
#>  @ description: chr(0) 
#>  @ enum       : chr(0) 
#>  @ vector     : logi FALSE
#>  @ schema     :List of 3
#>  .. $ type      : chr "object"
#>  .. $ properties:List of 6
#>  ..  ..$ name              :List of 2
#>  ..  .. ..$ type       : chr "string"
#>  ..  .. ..$ description: chr "Name of the country"
#>  ..  ..$ capital           :List of 2
#>  ..  .. ..$ type       : chr "string"
#>  ..  .. ..$ description: chr "Name of the capital"
#>  ..  ..$ population        :List of 2
#>  ..  .. ..$ type       : chr "number"
#>  ..  .. ..$ description: chr "Number of inhabitants, convert to absolute numbers"
#>  ..  ..$ continent         :List of 2
#>  ..  .. ..$ type: chr "string"
#>  ..  .. ..$ enum: chr [1:7] "Asia" "Africa" "North America" "South America" ...
#>  ..  ..$ nato_member       :List of 1
#>  ..  .. ..$ type: chr "boolean"
#>  ..  ..$ official_languages:List of 2
#>  ..  .. ..$ type : chr "array"
#>  ..  .. ..$ items:List of 2
#>  ..  .. .. ..$ type       : chr "string"
#>  ..  .. .. ..$ description: chr "Official languages"
#>  .. $ required  : 'AsIs' chr [1:6] "name" "capital" "population" "continent" ...
```

``` r
query(
  q,
  model = "llama3.2:1b",
  format = country_schema_tidyllm,
  output = "text"
)
#> 
#> ── Answer from llama3.2:1b ───────────────────────────────────────────────────────────────────────────────────────────
#> 
#> {
#>  "name": "Canada",
#>  "capital": "Ottawa",
#>  "population": 41000000, "continent": "North America",
#>  "nato_member": true,
#>  "official_languages": ["English", "French"] 
#> }
#> 
```
