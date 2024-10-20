if (ping_ollama(silent = TRUE)) {
  try({
    delete_model("mario")
    delete_model("mario-copy")
  }, silent = TRUE)
}
