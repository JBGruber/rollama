
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rollama` <img src="man/figures/logo.png" align="right" height="138" alt="rollama-logo" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/JBGruber/rollama/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JBGruber/rollama/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/JBGruber/rollama/branch/main/graph/badge.svg)](https://app.codecov.io/gh/JBGruber/rollama?branch=main)
[![CRAN status](https://www.r-pkg.org/badges/version/rollama)](https://CRAN.R-project.org/package=rollama)
[![CRAN_Download_Badge](https://cranlogs.r-pkg.org/badges/grand-total/rollama)](https://cran.r-project.org/package=rollama)
[![arXiv:10.48550/arXiv.2404.07654](https://img.shields.io/badge/DOI-arXiv.2404.07654-B31B1B?logo=arxiv)](https://doi.org/10.48550/arXiv.2404.07654)
[![say-thanks](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://saythanks.io/to/JBGruber)
<!-- badges: end -->

The goal of `rollama` is to wrap the Ollama API, which allows you to run
different LLMs locally and create an experience similar to
ChatGPT/OpenAI’s API. Ollama is very easy to deploy and handles a huge
number of models. Checkout the project here:
<https://github.com/ollama/ollama>.

## Installation

You can install this package from CRAN:

``` r
install.packages("rollama")
```

Or you can install the development version of `rollama` from
[GitHub](https://github.com/JBGruber/rollama) with:

``` r
# install.packages("remotes")
remotes::install_github("JBGruber/rollama")
```

The easiest way to get Ollama itself up and running is through
[Docker](https://docs.docker.com/desktop/). From the command line
interface, you can start Ollama locally with one command (add `sudo` if
`permission denied`):

``` sh
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

After restarting, you can run Ollama again with the command (add `sudo`
if `permission denied`):

``` sh
docker start ollama
```

Alternatively, you can use the Docker Compose file from [this
gist](https://gist.github.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc):

``` sh
wget https://gist.githubusercontent.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc/raw/ddf7bd411a6595d0bd770f99de62f2ac8864f6dc/docker-compose.yml
docker-compose up -d
```

If you don’t know how to use Docker Compose, you can follow this video:

[![Install Docker on macOS, Windows and
Linux](https://img.youtube.com/vi/iMyCdd5nP5U/0.jpg)](https://www.youtube.com/watch?v=iMyCdd5nP5U)

## Example

The first thing you should do after installation is to pull one of the
models from <https://ollama.com/library>. By calling `pull_model()`
without arguments, you are pulling the (current) default model — “llama2
7b”:

``` r
library(rollama)
```

``` r
pull_model()
```

There are two ways to communicate with the Ollama API. You can make
single requests, which does not store any history and treats each query
as the beginning of a new chat:

``` r
# ask a single question
query("why is the sky blue?")
#> 
#> ── Answer from llama2 ──────────────────────────────────────────────────────────
#> 
#> The sky appears blue because of a phenomenon called Rayleigh scattering, which
#> occurs when light travels through the Earth's atmosphere. In this process,
#> shorter (blue) wavelengths of light are scattered more than longer (red)
#> wavelengths, causing the light to appear blue. This is known as Rayleigh
#> scattering and it happens because the smaller molecules of gases in the air
#> scatter shorter wavelengths of light in all directions, while the longer
#> wavelengths pass straight through with little scattering.
#> 
#> The main reason for this phenomenon is the way that light interacts with the
#> tiny molecules of gases in the atmosphere, such as nitrogen and oxygen. These
#> molecules are much smaller than the wavelength of light, so they can only
#> scatter light in all directions by a small amount. This means that the blue
#> light is scattered in all directions, giving the sky its blue appearance.
#> 
#> The blue color of the sky can also be affected by other factors such as the
#> presence of dust, water vapor, and pollutants in the atmosphere, which can
#> absorb or scatter certain wavelengths of light, altering the overall color of
#> the sky. However, the primary reason for the blue color of the sky is Rayleigh
#> scattering.
#> 
#> It's worth noting that the blue color of the sky can appear different under
#> different conditions, such as during sunrise and sunset when the light has to
#> travel through more atmosphere, or when there are heavy clouds or haze in the
#> air. In these cases, the blue color may be less pronounced or even absent.
```

Or you can use the `chat` function, treats all messages sent during an R
session as part of the same conversation:

``` r
# hold a conversation
chat("why is the sky blue?")
#> 
#> ── Answer from llama2 ──────────────────────────────────────────────────────────
#> 
#> The sky appears blue because of a phenomenon called Rayleigh scattering. When
#> sunlight enters Earth's atmosphere, it encounters tiny molecules of gases such
#> as nitrogen and oxygen. These molecules scatter the light in all directions,
#> but they scatter shorter (blue) wavelengths more than longer (red) wavelengths.
#> 
#> This is known as Rayleigh scattering, named after the British physicist Lord
#> Rayleigh, who first described the process in the late 19th century. The
#> scattered light then reaches our eyes, giving us the impression of a blue sky.
#> 
#> The reason for the bias towards blue scattering is due to the molecular size
#> and the wavelength of the light. The smaller the molecule, the more it scatters
#> shorter wavelengths of light. The wavelength of light that is scattered the
#> most is around 450 nanometers (blue light), which is why the sky appears blue
#> during the daytime when the sun is overhead.
#> 
#> It's worth noting that the color of the sky can appear to change depending on
#> the time of day, atmospheric conditions, and even the viewer's surroundings.
#> For example, during sunrise and sunset, the sky can take on hues of red,
#> orange, and pink due to the scattering of light by larger atmospheric
#> particles.
#> 
#> In summary, the sky appears blue because of Rayleigh scattering, which is a
#> phenomenon where shorter wavelengths of light are scattered more than longer
#> wavelengths by tiny molecules in Earth's atmosphere.
chat("and how do you know that?")
#> 
#> ── Answer from llama2 ──────────────────────────────────────────────────────────
#> 
#> I know that the sky appears blue due to Rayleigh scattering because it is a
#> well-established scientific fact that has been observed, measured, and
#> explained through various scientific studies and experiments. Here are some of
#> the key pieces of evidence and explanations:
#> 
#> 1. Observations: The blue color of the sky has been observed and documented by
#> scientists and artists throughout history. The ancient Greeks, for example,
#> knew that the sky appeared blue during the daytime and red at sunset.
#> 2. Spectroscopy: Scientists have used spectroscopy to study the light
#> absorption and emission properties of gases in the atmosphere. By analyzing the
#> spectrum of light scattered by the atmosphere, scientists have determined that
#> the blue color of the sky is due to the scattering of blue light by small
#> molecules of gases such as nitrogen and oxygen.
#> 3. Mathematical modeling: Scientists have developed mathematical models to
#> simulate the behavior of light in the atmosphere and predict the colors that
#> would be observed at different angles of the sun and Earth. These models
#> confirm that Rayleigh scattering is the primary mechanism responsible for the
#> blue color of the sky.
#> 4. Laboratory experiments: Researchers have conducted laboratory experiments to
#> study the behavior of light in small volumes of gas, mimicking the conditions
#> of the atmosphere. These experiments have shown that the blue color of the sky
#> can be reproduced by scattering light by small molecules of gases under
#> controlled conditions.
#> 5. Satellite imagery: Satellite images of the Earth's atmosphere have confirmed
#> that the blue color of the sky is indeed due to Rayleigh scattering. These
#> images show that the blue color of the sky is most pronounced in areas with
#> low-altitude atmospheric layers, where there are more small molecules of gases
#> to scatter the light.
#> 
#> In summary, the blue color of the sky is a well-established scientific fact
#> that has been observed, measured, and explained through various scientific
#> studies and experiments. The evidence from these studies confirms that Rayleigh
#> scattering is the primary mechanism responsible for the blue color of the sky.
```

If you are done with a conversation and want to start a new one, you can
do that like so:

``` r
new_chat()
```

## Model parameters

You can set a number of model parameters, either by creating a new
model, with a
[modelfile](https://jbgruber.github.io/rollama/reference/create_model.html),
or by including the parameters in the prompt:

``` r
query("why is the sky blue?", model_params = list(
  seed = 42,
  temperature = 0,
  num_gpu = 0
))
#> 
#> ── Answer from llama2 ──────────────────────────────────────────────────────────
#> 
#> The sky appears blue because of a phenomenon called Rayleigh scattering, which
#> occurs when sunlight enters Earth's atmosphere. The sunlight encounters tiny
#> molecules of gases such as nitrogen and oxygen, which scatter the light in all
#> directions.
#> 
#> The shorter wavelengths of light, such as blue and violet, are scattered more
#> than the longer wavelengths, such as red and orange. This is known as
#> Rayleigh's Law. As a result, the blue light is dispersed throughout the
#> atmosphere, giving the sky its blue appearance.
#> 
#> The reason why the sky appears blue under these conditions is due to the way
#> that our eyes perceive colors. When white light enters our eyes, it is filtered
#> through the lens and hits the retina, which contains cells called cone cells
#> that are sensitive to different wavelengths of light. The cells are most
#> sensitive to the blue and violet end of the spectrum, so when we look at a blue
#> sky, our brains interpret this as the dominant color.
#> 
#> It's worth noting that the appearance of the sky can vary depending on a number
#> of factors, including the time of day, the amount of dust and water vapor in
#> the air, and the angle of the sun. For example, during sunrise and sunset, the
#> sky can take on hues of red, orange, and pink due to the scattering of light by
#> atmospheric particles.
#> 
#> In summary, the sky appears blue because of the way that light is scattered in
#> the atmosphere, and how our eyes perceive colors.
```

#### Valid Parameters and Values

| Parameter      | Description                                                                                                                                                                                                                                             | Value Type | Example Usage        |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | -------------------- |
| mirostat       | Enable Mirostat sampling for controlling perplexity. (default: 0, 0 = disabled, 1 = Mirostat, 2 = Mirostat 2.0)                                                                                                                                         | int        | mirostat 0           |
| mirostat_eta   | Influences how quickly the algorithm responds to feedback from the generated text. A lower learning rate will result in slower adjustments, while a higher learning rate will make the algorithm more responsive. (Default: 0.1)                        | float      | mirostat_eta 0.1     |
| mirostat_tau   | Controls the balance between coherence and diversity of the output. A lower value will result in more focused and coherent text. (Default: 5.0)                                                                                                         | float      | mirostat_tau 5.0     |
| num_ctx        | Sets the size of the context window used to generate the next token. (Default: 2048)                                                                                                                                                                    | int        | num_ctx 4096         |
| num_gqa        | The number of GQA groups in the transformer layer. Required for some models, for example it is 8 for llama2:70b                                                                                                                                         | int        | num_gqa 1            |
| num_gpu        | The number of layers to send to the GPU(s). On macOS it defaults to 1 to enable metal support, 0 to disable.                                                                                                                                            | int        | num_gpu 50           |
| num_thread     | Sets the number of threads to use during computation. By default, Ollama will detect this for optimal performance. It is recommended to set this value to the number of physical CPU cores your system has (as opposed to the logical number of cores). | int        | num_thread 8         |
| repeat_last_n  | Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)                                                                                                                                           | int        | repeat_last_n 64     |
| repeat_penalty | Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient. (Default: 1.1)                                                                     | float      | repeat_penalty 1.1   |
| temperature    | The temperature of the model. Increasing the temperature will make the model answer more creatively. (Default: 0.8)                                                                                                                                     | float      | temperature 0.7      |
| seed           | Sets the random number seed to use for generation. Setting this to a specific number will make the model generate the same text for the same prompt. (Default: 0)                                                                                       | int        | seed 42              |
| stop           | Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate `stop` parameters in a modelfile.                                      | string     | stop "AI assistant:" |
| tfs_z          | Tail free sampling is used to reduce the impact of less probable tokens from the output. A higher value (e.g., 2.0) will reduce the impact more, while a value of 1.0 disables this setting. (default: 1)                                               | float      | tfs_z 1              |
| num_predict    | Maximum number of tokens to predict when generating text. (Default: 128, -1 = infinite generation, -2 = fill context)                                                                                                                                   | int        | num_predict 42       |
| top_k          | Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative. (Default: 40)                                                                        | int        | top_k 40             |
| top_p          | Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)                                                                 | float      | top_p 0.9            |

## Configuration

You can configure the server address, the system prompt and the model
used for a query or chat. If not configured otherwise, `rollama` assumes
you are using the default port (11434) of a local instance
(“localhost”). Let’s make this explicit by setting the option:

``` r
options(rollama_server = "http://localhost:11434")
```

You can change how a model answers by setting a configuration or system
message in plain English (or another language supported by the model):

``` r
options(rollama_config = "You make answers understandable to a 5 year old")
query("why is the sky blue?")
#> 
#> ── Answer from llama2 ──────────────────────────────────────────────────────────
#> Oh, wow! That's a great question! *giggles* You know what? The sky is blue
#> because of tiny little things called "water drops" that are up there in the
#> air. They reflect sunlight and make the sky look blue! Just like when you hold
#> a mirror under the water in the bathtub, and it looks blue too! *excitedly*
#> 
#> And do you know what's even more cool? The sky can change colors! Sometimes
#> it's red during sunset, or yellow during sunrise. It's like magic! *smiles* So,
#> that's why the sky is blue! Isn't that amazing? 😍
```

By default, the package uses the “llama2 7B” model. Supported models can
be found at <https://ollama.com/library>. To download a specific model
make use of the additional information available in “Tags”
<https://ollama.com/library/mistral/tags>. Change this via
`rollama_model`:

``` r
options(rollama_model = "mixtral")
# if you don't have the model yet: pull_model("mixtral")
query("why is the sky blue?")
#> 
#> ── Answer from mixtral ─────────────────────────────────────────────────────────
#> When the sun shines, it sends out little bits of light called "sunlight."
#> Sunlight is made up of different colors, like red, orange, yellow, green, blue,
#> and purple. You can see all these colors in a rainbow!
#> 
#> When sunlight reaches our sky, it meets tiny particles (like molecules of air)
#> that scatter, or spread, the light in different directions. Blue light is
#> scattered more than other colors because it travels in smaller, shorter waves.
#> This scattering makes the sky look blue to us.
#> 
#> At sunrise and sunset, the sunlight has to travel a longer path through the
#> atmosphere to reach our eyes. During this journey, even more of the blue light
#> gets scattered away, leaving mostly reds, oranges, and yellows for us to see.
#> That's why sunrises and sunsets often have beautiful colors!
```
