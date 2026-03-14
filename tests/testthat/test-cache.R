# ---- helpers ----------------------------------------------------------------

make_fake_req <- function(
  model = "llama3.1",
  content = "test",
  stream = FALSE
) {
  httr2::request("http://localhost:11434") |>
    httr2::req_url_path_append("/api/chat") |>
    httr2::req_body_json(list(
      model = model,
      messages = list(list(role = "user", content = content)),
      stream = stream
    ))
}

ollama_json <- function(content = "Because Rayleigh scattering.") {
  jsonlite::toJSON(
    list(
      model = "llama3.1",
      created_at = "2024-01-01T00:00:00Z",
      message = list(role = "assistant", content = content),
      done = TRUE
    ),
    auto_unbox = TRUE
  )
}

# ---- req_hash ---------------------------------------------------------------

test_that("req_hash deterministically returns a 32-character hash string", {
  expect_equal(req_hash(make_fake_req()), "0227ca5af8ae565c3383d248a8b1010a")
})

test_that("req_hash differs for different model or content", {
  expect_false(
    req_hash(make_fake_req(model = "llama3.1")) ==
      req_hash(make_fake_req(model = "phi3"))
  )
  expect_false(
    req_hash(make_fake_req(content = "a")) ==
      req_hash(make_fake_req(content = "b"))
  )
})

# ---- resolve_cache_paths ----------------------------------------------------

test_that("resolve_cache_paths returns NULL when cache is NULL", {
  expect_null(resolve_cache_paths(NULL, list()))
})

test_that("resolve_cache_paths in directory mode creates dir and returns hashed paths", {
  cache_dir <- withr::local_tempdir()
  sub_dir <- file.path(cache_dir, "new_cache")
  reqs <- list(make_fake_req(content = "q1"), make_fake_req(content = "q2"))

  paths <- resolve_cache_paths(sub_dir, reqs)

  expect_true(dir.exists(sub_dir))
  expect_length(paths, 2L)
  expect_true(all(startsWith(paths, sub_dir)))
  expect_true(all(endsWith(paths, ".json")))
  # different questions → different file names
  expect_false(paths[[1]] == paths[[2]])
})

test_that("resolve_cache_paths uses an existing directory without error", {
  tmp <- withr::local_tempdir()
  reqs <- list(make_fake_req())
  expect_no_error(resolve_cache_paths(tmp, reqs))
})

test_that("resolve_cache_paths accepts an explicit path vector", {
  tmp <- withr::local_tempdir()
  explicit <- file.path(tmp, c("a.json", "b.json"))
  reqs <- list(make_fake_req(content = "q1"), make_fake_req(content = "q2"))
  expect_equal(resolve_cache_paths(explicit, reqs), explicit)
})

test_that("resolve_cache_paths aborts on length mismatch", {
  reqs <- list(
    make_fake_req(content = "q1"),
    make_fake_req(content = "q2"),
    make_fake_req(content = "q3")
  )
  expect_error(
    # should fail because only_one.json is not a cache dir that could be expanded
    resolve_cache_paths(c("q1.json", "q2.json"), reqs),
    "length mismatch"
  )
})

# ---- check_cache_valid ------------------------------------------------------

test_that("check_cache_valid returns FALSE for a missing file", {
  expect_false(check_cache_valid(tempfile(fileext = ".json")))
})

test_that("check_cache_valid returns TRUE for a valid JSON file", {
  tmp <- withr::local_tempfile(fileext = ".json")
  writeLines(ollama_json(), tmp)
  expect_true(check_cache_valid(tmp))
})

test_that("check_cache_valid returns FALSE for a corrupted file", {
  tmp <- withr::local_tempfile(fileext = ".json")
  writeLines("not valid json {{{{", tmp)
  expect_false(check_cache_valid(tmp))
})

# ---- read_cache -------------------------------------------------------------

test_that("read_cache returns an httr2_response with the original JSON body", {
  tmp <- withr::local_tempfile(fileext = ".json")
  writeLines(ollama_json("sky is blue"), tmp)

  resp <- read_cache(tmp)

  expect_s3_class(resp, "httr2_response")
  body <- httr2::resp_body_json(resp)
  expect_equal(body$message$content, "sky is blue")
  expect_equal(body$message$role, "assistant")
})

# ---- integration tests ------------------------------------------------------

test_that("query saves responses to a cache directory on first call", {
  skip_if_not(ping_ollama(silent = TRUE))
  tmp <- withr::local_tempdir()

  query("test", stream = FALSE, cache = tmp)

  expect_length(list.files(tmp, pattern = "\\.json$"), 1L)
})

test_that("query returns identical results when loading from cache", {
  skip_if_not(ping_ollama(silent = TRUE))
  tmp <- tempfile(fileext = ".json")

  res1 <- query("test", stream = FALSE, cache = tmp, output = "text")
  res2 <- query("test", stream = FALSE, cache = tmp, output = "text")

  expect_equal(res1, res2)
})

test_that("query with cache and stream = TRUE emits info and proceeds", {
  skip_if_not(ping_ollama(silent = TRUE))
  tmp <- withr::local_tempdir()

  expect_message(
    query("test", stream = TRUE, cache = tmp),
    "Disabling.streaming"
  )
})

test_that("query with cache and output = 'httr2_response' aborts", {
  expect_error(
    query("test", stream = FALSE, output = "httr2_response", cache = tempdir()),
    "not.compatible"
  )
})

test_that("query with cache runs only missing requests on partial cache hit", {
  skip_if_not(ping_ollama(silent = TRUE))
  tmp <- withr::local_tempdir()

  qs <- c("question one", "question two", "question three")
  res1 <- query(qs, stream = FALSE, cache = tmp, output = "text")

  cache_files <- list.files(tmp, pattern = "\\.json$", full.names = TRUE)
  expect_length(cache_files, 3L)

  # simulate a corrupted/missing cache entry
  unlink(cache_files[3])

  expect_message(
    res2 <- query(
      qs,
      stream = FALSE,
      cache = tmp,
      output = "text",
      verbose = TRUE
    ),
    "cached"
  )
  expect_equal(length(res1), length(res2))
  expect_equal(res1[1:2], res2[1:2])
})

test_that("query accepts explicit per-request cache paths", {
  skip_if_not(ping_ollama(silent = TRUE))
  tmp <- withr::local_tempdir()
  paths <- file.path(tmp, c("resp1.json", "resp2.json"))

  res1 <- query(
    c("q1", "q2"),
    stream = FALSE,
    cache = paths,
    output = "text"
  )
  expect_true(all(file.exists(paths)))

  res2 <- query(
    c("q1", "q2"),
    stream = FALSE,
    cache = paths,
    output = "text"
  )
  expect_equal(res1, res2)
})
