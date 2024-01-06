test_that("Test query", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(query("test"), ".")
})

test_that("Test chat", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(chat("Please only say 'yes'"), "Yes")
  expect_message(chat("One more time"), "Yes")
  expect_equal(nrow(chat_history()), 4L)
  expect_equal({
    new_chat()
    nrow(chat_history())
  }, 0L)
})
