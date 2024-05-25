initialize_ollama <- function(version = "latest",
                              web_ui = TRUE,
                              GPU = TRUE) {

  pull(paste0("ollama/ollama:", version))
  if (web_ui) pull("ghcr.io/open-webui/open-webui:main")

  ollama_conf <- list(
    image = paste0("ollama/ollama:", version),
    container_name = "ollama",
    pull_policy = "missing",
    tty = TRUE,
    restart = "unless-stopped",
    ports = c("11434:11434", "53:53"),
    volumes = "ollama:/root/.ollama"
  )

  if (GPU) {
    ollama_conf$deploy <- list(resources = list(reservations = list(devices = list(
      list(driver = "nvidia", count = 1L, capabilities = "gpu")
    ))))
  }

  cli::cli_progress_step("starting Ollama")
  strt(webui_conf)
  cli::cli_progress_done()

  if (web_ui) {
    cli::cli_progress_step("starting open-webui")
    webui_conf <- list(
      image = "ghcr.io/open-webui/open-webui:main",
      container_name = "open-webui",
      pull_policy = "missing",
      volumes = "open-webui:/app/backend/data",
      depends_on = "ollama",
      ports = "3000:8080",
      environment = "OLLAMA_API_BASE_URL=http://ollama:11434/api",
      extra_hosts = "host.docker.internal:host-gateway",
      restart = "unless-stopped"
    )
    strt(webui_conf)
    cli::cli_progress_done()
  }

}


pull <- function(img) {
  if (length(img) != 1L) stop("You can only create one img at the time")
  req <- docker_base_req() |>
    httr2::req_url_path_append("images/create") |>
    httr2::req_url_query(fromImage = img) |>
    httr2::req_method("post") |>
    httr2::req_error(is_error = function(resp) FALSE)
  the$str_prgs <- NULL

  res <- req |>
    httr2::req_perform_stream(callback = pgrsdkr, buffer_kb = 0.1)
  cli::cli_progress_done()
}


strt <- function(conf) {
  req <- docker_base_req() |>
    httr2::req_url_path_append("containers/create") |>
    httr2::req_url_query(name = conf$container_name) |>
    httr2::req_method("post") |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_body_json(conf)

  res <- httr2::req_perform(req) |>
    httr2::resp_body_json()
  if (length(res$Warnings) > 0) cli::cli_alert_warning(res$Warnings)
  invisible(res$Id)
}


pgrsdkr <- function(resp) {
  resp <<- resp
  if (!getOption("rollama_verbose", default = interactive())) return(TRUE)
  if (is.null(the$str_prgs$bar_id)) {
    the$str_prgs$bar_id <- cli::cli_progress_bar(name = "Downloading images",
                                                 current = FALSE,
                                                 clear = FALSE,
                                                 auto_terminate = FALSE,
                                                 .envir = the)
  }
  the$str_prgs$stream_raw <- c(the$str_prgs$stream_raw, resp)
  resp <- the$str_prgs$stream_raw
  status <- strsplit(rawToChar(resp), "\r?\n", useBytes = TRUE)[[1]] |>
    head(-1) |> # ignore last line which might be incomplete
    textConnection() |>
    jsonlite::stream_in(verbose = FALSE, simplifyVector = FALSE)

  status <- setdiff(status, the$str_prgs$pb_done)

  for (s in status) {
    # this ignores digests and waiting status messages
    if (!purrr::pluck_exists(s, "progressDetail") &&
        purrr::pluck_exists(s, "id")) {
      if (!s$id %in% the$str_prgs$id_done) {
        cli::cli_alert_info("{s$status} ({s$id})")
        the$str_prgs$id_done <- c(s$id, the$str_prgs$id_done)
      }
    } else if (s$status == "Downloading") {
      the$str_prgs$downloads$current[[s$id]] <- s$progressDetail$current
      the$str_prgs$downloads$total[[s$id]] <- s$progressDetail$total
      cli::cli_progress_update(set = sum(unlist(the$str_prgs$downloads$current)),
                               total = sum(unlist(the$str_prgs$downloads$total)),
                               id = the$str_prgs$bar_id,
                               .envir = the)
    }
    the$str_prgs$pb_done <- append(the$str_prgs$pb_done, list(s))
  }
  return(TRUE)
}

docker_base_req <- function(verbose = FALSE) {
  if (R.Version()$os == "mingw32") {
    req <- httr2::request("http://localhost:2375")
  } else {
    req <- httr2::request("http://localhost:80") |>
      httr2::req_options(UNIX_SOCKET_PATH = "/var/run/docker.sock")
  }
  if(verbose) req <- httr2::req_options(req, debugfunction = return_status, verbose = TRUE)
  return(req)
}

