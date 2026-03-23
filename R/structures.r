#' Create a structured output schema
#'
#' @description
#' Build a JSON Schema for structured output. Pass named type objects as
#' arguments, or supply raw JSON via `.schema`. These functions specify a JSON
#' schema that LLMs can be told to use in their outputs. This is particularly
#' effective for structured data extraction. Their names are based on the [JSON
#' schema](https://json-schema.org), which is what the APIs expect behind the
#' scenes. See the [structured outputs article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
#' for a tutorial.
#'
#' * `type_boolean()`, `type_integer()`, `type_number()`, and `type_string()`
#'   each represent scalars. These are equivalent to length-1 logical,
#'   integer, double, and character vectors (respectively).
#'
#' * `type_enum()` is equivalent to a length-1 factor; it is a string that can
#'   only take the specified values.
#'
#' * `type_array()` is equivalent to a vector in R. You can use it to represent
#'   an atomic vector: e.g. `type_array(type_boolean())` is equivalent
#'   to a logical vector and `type_array(type_string())` is equivalent
#'   to a character vector). You can also use it to represent a list of more
#'   complicated types where every element is the same type (R has no base
#'   equivalent to this), e.g. `type_array(type_array(type_string()))`
#'   represents a list of character vectors.
#'
#' * `type_object()` is equivalent to a named list in R, but where every element
#'   must have the specified type. For example,
#'   `type_object(a = type_string(), b = type_array(type_integer()))` is
#'   equivalent to a list with an element called `a` that is a string and
#'   an element called `b` that is an integer vector.
#'
#'
#' * `type_ignore()` is used in tool calling to indicate that an argument should
#'   not be provided by the LLM. This is useful when the R function has a
#'   default value for the argument and you don't want the LLM to supply it.
#'
#' * `type_from_schema()` allows you to specify the full schema that you want to
#'   get back from the LLM as a JSON schema. This is useful if you have a
#'   pre-defined schema that you want to use directly without manually creating
#'   the type using the `type_*()` functions. You can point to a file with the
#'   `path` argument or provide a JSON string with `text`. The schema must be a
#'   valid JSON schema object.
#'
#' @seealso [query()] and [chat()] where the schema is passed via the `format`
#'   argument. [Structured outputs article](https://jbgruber.github.io/rollama/articles/structured_outputs.html)
#'   for a tutorial.
#'
#' @param ... Named rollama type objects representing top-level properties.
#' @param .description,description Optional description for the schema.
#' @param .additional_properties Whether to allow additional properties.
#' @param .schema A raw JSON string or file path to use as the schema directly.
#' @param .required,required Whether this field is required in the parent
#'   object.
#' @param values A character vector of allowed values.
#' @param items A rollama type object describing the array items.
#' @export
create_schema <- function(
  ...,
  .description = NULL,
  .additional_properties = FALSE,
  .schema = NULL
) {
  if (!is.null(.schema)) {
    if (file.exists(.schema)) {
      .schema <- paste(readLines(.schema, warn = FALSE), collapse = "\n")
    }
    parsed <- jsonlite::parse_json(.schema, simplifyVector = FALSE)
    return(structure(parsed, class = "rollama_schema_raw"))
  }
  type_object(
    .description = .description,
    ...,
    .required = TRUE,
    .additional_properties = .additional_properties
  )
}


#' @export
#' @rdname create_schema
type_string <- function(description = NULL, required = TRUE) {
  new_rollama_type("string", description = description, required = required)
}


#' @export
#' @rdname create_schema
type_boolean <- function(description = NULL, required = TRUE) {
  new_rollama_type("boolean", description = description, required = required)
}


#' @export
#' @rdname create_schema
type_integer <- function(description = NULL, required = TRUE) {
  new_rollama_type("integer", description = description, required = required)
}


#' @export
#' @rdname create_schema
type_number <- function(description = NULL, required = TRUE) {
  new_rollama_type("number", description = description, required = required)
}


#' @export
#' @rdname create_schema
type_enum <- function(values, description = NULL, required = TRUE) {
  new_rollama_type(
    "enum",
    values = values,
    description = description,
    required = required
  )
}


#' @export
#' @rdname create_schema
type_array <- function(items, description = NULL, required = TRUE) {
  new_rollama_type(
    "array",
    items = items,
    description = description,
    required = required
  )
}

#' @export
#' @rdname create_schema
type_object <- function(
  .description = NULL,
  ...,
  .required = TRUE,
  .additional_properties = FALSE
) {
  new_rollama_type(
    "object",
    description = .description,
    required = .required,
    additional_properties = .additional_properties,
    properties = list(...)
  )
}

#' @export
print.rollama_type <- function(x, ...) {
  cli::cat_line(cli::col_grey("<rollama structured output schema>"))
  if (x$type == "object") {
    desc_str <- if (is.null(x$description)) {
      "<NULL>"
    } else {
      paste0('"', x$description, '"')
    }
    req_str <- if (isTRUE(x$required)) {
      paste0(" (", cli::col_br_red("required"), ")")
    } else {
      ""
    }
    cli::cat_line(paste0(
      cli::col_grey("\u251c\u2500object: "),
      desc_str,
      req_str
    ))
    if (length(x$properties) > 0) {
      cli::cat_line(cli::col_grey("\u2514\u2500properties"))
      props <- x$properties
      n <- length(props)
      for (i in seq_along(props)) {
        rollama_type_line(
          props[[i]],
          name = names(props)[i],
          prefix = "  ",
          is_last = i == n
        )
      }
    }
  } else {
    rollama_type_line(x, name = NULL, prefix = "", is_last = TRUE)
  }
  invisible(x)
}


rollama_type_trunc <- function(s, max_chars = 32) {
  if (!is.null(s) && nchar(s) > max_chars) {
    paste0(substr(s, 1, max_chars), "...")
  } else {
    s
  }
}


rollama_type_line <- function(x, name = NULL, prefix = "", is_last = TRUE) {
  conn <- if (is_last) "\u2514\u2500" else "\u251c\u2500"
  cont <- if (is_last) "  " else paste0(cli::col_grey("\u2502"), " ")
  type <- x$type
  name <- if (!is.null(name)) paste0("<", name) else "<"

  if (type == "enum") {
    values_str <- rollama_type_trunc(paste(
      paste0('"', x$values, '"'),
      collapse = ", "
    ))
    content <- cli::col_blue(paste0(
      c(name, paste0("<one_of: ", values_str)),
      collapse = ", ",
      ">"
    ))
  } else {
    content <- if (!is.null(x$description)) {
      if (name != "<") {
        name <- paste0(name, ": ")
      }
      paste(name, cli::style_italic(rollama_type_trunc(x$description)), ">")
    } else {
      paste0(name, ">")
    }
  }
  content <- if (content == "<>") NULL else paste(cli::col_blue(content), " ")

  content <- if (isTRUE(x$required)) {
    paste0(content, "(", cli::col_br_red("required"), ")")
  } else {
    ""
  }

  cli::cat_line(paste0(
    prefix,
    cli::col_grey(paste0(conn, type, ": ")),
    content
  ))

  child_prefix <- paste0(prefix, cont)

  if (type == "object" && length(x$properties) > 0) {
    cli::cat_line(paste0(child_prefix, cli::col_grey("\u2514\u2500properties")))
    prop_prefix <- paste0(child_prefix, "  ")
    props <- x$properties
    n <- length(props)
    for (i in seq_along(props)) {
      rollama_type_line(
        props[[i]],
        name = names(props)[i],
        prefix = prop_prefix,
        is_last = i == n
      )
    }
  } else if (type == "array" && !is.null(x$items)) {
    cli::cat_line(paste0(child_prefix, cli::col_grey("\u2514\u2500items")))
    rollama_type_line(
      x$items,
      name = NULL,
      prefix = paste0(child_prefix, "  "),
      is_last = TRUE
    )
  }
}


#' @export
as.list.rollama_type <- function(x, ...) {
  as_json_schema(x)
}


# Internal constructor
new_rollama_type <- function(type, ...) {
  structure(
    list(type = type, ...),
    class = c(paste0("rollama_type_", type), "rollama_type")
  )
}


# Serialization generic
as_json_schema <- function(x, ...) UseMethod("as_json_schema")


#' @export
as_json_schema.default <- function(x, ...) x


#' @export
as_json_schema.rollama_type_string <- function(x, ...) {
  out <- list(type = "string")
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_boolean <- function(x, ...) {
  out <- list(type = "boolean")
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_integer <- function(x, ...) {
  out <- list(type = "integer")
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_number <- function(x, ...) {
  out <- list(type = "number")
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_enum <- function(x, ...) {
  out <- list(type = "string", enum = as.list(x$values))
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_array <- function(x, ...) {
  out <- list(type = "array", items = as_json_schema(x$items))
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_type_object <- function(x, ...) {
  props <- lapply(x$properties, as_json_schema)
  required_names <- names(Filter(function(p) isTRUE(p$required), x$properties))
  out <- list(type = "object", properties = props)
  if (length(required_names) > 0) {
    out$required <- as.list(required_names)
  }
  out$additionalProperties <- isTRUE(x$additional_properties)
  if (!is.null(x$description)) {
    out$description <- x$description
  }
  out
}


#' @export
as_json_schema.rollama_schema_raw <- function(x, ...) {
  unclass(x)
}


#' @export
as_json_schema.character <- function(x, ...) {
  tryCatch(
    jsonlite::parse_json(x, simplifyVector = TRUE),
    error = function(e) {
      cli::cli_abort(
        "Could not parse {.arg format} as JSON: {conditionMessage(e)}"
      )
    }
  )
}


# S7 objects (ellmer and tidyllm) — S3 dispatch can't handle "::" in class
# names, so we dispatch manually via inherits()
#' @export
as_json_schema.S7_object <- function(x, ...) {
  if (inherits(x, "ellmer::TypeBasic")) {
    out <- list(type = x@type)
    if (!is.null(x@description)) {
      out$description <- x@description
    }
    out
  } else if (inherits(x, "ellmer::TypeEnum")) {
    out <- list(type = "string", enum = as.list(x@values))
    if (!is.null(x@description)) {
      out$description <- x@description
    }
    out
  } else if (inherits(x, "ellmer::TypeArray")) {
    out <- list(type = "array", items = as_json_schema(x@items))
    if (!is.null(x@description)) {
      out$description <- x@description
    }
    out
  } else if (inherits(x, "ellmer::TypeObject")) {
    props <- lapply(x@properties, as_json_schema)
    required_names <- names(Filter(
      function(p) isTRUE(p@required),
      x@properties
    ))
    out <- list(type = "object", properties = props)
    if (length(required_names) > 0) {
      out$required <- as.list(required_names)
    }
    out$additionalProperties <- isTRUE(x@additional_properties)
    if (!is.null(x@description)) {
      out$description <- x@description
    }
    out
  } else if (inherits(x, "tidyllm::tidyllm_field")) {
    type <- S7::prop(x, "type")
    description <- S7::prop(x, "description")
    enum <- S7::prop(x, "enum")
    vector <- S7::prop(x, "vector")
    schema <- S7::prop(x, "schema")
    if (type == "object") {
      inner <- schema
    } else {
      inner <- list(type = type)
      if (length(enum) > 0) {
        inner$enum <- as.list(enum)
      }
      if (length(description) > 0 && !isTRUE(vector)) {
        inner$description <- description
      }
    }
    if (isTRUE(vector)) {
      out <- list(type = "array", items = inner)
      if (length(description) > 0) {
        out$description <- description
      }
      return(out)
    }
    inner
  } else {
    x
  }
}
