---
title: 'rollama: An R package for using generative large language models through Ollama'
tags:
  - R
  - large language models
  - open models
authors:
  - name: Johannes B. Gruber
    orcid: 0000-0001-9177-1772
    corresponding: true # (This is how to denote the corresponding author)
    equal-contrib: false
    affiliation: 1
  - name:  Maximilian Weber
    orcid: 0000-0002-1174-449X
    equal-contrib: false
    affiliation: 2
affiliations:
 - name: University of Amsterdam
   index: 1
 - name: Goethe University Frankfurt
   index: 2
date: 18 March 2024
bibliography: paper.bib
---

# Summary

`rollama` is an R package that wraps the `Ollama` API, which allows you to run different Generative Large Language Models (GLLM)[^1] locally. The package and learning material focus on making it easy to use `Ollama` for annotating textual or imagine data with open-source models as well as use these models for document embedding. But users can use or extend `rollama` to do essentially anything else that is possible through OpenAI's API, yet more private, reproducible and for free.


# Statement of need

As researchers embrace the next revolution in computational social science, the arrival of GLLM, there is a critical need for open-source alternatives [@Spirling_2023]. This need arises to avoid falling into a reproducibility trap or becoming overly dependent on services offered by for-profit companies.

After the release of ChatGPT, researchers started using OpenAI's API for annotating text with GPT models [e.g., @GilardiChatGPT2023; @He_Lin_et_al._2023]. However, this approach presents several shortcomings, including privacy and replication issues associated with relying on proprietary models over which researchers have no control whatsoever [@Spirling_2023; @weber2023evaluation].

Fortunately, since GLLMs were popularized by OpenAI's ChatGPT a little more than a year ago, a large and active alliance of open-source communities and technology companies has made considerable efforts to provide open models that rival, and sometimes surpass, proprietary ones [@alizadeh2023opensource; @irugalbandara_trade-off_2024].

One method of utilizing open models involves downloading them from a platform known as Hugging Face and using them via Python scripts. However, there is now software available that facilitates access to these models in an environment, allowing users to simply specify the model or models they wish to use. This can be done locally on one's computer, and the software is called `Ollama`. The R package `rollama` provides a wrapper to use the `Ollama` API within R.

[^1]: Also referred to generative AI or Generative Pre-trained Transformer (GPT).

# Background: `Ollama`

`Ollama` can be installed using dedicated installers for macOS and Windows, or through a bash installation script for Linux[^2]. However, our preferred method is to utilize Docker -- an open-source containerization tool. This approach enhances security and simplifies the processes of updating, rolling back, and completely removing `Ollama`. For convenience, we provide a Docker compose file to start a container running `Ollama` and Open WebUI -- a browser interface strongly inspired by ChatGPT -- in a GitHub Gist[^3].

[^2]: <https://ollama.com/download>
[^3]: <https://gist.github.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc>

# Usage

After `Ollama` is installed, the R-package `rollama` can be installed from CRAN (the Comprehensive R Archive Network):

```r
install.packages("rollama")
```

or from GitHub using remotes:

``` r
# install.packages("remotes")
remotes::install_github("JBGruber/rollama")
```

After that, the user should check whether the `Ollama` API is up and running.

``` r
library(rollama)
ping_ollama()
```

After installation, the first step is to pull one of the models from [ollama.ai/library](https://ollama.ai/library) by using the model tag. By calling  `pull_model()` without any arguments will download the default model.

``` r
# pull the default model
pull_model()
# pull a specified model by providing the model tag
pull_model("gemma:2b-instruct-q4_0")
```

## Main functions

The core of the package are two functions: `query()` and `chat()`.
The difference is that `chat()` saves the history of the conversation with an `Ollama` model, while `query()` treats every question as a new conversation.

To ask a single question, the `query()` function can be used.

``` r
query("why is the sky blue?")
```

For conversational interactions, the `chat()` function is used.

``` r
chat("why is the sky blue?")
chat("and how do you know that?")
```

## Reproducible outcome

Within the `model_params` of the `query()` function, setting a seed is possible. When a seed is used, the temperature must be set to "0" to ensure consistent output for repeated prompts.

``` r
query("Why is the sky blue? Answer in one sentence.",
      model_params = list(
        seed = 42,
        temperature = 0
      ))
```

This is considerable advatage of `Ollama`, and `rollama` respectivly, over tools like ChatGPT, which will return different results each time and change the underlying models periodically. 

# Examples

We present several examples to illustrate some functionalities. As mentioned previously, many tasks that can be performed through OpenAI's API can also be accomplished by using open models within `Ollama`. Moreover, these models can be controlled with a seed, ensuring reproducible results.

## Annotating text

For annotating text data, various prompting strategies are available [see @weber2023evaluation for a comprehensive overview]. These strategies primarily differ in whether or how many examples are given (Zero-shot, One-shot, or Few-shot) and whether reasoning is involved (Chain-of-Thought).

When writing a prompt we can give the model content for the system part, user part and assistant part. The system message typically includes instructions or context that guides the interaction, setting the stage for how the user and the assistant should interact. For an annotation task we could write: “You assign texts into categories. Answer with just the correct category.” The following example is a zero-shot approach only containing a system message and one user message. In practice, annotating a single text is rarely the goal. For guidance on batch annotations[^4] and working with dataframes[^5], refer to the package documentation.

[^4]: <https://jbgruber.github.io/rollama/articles/annotation.html#batch-annotation>
[^5]: <https://jbgruber.github.io/rollama/articles/annotation.html#another-example-using-a-dataframe>

``` r
library(tibble)
library(purrr)
q <- tribble(
  ~role,    ~content,
  "system", "You assign texts into categories. Answer with just the correct category.",
  "user",   "text: the pizza tastes terrible\ncategories: positive, neutral, negative"
)
query(q, model_params = list(seed = 42, temperature = 0))
```

## Using multimodal models

`Ollama` also supports multimodal models, which can interact with (but at the moment not create) images. A model designed for image handling, such as the llava model, needs to be pulled. Using `pull_model("llava")` will download the model.

``` r
pull_model("llava")
query("Excitedly desscribe this logo", model = "llava",
      images = "https://ollama.com/public/ollama.png")
```

## Obtaining text embeddings 

`Ollama`, and hence rollama, can be utilized to generate text embeddings. In short, text embedding uses the knowledge of the meaning of words inferred from the context they are used in and saved in a large language model through its training to turn text into meaningful vectors of numbers [@kroon_transfer-learning2023].
This technique is a powerful preprocessing step for supervised machine learning and often increases the performance of a classification model substantially [@laurer_benchmarking2024].
The gLLMs, like the default llama2, which are the focus of `Ollama` can produce high quality document embeddings, however, to speed up the procedure, one can use specialized embedding models like nomic-embed-text[^6] or all-minilm[^7].

``` r
pull_model(model = "nomic-embed-text")
embed_text(text = "It’s a beautiful day", model = "nomic-embed-text")
```

These models were previously only available in Python, with the only ... for R users to use them through Python interface provided by `reticulate` [@ushey_reticulate2024] or packages build on top of it [e.g. @chan_grafzahl2023; @kjell_text2023] -- which users regularly struggle with due to the complexity of Python environments.
For a more detailed example of using embeddings for training supervised machine learning models and doing classification tasks, refer to the package documentation[^8]. 

[^6]: <https://ollama.com/library/nomic-embed-text>
[^7]: <https://ollama.com/library/all-minilm>
[^8]: <https://jbgruber.github.io/rollama/articles/text-embedding.html>


# Learning material

We provide tutorials for the package at [jbgruber.github.io/rollama](https://jbgruber.github.io/rollama/) and an initial overview is available as a YouTube video[^9].

[^9]: <https://youtu.be/N-k3RZqiSZY>

# References
