options("rollama_verbose" = FALSE)

test_that("pull model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(nrow(pull_model()), 1L)
})

test_that("pull several models", {
  skip_if_not(ping_ollama(silent = TRUE))
  models <- list_models()$name
  skip_if(length(models) < 2L, "needs at least two local models")
  out <- pull_model(models[1:2])
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 2L)
})

test_that("show model", {
  skip_if_not(ping_ollama(silent = TRUE))
  out <- show_model()
  expect_equal(nrow(out), 1L)
  expect_s3_class(out, "tbl_df")
  expect_equal(ncol(list_models()), 14L)
  expect_s3_class(list_models(), "tbl_df")
})

test_that("show model detailed", {
  skip_if_not(ping_ollama(silent = TRUE))
  out_default <- show_model(detailed = FALSE)
  out_detailed <- show_model(detailed = TRUE)
  expect_equal(nrow(out_detailed), 1L)
  expect_s3_class(out_detailed, "tbl_df")
  # detailed = TRUE should return at least as many columns
  expect_gt(
    length(unlist(out_detailed$model_info)),
    length(unlist(out_default$model_info))
  )
})

test_that("create model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_equal(
    nrow(create_model(
      "mario",
      from = "llama3.1",
      system = "You are mario from Super Mario Bros."
    )),
    1L
  )
})

test_that("copy model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(copy_model("mario"), "model.mario.copied.to.mario-copy")
})

test_that("delete model", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_message(delete_model("mario"), "model.mario.removed")
  expect_message(delete_model("mario-copy"), "model.mario-copy.removed")
})

test_that("model missing", {
  skip_if_not(ping_ollama(silent = TRUE))
  expect_error(
    check_model_installed("NOMODEL"),
    "Model.NOMODEL:latest.not.installed."
  )
})

test_that("list running models", {
  skip_if_not(ping_ollama(silent = TRUE))
  query("test", keep_alive = "30s")
  expect_s3_class(list_running_models(), "data.frame")
  expect_gte(ncol(list_running_models()), 8L)
  expect_gte(nrow(list_running_models()), 1L)
})
