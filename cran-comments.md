This is a re-submission. To clarify why \dontrun{} is used in most examples:
Ollama is a tool that can run ChatGPT-like large language models locally and 
opens an API that this package wraps. Since the package does not provide Ollama 
itself (the README mentions how to set it up), checking the examples would 
fail, unless Ollama was installed on the system first.


## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.
