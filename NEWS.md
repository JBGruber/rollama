# rollama (development version)

* `query()` can now batch annotate several images with the same prompt by passing `images` as a list (one element per query)
* updated image annotation vignette to explain batch annotation
* fixes issue in tests

# rollama 0.3.0

* adds option to cache responses
* query now supports logprobs output
* make it possible to supply several questions at once
* add authentication vignette
* implemented structured outputs (including new vignette)
* synced package with Ollama API changes
* adds list_running_models()
* updated chat() and query()
* update parameters in embed_text()
* update parameters and output in show_model()
* rewrote progress and answer streaming
* bug fixes

# rollama 0.2.1

* added support for structured output
* added support for custom headers (e.g., for authentication)
* added option for custom outputs
* some bug fixes and improved documentation

# rollama 0.2.0

* added make_query() function to facilitate easier annotation
* added more output formats to query()/chat()
* improved performance of embed_text()
* improved performance of query() for multiple queries
* changed default model to llama3.1
* added option to employ multiple servers
* pull_model() gained verbose option
* improved annotation vignette 
* added vignette on how to use Hugging Face Hub models
* some bug fixes

# rollama 0.1.0

* adds function `check_model_installed`
* changes default model to llama3

# rollama 0.0.3

* add option to query several models at once
* dedicated embedding models are available now (see `vignette("text-embedding", "rollama")`)
* error handling and bug fixes

# rollama 0.0.2

* Initial CRAN submission.
