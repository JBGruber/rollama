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
 - name: Johannes Gutenberg University Mainz
   index: 2
date: 09 March 2024
bibliography: paper.bib
---

# Summary

# Statement of need

As researchers embrace the next revolution in computational social science, the arrival of generative large language models (gLLM)[^1], we need open source alternatives to not fall into an reproducibility trap or make ourselves and our research projects too dependent on services offered by for-profit companies.

- people started using OpenAI's API to GPT models to annotate text [e.g., @GilardiChatGPT2023; @He_Lin_et_al._2023]
- However, this comes with several shortcomings [@Spirling_2023; @weber2023evaluation]

Luckily, since gLLMs were popularized by OpenAI's ChatGPT a little more than a year ago, a large and active alliance of open source communities and tech companies have made considerable efforts to provide open models that rival or sometimes surpass proprietary ones.

[^1]: Also referred to generative AI or Generative Pre-trained Transformer (GPT).

# Background: Ollama

The easiest way to install Ollama is to use their bash install script.
However, we prefer to run Ollama through Docker, as this provides additional security, makes Ollama available on Windows[^2], and makes it straightforward to update, roll back, and remove Ollama complelty.
We provide a Docker Compose file to start a container running Ollama and one running Open WebUI -- a browser interface stronmgly inspired by ChatGPT -- in a GitHub Gist[^3].

[^2]: At the time of writing a Windows version of Ollama is not available.
[^3]: <https://gist.github.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc>

# Flexible implementation through `httr2`


# Usage

The package can be installed from CRAN (the Comprehensive R Archive Network):

```r
install.packages("rollama")
```

or from GitHub using remotes [@remotes]:

``` r
# install.packages("remotes")
remotes::install_github("JBGruber/rollama")
```

After that, the user should check whether the Ollama API is up and running.

``` r
ping_ollama()
```

The core of the package are two functions: `query()` and `chat()`.
The difference is that `chat()` saves the history of the conversation with an Ollama model, while `query()` treats every question as a new conversation.

# Learning material

We provide tutorials for the package at [jbgruber.github.io/rollama](https://jbgruber.github.io/rollama/) and an inital overview is available as a YouTube video[^4].

[^4]: <https://youtu.be/N-k3RZqiSZY>

# References