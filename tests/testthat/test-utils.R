test_that("verbose", {
  expect_no_message({
    op <- options("rollama_verbose" = FALSE)
    on.exit(options(op), add = TRUE, after = FALSE)
    query(q = "test", screen = FALSE)
  })
})
