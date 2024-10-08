% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.r
\name{check_model_installed}
\alias{check_model_installed}
\title{Check if one or several models are installed on the server}
\usage{
check_model_installed(model, auto_pull = FALSE, server = NULL)
}
\arguments{
\item{model}{names of one or several models as character vector.}

\item{auto_pull}{if FALSE, the default, asks before downloading models.}

\item{server}{URL to an Ollama server (not the API). Defaults to
"http://localhost:11434".}
}
\value{
invisible TRUE/FALSE
}
\description{
Check if one or several models are installed on the server
}
