#' Install Ollama
#'
#' Minimally more convenient than to download Ollama from
#' <https://ollama.com/download> and installing it yourself.
#'
#' @param path folder to cache downloaded binary (for Windows and MacOS).
#' @param docker install through Docker Compose
#'   (<https://docs.docker.com/compose/>) instead of running Ollama directly.
#'
#' @returns Nothing, called to install Ollama application.
#' @export
install_ollama <- function(path,
                           docker = FALSE) {
  if (docker) {
    cmps <- curl::curl_download(
      "https://gist.githubusercontent.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc/raw/docker-compose.yml",
      "docker-compose.yml",
      quiet = TRUE
    )
    system2("docker-compose", args = c("up", "-d"))
  } else {
    sysname <- Sys.info()["sysname"]
    switch (sysname,
            "Windows" = install_win(path),
            "Linux"   = install_linux(path),
            "macos"   = install_macos(path)
    )
  }

}


install_win <- function(path) {
  if (missing(path)) {
    path <- tempdir()
  }

  f <- curl::curl_download("https://ollama.com/download/OllamaSetup.exe",
                           file.path(path, "OllamaSetup.exe"),
                           quiet = FALSE)
  system(f)
  invisible(NULL)
}

install_linux <- function(path) {
  if (missing(path)) {
    path <- tempdir()
  }

  f <- curl::curl_download("https://ollama.com/install.sh",
                           file.path(path, "OllamaInstall.sh"),
                           quiet = FALSE)
  system2("sh", args = f)
  system("ollama serve", wait = FALSE)
  invisible(NULL)
}

# NOT TESTED!
install_macos <- function(path) {
  if (missing(path)) {
    path <- tempdir()
  }

  f <- curl::curl_download("https://ollama.com/download/Ollama-darwin.zip",
                           file.path(path, "Ollama-darwin.zip"),
                           quiet = FALSE)
  f <- unzip(f)
  system(f)
  invisible(NULL)
}
