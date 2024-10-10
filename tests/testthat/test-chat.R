test_that("Test query", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(query("test"), ".")
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

test_that("Test output parameter", {
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


query("why is the sky blue?", output = "httr2_request")
