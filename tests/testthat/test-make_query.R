test_that("correct structure", {
  examples <- tibble::tribble(
    ~text, ~answer,
    "This movie was amazing, with great acting and story.", "positive",
    "The film was okay, but not particularly memorable.", "neutral",
    "I found this movie boring and poorly made.", "negative"
  )
  texts <- c("A stunning visual spectacle.", "Predictable but well-acted.")
  queries <- make_query(
    text = texts,
    prompt = "Classify sentiment as positive, neutral, or negative.",
    template = "{text}",
    system = "Provide a sentiment classification.",
    prefix = "Review: ",
    suffix = " Please classify.",
    examples = examples
  )
  expect_true(texts[2] %in% queries[[2]][["content"]])

  queries <- make_query(
    text = texts,
    prompt = "Classify sentiment as positive, neutral, or negative.",
    template = "{prefix}{text}\n{prompt}\n{suffix}",
    system = "Provide a sentiment classification.",
    prefix = "Review: ",
    suffix = " Please classify.",
    examples = examples
  )
  expect_length(queries, 2L)
  expect_type(queries, "list")
  expect_s3_class(queries[[1]], "tbl_df")
  expect_equal(nrow(queries[[1]]), 8L)

})

test_that("queries work with query()", {
  skip_if_not(ping_ollama(silent = TRUE))
  queries <- make_query(
    text = c("A stunning visual spectacle.", "Predictable but well-acted."),
    prompt = "Classify sentiment as positive, neutral, or negative.",
    template = "{prefix}{text}\n{prompt}\n{suffix}",
    system = "Provide a sentiment classification.",
    prefix = "Review: ",
    suffix = " Please classify."
  )
  results <- query(queries, output = "text", screen = FALSE)
  expect_type(results, "character")
  expect_length(results, 2L)
})
