test_that("ping", {
  expect_type(ping_ollama(), "logical")
})

test_that("verbose", {
  expect_no_message({
    skip_if_not(ping_ollama(silent = TRUE))
    op <- options("rollama_verbose" = FALSE)
    on.exit(options(op), add = TRUE, after = FALSE)
    query(q = "test", screen = FALSE)
  })
})
