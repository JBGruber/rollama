# pull model [plain]

    Code
      pull_model("llama3.2:3b-instruct-q8_0", verbose = TRUE)
    Message
      v model llama3.2:3b-instruct-q8_0 pulled succesfully

# pull model [ansi]

    Code
      pull_model("llama3.2:3b-instruct-q8_0", verbose = TRUE)
    Message
      [32mv[39m model llama3.2:3b-instruct-q8_0 pulled succesfully

# pull model [unicode]

    Code
      pull_model("llama3.2:3b-instruct-q8_0", verbose = TRUE)
    Message
      ✔ model llama3.2:3b-instruct-q8_0 pulled succesfully

# pull model [fancy]

    Code
      pull_model("llama3.2:3b-instruct-q8_0", verbose = TRUE)
    Message
      [32m✔[39m model llama3.2:3b-instruct-q8_0 pulled succesfully

# perform_req [plain]

    Code
      chat("Please only say 'yes'", screen = FALSE, verbose = TRUE)

# perform_req [ansi]

    Code
      chat("Please only say 'yes'", screen = FALSE, verbose = TRUE)

# perform_req [unicode]

    Code
      chat("Please only say 'yes'", screen = FALSE, verbose = TRUE)

# perform_req [fancy]

    Code
      chat("Please only say 'yes'", screen = FALSE, verbose = TRUE)

# perform_reqs [plain]

    Code
      query("Please only say 'yes'", model = c("llama3.1",
        "llama3.2:3b-instruct-q8_0"), screen = FALSE, verbose = TRUE)
    Message
      \ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 1/2 questions
      \ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 0/2 questions

# perform_reqs [ansi]

    Code
      query("Please only say 'yes'", model = c("llama3.1",
        "llama3.2:3b-instruct-q8_0"), screen = FALSE, verbose = TRUE)
    Message
      \ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 1/2 questions
      \ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 0/2 questions

# perform_reqs [unicode]

    Code
      query("Please only say 'yes'", model = c("llama3.1",
        "llama3.2:3b-instruct-q8_0"), screen = FALSE, verbose = TRUE)

# perform_reqs [fancy]

    Code
      query("Please only say 'yes'", model = c("llama3.1",
        "llama3.2:3b-instruct-q8_0"), screen = FALSE, verbose = TRUE)
    Message
      ⠙ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 1/2 questions
      ⠙ llama3.1 and llama3.2:3b-instruct-q8_0 are thinking about 0/2 questions

