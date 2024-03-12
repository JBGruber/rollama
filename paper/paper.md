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
date: 13 March 2024
bibliography: paper.bib
---

# Summary
`rollama` is an R package that wraps the Ollama API, which allows you to run different Generative Large Language Models (GLLM)[^1] locally. The package makes it easy to use Ollama for annotating textual or imagine data with open-source models.

# Statement of need

As researchers embrace the next revolution in computational social science, the arrival of GLLM, there is a critical need for open-source alternatives. This need arises to avoid falling into a reproducibility trap or becoming overly dependent on services offered by for-profit companies.

After the release of ChatGPT, researchers began utilizing OpenAI's API to annotate textual data with the aid of GPT models  [e.g., @GilardiChatGPT2023; @He_Lin_et_al._2023]. However, this approach presents several shortcomings, including privacy and replication issues associated with relying on proprietary models [@Spirling_2023; @weber2023evaluation].

Fortunately, since GLLMs were popularized by OpenAI's ChatGPT a little more than a year ago, a large and active alliance of open-source communities and technology companies has made considerable efforts to provide open models that rival, and sometimes surpass, proprietary ones.

One method of utilizing open models involves downloading them from a platform known as Hugging Face and setting them up. However, there is now software available that facilitates access to these models in an environment, allowing users to simply specify the model or models they wish to use. This can be done locally on one's computer, and the software is called Ollama.

[^1]: Also referred to generative AI or Generative Pre-trained Transformer (GPT).

# Background: Ollama

Ollama can be installed using dedicated installers for macOS and Windows, or through a bash installation script for Linux[^2]. However, our preferred method is to utilize Docker. This approach enhances security and simplifies the processes of updating, rolling back, and completely removing Ollama. For convenience, we provide a Docker compose file to start a container running Ollama and one running Open WebUI -- a browser interface strongly inspired by ChatGPT -- in a GitHub Gist[^3].

[^2]: <https://ollama.com/download>
[^3]: <https://gist.github.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc>

# Usage
After Ollama is installed, the R-package `rollama`  can be installed from CRAN (the Comprehensive R Archive Network):

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

# Main functions
The core of the package are two functions: `query()` and `chat()`.
The difference is that `chat()` saves the history of the conversation with an Ollama model, while `query()` treats every question as a new conversation.

# Learning material

We provide tutorials for the package at [jbgruber.github.io/rollama](https://jbgruber.github.io/rollama/) and an initial overview is available as a YouTube video[^4].

[^4]: <https://youtu.be/N-k3RZqiSZY>

# References
