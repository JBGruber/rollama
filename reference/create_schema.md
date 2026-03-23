# Create a structured output schema

Build a JSON Schema for structured output. Pass named type objects as
arguments, or supply raw JSON via `.schema`. These functions specify a
JSON schema that LLMs can be told to use in their outputs. This is
particularly effective for structured data extraction. Their names are
based on the [JSON schema](https://json-schema.org), which is what the
APIs expect behind the scenes. See the [structured outputs
article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
for a tutorial.

- `type_boolean()`, `type_integer()`, `type_number()`, and
  `type_string()` each represent scalars. These are equivalent to
  length-1 logical, integer, double, and character vectors
  (respectively).

- `type_enum()` is equivalent to a length-1 factor; it is a string that
  can only take the specified values.

- `type_array()` is equivalent to a vector in R. You can use it to
  represent an atomic vector: e.g. `type_array(type_boolean())` is
  equivalent to a logical vector and `type_array(type_string())` is
  equivalent to a character vector). You can also use it to represent a
  list of more complicated types where every element is the same type (R
  has no base equivalent to this), e.g.
  `type_array(type_array(type_string()))` represents a list of character
  vectors.

- `type_object()` is equivalent to a named list in R, but where every
  element must have the specified type. For example,
  `type_object(a = type_string(), b = type_array(type_integer()))` is
  equivalent to a list with an element called `a` that is a string and
  an element called `b` that is an integer vector.

- `type_ignore()` is used in tool calling to indicate that an argument
  should not be provided by the LLM. This is useful when the R function
  has a default value for the argument and you don't want the LLM to
  supply it.

- `type_from_schema()` allows you to specify the full schema that you
  want to get back from the LLM as a JSON schema. This is useful if you
  have a pre-defined schema that you want to use directly without
  manually creating the type using the `type_*()` functions. You can
  point to a file with the `path` argument or provide a JSON string with
  `text`. The schema must be a valid JSON schema object.

## Usage

``` r
create_schema(
  ...,
  .description = NULL,
  .additional_properties = FALSE,
  .schema = NULL
)

type_string(description = NULL, required = TRUE)

type_boolean(description = NULL, required = TRUE)

type_integer(description = NULL, required = TRUE)

type_number(description = NULL, required = TRUE)

type_enum(values, description = NULL, required = TRUE)

type_array(items, description = NULL, required = TRUE)

type_object(
  .description = NULL,
  ...,
  .required = TRUE,
  .additional_properties = FALSE
)
```

## Arguments

- ...:

  Named rollama type objects representing top-level properties.

- .description, description:

  Optional description for the schema.

- .additional_properties:

  Whether to allow additional properties.

- .schema:

  A raw JSON string or file path to use as the schema directly.

- values:

  A character vector of allowed values.

- items:

  A rollama type object describing the array items.

- .required, required:

  Whether this field is required in the parent object.

## See also

[`query()`](https://jbgruber.github.io/rollama/reference/query.md) and
[`chat()`](https://jbgruber.github.io/rollama/reference/query.md) where
the schema is passed via the `format` argument. [Structured outputs
article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
for a tutorial.
