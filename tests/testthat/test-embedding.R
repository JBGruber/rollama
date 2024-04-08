test_that("embedding", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(nrow(embed_text(c("Test 1", "Test 2"))), 2)
})

test_that("missing model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_error(embed_text("test", model = "missing"),
               "try.pulling.it.first")
})
