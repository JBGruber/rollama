test_that("Test query", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(query("test"), ".")
  expect_message(query("test", verbose = TRUE), ".")
})

test_that("Test chat", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(chat("Please only say 'yes'"), "Yes")
  expect_message(chat("One more time"), "Yes")
  expect_equal(nrow(chat_history()), 4L)
  # check order of history
  expect_equal(chat_history()$content[c(1, 3)],
               c("Please only say 'yes'", "One more time"))
  expect_equal(chat_history()$role,
               c("user", "assistant", "user", "assistant"))
  expect_error(query(q = tibble::tibble(role = "assistant", content = "Pos")),
               "needs.at.least.one.user.message")
  expect_equal({
    new_chat()
    nrow(chat_history())
  }, 0L)
})

test_that("Test inputs", {
  skip_if_not(ping_ollama(silent = TRUE))
  # text
  expect_message(query("test"), ".")
  # text + image (I don't want to pull a different model for this, the API still
  # works with models that can't handle images)
  query("test",
        images = system.file("extdata", "logo.png", package = "rollama"))
  # data.frame
  expect_message(query(data.frame(role = "user", content = "test")), ".")
  expect_error(query(data.frame(role = "system", content = "test")),
               "at.least.one.user.message")
  # list of data.frames
  l <- rep(list(data.frame(role = "user", content = "test")), 5)
  answers <- query(l, screen = FALSE)
  expect_length(answers, 5)
  expect_type(answers, "list")
  expect_type(answers[[1]], "list")
})

test_that("Test output parameter", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_s3_class(
    query("Please only say 'yes'", output = "httr2_request")[[1]],
    "httr2_request"
  )
  expect_error(query("Please only say 'yes'", output = "invalid"),
               "should.be.one.of")

  skip_if_not(ping_ollama(silent = TRUE))
  # "httr2_response", "text", "list", "data.frame", "httr2_request"
  expect_s3_class(
    query("Please only say 'yes'", screen = FALSE,
          output = "httr2_response")[[1]],
    "httr2_response"
  )
  expect_equal(
    names(query("Please only say 'yes'", screen = FALSE,
                output = "list")[[1]]),
    c("request", "response")
  )
  expect_equal(
    colnames(query("Please only say 'yes'", screen = FALSE,
                   output = "data.frame")),
    c("model", "role", "response")
  )
})

test_that("Test seed", {
  skip_if_not(ping_ollama(silent = TRUE))
  snapshot <- query("test", model_params = list(seed = 42), output = "text")
  expect_equal(query("test", model_params = list(seed = 42), output = "text"),
               snapshot)
  expect_equal({
    withr::with_options(list(rollama_seed = 42),
                        query("test", output = "text"))
  }, snapshot)
  # different seed, different result
  expect_false(isTRUE(all.equal(
    query("test", model_params = list(seed = 1), output = "text"),
    snapshot
  )))
})
