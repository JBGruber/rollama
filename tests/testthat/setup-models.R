if (ping_ollama(silent = TRUE)) {
  pull_model()
  try({
    delete_model("mario")
    delete_model("mario-copy")
  }, silent = TRUE)
}
