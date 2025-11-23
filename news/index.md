# Changelog

## rollama (development version)

## rollama 0.2.2

CRAN release: 2025-04-25

## rollama 0.2.1

CRAN release: 2025-04-24

- added support for structured output
- added support for custom headers (e.g., for authentication)
- added option for custom outputs
- some bug fixes and improved documentation

## rollama 0.2.0

CRAN release: 2024-12-06

- added make_query() function to facilitate easier annotation
- added more output formats to query()/chat()
- improved performance of embed_text()
- improved performance of query() for multiple queries
- changed default model to llama3.1
- added option to employ multiple servers
- pull_model() gained verbose option
- improved annotation vignette
- added vignette on how to use Hugging Face Hub models
- some bug fixes

## rollama 0.1.0

CRAN release: 2024-05-01

- adds function `check_model_installed`
- changes default model to llama3

## rollama 0.0.3

CRAN release: 2024-03-21

- add option to query several models at once
- dedicated embedding models are available now (see
  [`vignette("text-embedding", "rollama")`](https://jbgruber.github.io/rollama/articles/text-embedding.md))
- error handling and bug fixes

## rollama 0.0.2

CRAN release: 2024-01-29

- Initial CRAN submission.
