test_that("embeddings", {
  skip_if_not(ping_ollama(silent = TRUE))
  out <- embed_text(c("Test 1", "Test 2"), model = "nomic-embed-text")
  expect_equal(nrow(out), 2)
  expect_true(ncol(out) > 1)
  # embedding columns are named dim_*
  expect_true(all(grepl("^dim_\\d+$", names(out))))
})

test_that("dimensions parameter reduces embedding size", {
  skip_if_not(ping_ollama(silent = TRUE))
  # not all models support dimensions; skip if the server ignores it
  out_full <- embed_text("Hello", model = "nomic-embed-text")
  out_small <- embed_text("Hello", dimensions = 4L, model = "nomic-embed-text")
  skip_if(
    ncol(out_full) == ncol(out_small),
    "model does not support dimensions"
  )
  expect_equal(ncol(out_small), 4L)
})

test_that("truncate parameter is accepted without error", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_no_error(embed_text(
    "A long piece of text.",
    truncate = TRUE,
    model = "nomic-embed-text"
  ))
})

test_that("keep_alive parameter is accepted without error", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_no_error(embed_text(
    "Hello",
    keep_alive = "1m",
    model = "nomic-embed-text"
  ))
})

test_that("missing model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_error(embed_text("test", model = "missing"), "not.installed")
})
