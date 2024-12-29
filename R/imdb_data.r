#' Download IMDb Large Movie Review Dataset
#'
#' @param data_file file used to cache data
#' @inheritParams check_model_installed
#'
#' @return a data frame with 50k movie reviews
#' @export
#'
#' @examples
#' \dontrun{
#'   imdb_df <- dataset_imdb("imdb.rds")
#'   # sample 500 reviews
#'   set.seed(42)
#'   dplyr::slice_sample(imdb_df, n = 500L)
#' }
dataset_imdb <- function(data_file = NULL,
                         auto_pull = FALSE,
                         verbose = interactive()) {

  if (!isTRUE(try(file.exists(data_file), silent = TRUE))) {
    if (interactive() && !auto_pull) {
      msg <- c(
        "{cli::col_cyan(cli::symbol$info)}",
        " IMDb Large Movie Review Dataset not found locally.",
        " Shouldn it be downloaded from {.url http://ai.stanford.edu/~amaas/data/sentiment/}"
      )
      auto_pull <- utils::askYesNo(cli::cli_text(msg))
    }
    if (!auto_pull) {
      cli::cli_abort("IMDb Large Movie Review Dataset not found locally.")
      return(invisible(FALSE))
    }

    temp <- file.path(tempdir(), "imdb")
    dir.create(temp, recursive = TRUE, showWarnings = FALSE)
    if (verbose) cli::cli_progress_step("Downloading data")
    # download into a temporary folder and unpack archive
    curl::curl_download("http://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz",
                        file.path(temp, "aclImdb_v1.tar.gz"), quiet = FALSE)
    if (verbose) cli::cli_progress_step("Uncompressing data")
    untar(file.path(temp, "aclImdb_v1.tar.gz"), exdir = temp)
    files <- list.files(temp,
                        pattern = ".txt",
                        recursive = TRUE,
                        full.names = TRUE)
    # read in files
    imdb <- purrr::map(files, function(f) {
      tibble::tibble(
        file = f,
        text = readLines(f, warn = FALSE)
      )
    }, .progress = TRUE) |>
      dplyr::bind_rows() |>
      dplyr::mutate(label = stringr::str_extract(file, "/pos/|/neg/"),
                    label = stringr::str_remove_all(label, "/"),
                    label = factor(label),
                    dataset = stringr::str_extract(file, "/test/|/train/"),
                    dataset = stringr::str_remove_all(dataset, "/"),
                    dataset = factor(dataset)) |>
      dplyr::filter(!is.na(label)) |>
      dplyr::select(-file) |>
      # adding unique IDs for later
      dplyr::mutate(id = dplyr::row_number(), .before = 1L)
    if (verbose) cli::cli_progress_done()
    saveRDS(imdb, data_file)
  } else {
    if (verbose) cli::cli_progress_step("Loading cached data")
    imdb <- readRDS(data_file)
  }
  return(imdb)
}

