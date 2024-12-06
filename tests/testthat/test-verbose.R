cli::test_that_cli("pull model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_snapshot(pull_model("llama3.2:3b-instruct-q8_0", verbose = TRUE))
})

cli::test_that_cli("perform_req", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_snapshot(chat("Please only say 'yes'", screen = FALSE, verbose = TRUE))
})

cli::test_that_cli("perform_reqs", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_snapshot(query("Please only say 'yes'",
                      model = c("llama3.1", "llama3.2:3b-instruct-q8_0"),
                      screen = FALSE,
                      verbose = TRUE))
})

