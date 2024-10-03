
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rollama` <img src="man/figures/logo.png" align="right" height="138" alt="rollama-logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/JBGruber/rollama/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/JBGruber/rollama/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/JBGruber/rollama/branch/main/graph/badge.svg)](https://app.codecov.io/gh/JBGruber/rollama?branch=main)
[![CRAN
status](https://www.r-pkg.org/badges/version/rollama)](https://CRAN.R-project.org/package=rollama)
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

However, `rollama` is just the client package. The models are run in
`Ollama`, which you need to install on your system, on a remote system
or through [Docker](https://docs.docker.com/desktop/). The easiest way
is to simply download and install the Ollama application from [their
website](https://ollama.com/). Once `Ollama` is running, you can see if
you can access it with:

``` r
rollama::ping_ollama()
#> ▶ Ollama (v0.3.12) is running at <http://localhost:11434>!
```

### Installation of Ollama through Docker

The advantage of running things through Docker is that the application
is isolated from the rest of your system, behaves the same on different
systems, and is easy to download and update. You can also get a nice web
interface. After making sure [Docker](https://docs.docker.com/desktop/)
is installed, you can simply use the Docker Compose file from [this
gist](https://gist.github.com/JBGruber/73f9f49f833c6171b8607b976abc0ddc).

If you don’t know how to use Docker Compose, you can follow this video 
to use the compose file and start Ollama and Open WebUI:

[![Install Docker on macOS, Windows and
Linux](https://img.youtube.com/vi/iMyCdd5nP5U/0.jpg)](https://www.youtube.com/watch?v=iMyCdd5nP5U)

## Example

The first thing you should do after installation is to pull one of the
models from <https://ollama.com/library>. By calling `pull_model()`
without arguments, you are pulling the (current) default model —
“llama3.1 8b”:

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
#> ── Answer from llama3.1 ────────────────────────────────────────────────────────
#> The sky appears blue to us because of a phenomenon called Rayleigh scattering.
#> Here's a simplified explanation:
#> 
#> 1. **Sunlight enters Earth's atmosphere**: When sunlight enters our atmosphere,
#> it encounters tiny molecules of gases such as nitrogen (N2) and oxygen (O2).
#> 2. **Scattering occurs**: These gas molecules are much smaller than the
#> wavelength of light, so they scatter the shorter (blue) wavelengths more
#> efficiently than the longer (red) wavelengths.
#> 3. **Blue light is scattered in all directions**: As a result of this
#> scattering, blue light is distributed throughout the atmosphere and reaches our
#> eyes from all directions, giving the sky its blue appearance.
#> 4. **Red light continues to travel in a straight line**: The longer wavelengths
#> of red light, on the other hand, continue to travel in a straight line with
#> less scattering, which is why we see them as coming from the sun itself.
#> 
#> The combination of these factors results in our perception of a blue sky during
#> the daytime. However, it's worth noting that:
#> 
#> * **At sunrise and sunset**, the red light has a longer path through the
#> atmosphere, so more scattering occurs, making the sky appear more reddish.
#> * **On cloudy days** or during dust storms, the smaller particles in the air
#> scatter all wavelengths of light equally, resulting in a hazy or whitish
#> appearance.
#> 
#> Now you know why the sky is blue!
```

Or you can use the `chat` function, treats all messages sent during an R
session as part of the same conversation:

``` r
# hold a conversation
chat("why is the sky blue?")
#> 
#> ── Answer from llama3.1 ────────────────────────────────────────────────────────
#> The sky appears blue to us because of a phenomenon called scattering, which
#> occurs when sunlight enters Earth's atmosphere.
#> 
#> Here's what happens:
#> 
#> 1. **Sunlight**: The sun emits white light, which contains all the colors of
#> the visible spectrum (red, orange, yellow, green, blue, indigo, and violet).
#> 2. **Entry into atmosphere**: When this white light enters our atmosphere, it
#> encounters tiny molecules of gases such as nitrogen (N2) and oxygen (O2). These
#> molecules are much smaller than the wavelength of light.
#> 3. **Scattering occurs**: As sunlight interacts with these molecules, the
#> shorter (blue) wavelengths of light are scattered in all directions by the gas
#> molecules. This is known as Rayleigh scattering, named after the British
#> physicist Lord Rayleigh who first described it in the late 19th century.
#> 
#> The key point here is that blue light is scattered more than other colors
#> because its wavelength is so small compared to the size of the gas molecules.
#> This means that the blue light is distributed throughout the atmosphere and
#> reaches our eyes from all directions, making the sky appear blue!
#> 
#> **Why not violet?**: If scattering was the only factor, we'd expect the sky to
#> appear violet, as violet has an even shorter wavelength than blue. However,
#> there are two reasons why we don't see a violet sky:
#> 
#> a. **Color perception**: The human eye is less sensitive to violet light than
#> to blue light, so we perceive the scattered light as blue rather than violet.
#> 
#> b. **Atmospheric conditions**: The Earth's atmosphere absorbs and scatters
#> shorter wavelengths of light more efficiently than longer ones. This is why the
#> sun appears yellow or orange during sunrise and sunset, when the light has
#> traveled through a greater thickness of atmosphere.
#> 
#> So, to summarize: the sky appears blue because of the scattering of sunlight by
#> tiny gas molecules in our atmosphere, which favors shorter (blue) wavelengths
#> of light.
```

``` r
chat("and how do you know that?")
#> 
#> ── Answer from llama3.1 ────────────────────────────────────────────────────────
#> The explanation for why the sky is blue comes from a combination of scientific
#> experiments, observations, and theoretical understanding. Here are some key
#> sources and milestones:
#> 
#> 1. **Rayleigh's work**: Lord Rayleigh (1842-1919) was a British physicist who,
#> in 1871, first described the phenomenon of scattering by gases. He discovered
#> that the blue color of the sky could be explained by the interaction between
#> sunlight and the tiny molecules of air. Rayleigh's theory provided a foundation
#> for understanding why shorter wavelengths are scattered more than longer ones.
#> 2. **Tyndall's experiments**: In 1859, English physicist John Tyndall
#> (1820-1893) conducted an experiment to demonstrate that gases can scatter
#> light. He placed a container of water in a beam of sunlight and observed how
#> the light was scattered by the water molecules. This experiment helped
#> establish the concept of scattering.
#> 3. **Arago's observations**: French physicist François Arago (1786-1853)
#> noticed that the sky appears blue, even when viewed from a great distance,
#> suggesting that the color is not simply a property of the atmosphere itself but
#> rather an effect of the light being scattered by it.
#> 4. **Modern understanding**: In the 20th century, scientists further refined
#> our understanding of light scattering using various techniques such as
#> spectroscopy and quantum mechanics.
#> 
#> Some specific experiments and observations that confirm the explanation I
#> provided include:
#> 
#> * **Sunrise and sunset colors**: The color changes observed during sunrise and
#> sunset demonstrate how different wavelengths are scattered at varying angles.
#> * **Clouds and fog**: When sunlight passes through water droplets or ice
#> crystals, it scatters in a way that appears as white light. This shows that
#> shorter wavelengths (like blue) are being scattered more than longer ones.
#> * **Light scattering measurements**: Researchers have measured the intensity of
#> scattered light at different wavelengths using instruments such as
#> spectrometers and spectrophotometers.
#> 
#> These findings from various fields, including physics, chemistry, and
#> astronomy, collectively support the explanation for why the sky appears blue.
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
#> ── Answer from llama3.1 ────────────────────────────────────────────────────────
#> The sky appears blue to us because of a phenomenon called scattering, which
#> occurs when sunlight interacts with the tiny molecules of gases in the
#> atmosphere. Here's a simplified explanation:
#> 
#> 1. **Sunlight enters Earth's atmosphere**: When the sun shines, it emits a wide
#> range of electromagnetic radiation, including visible light, ultraviolet (UV)
#> radiation, and infrared (IR) radiation.
#> 2. **Light scatters off gas molecules**: As sunlight travels through the
#> atmosphere, it encounters tiny molecules of gases like nitrogen (N2) and oxygen
#> (O2). These molecules are much smaller than the wavelength of light, so they
#> scatter the light in all directions.
#> 3. **Short wavelengths scattered more**: The shorter wavelengths of light, such
#> as blue and violet, are scattered more than the longer wavelengths, like red
#> and orange. This is because the smaller gas molecules are more effective at
#> scattering the shorter wavelengths.
#> 4. **Blue light reaches our eyes**: As a result of this scattering process, the
#> blue light is distributed throughout the atmosphere and reaches our eyes from
#> all directions. This is why the sky appears blue to us.
#> 
#> Some additional factors can affect the color of the sky:
#> 
#> * **Time of day**: During sunrise and sunset, the sun's rays have to travel
#> through more of the Earth's atmosphere, which scatters the shorter wavelengths
#> even more. This is why the sky often appears redder during these times.
#> * **Atmospheric conditions**: Dust, pollution, and water vapor in the air can
#> also affect the color of the sky by scattering or absorbing light.
#> * **Altitude and location**: The color of the sky can vary depending on your
#> altitude and location. For example, at higher elevations or near large bodies
#> of water, the sky may appear more blue due to the reduced amount of atmospheric
#> gases.
#> 
#> In summary, the sky appears blue because of the scattering of sunlight by tiny
#> gas molecules in the atmosphere, which favors shorter wavelengths like blue
#> light.
```

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
#> ── Answer from llama3.1 ────────────────────────────────────────────────────────
#> So, you know how sometimes we see really bright things like blueberries or blue
#> crayons? Well, the sky looks kind of like that too!
#> 
#> The reason the sky is blue is because of something called sunlight. When
#> sunlight comes from the sun, it goes all around the world and hits our eyes.
#> 
#> But here's the cool thing about sunlight: it has lots of different colors in
#> it, like a big ol' rainbow! And guess what? Blue is one of those colors!
#> 
#> So, when sunlight hits the tiny particles in the air (like really, really small
#> bits of water or dust), they bounce back up to our eyes. And because blue is
#> such a strong color in the sunlight, that's the color we see most often.
#> 
#> That's why the sky looks blue! Isn't that awesome?
```

By default, the package uses the “llama3.1 8B” model. Supported models
can be found at <https://ollama.com/library>. To download a specific
model make use of the additional information available in “Tags”
<https://ollama.com/library/mistral/tags>. Change this via
`rollama_model`:

``` r
options(rollama_model = "mixtral")
# if you don't have the model yet: pull_model("mixtral")
query("why is the sky blue?")
#> 
#> ── Answer from mixtral ─────────────────────────────────────────────────────────
#> The sky appears blue because of something called "scattering." When the sun's
#> light reaches our atmosphere, it meets tiny particles and gases. These
#> particles scatter, or spread out, the sunlight in different directions. Blue
#> light has a shorter wavelength and gets scattered more easily than other
#> colors, such as red or yellow, which have longer wavelengths.
#> 
#> As a result, when we look up at the sky, we see mostly blue light that has been
#> scattered all around us. This is why the sky usually looks blue during the day!
```
