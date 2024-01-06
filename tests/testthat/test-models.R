options("rollama_verbose" = FALSE)

test_that("pull model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(nrow(pull_model()), 1L)
})

test_that("show model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(nrow(show_model()), 1L)
})

test_that("create model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(nrow(create_model(
    model = "mario",
    modelfile = "FROM llama2\nSYSTEM You are mario from Super Mario Bros."
  )), 1L)
})

test_that("copy model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(copy_model("mario"),
                 "model.mario.copied.to.mario-copy")
})

test_that("delete model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(delete_model("mario"),
                 "model.mario.removed")
  expect_message(delete_model("mario-copy"),
                 "model.mario-copy.removed")
})

