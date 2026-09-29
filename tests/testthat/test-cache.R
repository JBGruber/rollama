# ---- helpers ----------------------------------------------------------------

make_fake_req <- function(
  model = "llama3.1",
  content = "test",
  stream = FALSE,
  server = "http://localhost:11434",
  ...
) {
  httr2::request(server) |>
    httr2::req_url_path_append("/api/chat") |>
    httr2::req_body_json(list(
      model = model,
      messages = list(list(role = "user", content = content)),
      stream = stream,
      ...
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
  expect_equal(req_hash(make_fake_req()), "2e52d4ea12589b3f4bd93a2f027e1f85")
})

test_that("req_hash_legacy still returns the hash used by rollama <= 0.3.1", {
  expect_equal(
    req_hash_legacy(make_fake_req()),
    "84509e0fca78bfe92d29a181dfbbce1d"
  )
})

test_that("req_hash does not depend on the locale", {
  req <- make_fake_req(content = "Gr\u00fc\u00dfe \u2013 \U0001F600")
  hash <- req_hash(req)
  withr::with_locale(c(LC_CTYPE = "C"), expect_equal(req_hash(req), hash))
})

test_that("req_hash ignores server, stream and keep_alive", {
  expect_equal(
    req_hash(make_fake_req()),
    req_hash(make_fake_req(
      server = "http://other:11434",
      stream = TRUE,
      keep_alive = "5m"
    ))
  )
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

test_that("resolve_cache_paths creates the directory for a single request", {
  sub_dir <- file.path(withr::local_tempdir(), "new_cache")
  expect_message(resolve_cache_paths(sub_dir, list(make_fake_req())), "Created")
  expect_true(dir.exists(sub_dir))
})

test_that("resolve_cache_paths renames cache files from rollama <= 0.3.1", {
  tmp <- withr::local_tempdir()
  reqs <- list(make_fake_req(content = "q1"), make_fake_req(content = "q2"))
  legacy <- file.path(tmp, paste0(req_hash_legacy(reqs[[1]]), ".json"))
  writeLines(ollama_json("old answer"), legacy)

  expect_message(
    paths <- resolve_cache_paths(tmp, reqs),
    "Renamed 1 cache file"
  )
  expect_false(file.exists(legacy))
  expect_true(file.exists(paths[1]))
  expect_false(file.exists(paths[2]))
  expect_equal(
    httr2::resp_body_json(read_cache(paths[1]))$message$content,
    "old answer"
  )
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

test_that("check_cache_valid returns FALSE for an Ollama error response", {
  tmp <- withr::local_tempfile(fileext = ".json")
  writeLines('{"error":"model runner has unexpectedly stopped"}', tmp)
  expect_false(check_cache_valid(tmp))
})

test_that("check_cache_valid returns FALSE for JSON that is not a response", {
  tmp <- withr::local_tempfile(fileext = ".json")
  writeLines("[1, 2, 3]", tmp)
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

# ---- perform_reqs_with_cache ------------------------------------------------

# mocked responses bypass httr2's file writing, so the mock writes the cache
# file itself; `bodies` is used in turn for each call
mock_ollama <- function(cache_dir, bodies, status = 200L) {
  env <- new.env()
  env$calls <- 0L
  env$fn <- function(req) {
    env$calls <- env$calls + 1L
    i <- min(env$calls, length(bodies))
    path <- file.path(cache_dir, paste0(req_hash(req), ".json"))
    writeLines(bodies[[i]], path)
    httr2::response(status_code = rep_len(status, i)[[i]])
  }
  env
}

test_that("perform_reqs_with_cache sends identical requests only once", {
  tmp <- withr::local_tempdir()
  mock <- mock_ollama(tmp, list(ollama_json()))
  withr::local_options(httr2_mock = mock$fn)
  reqs <- list(
    make_fake_req(content = "a"),
    make_fake_req(content = "a"),
    make_fake_req(content = "b")
  )
  paths <- resolve_cache_paths(tmp, reqs)

  resps <- perform_reqs_with_cache(reqs, paths, verbose = FALSE)

  expect_equal(mock$calls, 2L)
  expect_length(resps, 3L)
  expect_equal(
    httr2::resp_body_json(resps[[2]])$message$content,
    "Because Rayleigh scattering."
  )
})

test_that("perform_reqs_with_cache retries failed requests", {
  tmp <- withr::local_tempdir()
  mock <- mock_ollama(
    tmp,
    list('{"error":"try again"}', ollama_json("second time lucky")),
    status = c(500L, 200L)
  )
  withr::local_options(httr2_mock = mock$fn)
  reqs <- list(make_fake_req())
  paths <- resolve_cache_paths(tmp, reqs)

  expect_message(
    resps <- perform_reqs_with_cache(reqs, paths, verbose = FALSE),
    "retrying"
  )
  expect_equal(mock$calls, 2L)
  expect_equal(
    httr2::resp_body_json(resps[[1]])$message$content,
    "second time lucky"
  )
})

test_that("perform_reqs_with_cache gives up after retries and keeps no error files", {
  tmp <- withr::local_tempdir()
  mock <- mock_ollama(
    tmp,
    list('{"error":"model runner has unexpectedly stopped"}'),
    status = 500L
  )
  withr::local_options(httr2_mock = mock$fn)
  reqs <- list(make_fake_req())
  paths <- resolve_cache_paths(tmp, reqs)

  expect_error(
    suppressMessages(
      perform_reqs_with_cache(reqs, paths, verbose = FALSE, retries = 2L)
    ),
    "unexpectedly stopped"
  )
  expect_equal(mock$calls, 3L)
  expect_false(file.exists(paths))
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

  # cache file names are content hashes, so their alphabetical listing order
  # need not match request order; derive the paths the same way query() does
  # to reliably target the third *request's* cache file
  reqs <- query(qs, stream = FALSE, output = "httr2_request")
  cache_files <- resolve_cache_paths(tmp, reqs)
  expect_length(cache_files, 3L)
  expect_true(all(file.exists(cache_files)))

  # simulate a corrupted/missing cache entry for the third request
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
