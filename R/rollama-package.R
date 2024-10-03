# package environment
the <- new.env()

#' @keywords internal
"_PACKAGE"

#' @title rollama Options
#' @name rollama-options
#'
#' @description The behaviour of `rollama` can be controlled through
#' `options()`. Specifically, the options below can be set.
#'
#' @details
#' \describe{
#' \item{rollama_server}{\describe{
#'   This controls the default server where Ollama is expected to run. It assumes
#'   that you are running Ollama locally in a Docker container.
#'   \item{default:}{\code{"http://localhost:11434"}}
#' }}
#' \item{rollama_model}{\describe{
#'   The default model is llama3.1, which is a good overall option with reasonable
#'   performance and size for most tasks. You can change the model in each
#'   function call or globally with this option.
#'   \item{default:}{\code{"llama3.1"}}
#' }}
#' \item{rollama_verbose}{\describe{
#'   Whether the package tells users what is going on, e.g., showing a spinner
#'   while the models are thinking or showing the download speed while pulling
#'   models. Since this adds some complexity to the code, you might want to
#'   disable it when you get errors (it won't fix the error, but you get a
#'   better error trace).
#'   \item{default:}{\code{TRUE}}
#' }}
#' \item{rollama_config}{\describe{
#'   The default configuration or system message. If NULL, the system message
#'   defined in the used model is employed.
#'   \item{default:}{None}
#' }}
#' }
#' @examples
#' options(rollama_config = "You make answers understandable to a 5 year old")
NULL

## usethis namespace: start
## usethis namespace: end
NULL
