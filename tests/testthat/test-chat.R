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
