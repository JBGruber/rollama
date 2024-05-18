test_that("ping", {
  expect_type(ping_ollama(), "logical")
  expect_type(ping_ollama(silent = TRUE), "logical")
  expect_no_message(ping_ollama(silent = TRUE))
})

test_that("verbose", {
  expect_no_message({
    skip_if_not(ping_ollama(silent = TRUE))
    op <- options("rollama_verbose" = FALSE)
    on.exit(options(op), add = TRUE, after = FALSE)
    query(q = "test", screen = FALSE)
  })
})
