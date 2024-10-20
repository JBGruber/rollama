# slightly out of place, but we don't want to pull unnecessary models and this
# should come before the first test
test_that("Auto pull model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_true(check_model_installed(getOption("rollama_model", default = "llama3.1"),
                                    auto_pull = TRUE))
})
