
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `rollama`

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![say-thanks](https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg)](https://saythanks.io/to/JBGruber)
<!-- badges: end -->

The goal of `rollama` is to wrap the Ollama API, which allows you to run
different LLMs locally and create an experience similar to
ChatGPT/OpenAI’s API. Ollama is very easy to deploy and handles a huge
number of models. Checkout the project here:
<https://github.com/jmorganca/ollama>.

## Installation

You can install the development version of `rollama` from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("JBGruber/`rollama`")
```

## Example

``` r
library(rollama)
```

There are two ways to communicate with the Ollama API. You can make
single requests, which does not store any history and treats each query
as the beginning of a new chat:

``` r
# ask a single question
query("why is the sky blue?")
#> 
#> ── Answer ──────────────────────────────────────────────────────────────────────
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
#> ── Answer ──────────────────────────────────────────────────────────────────────
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
#> ── Answer ──────────────────────────────────────────────────────────────────────
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

## Configuration

You can configure the server address, the system prompt and the model
used for a query or chat. If not configured otherwise, `rollama` assumes
you are using the default port (11434) of a local instance
(<http://localhost>). Let’s make this explicit by setting the option:

``` r
options(rollama_server = "http://localhost:11434")
```

You can change how a model answers by setting a configuration or system
message in plain English (or another language supported by the model):

``` r
options(rollama_config = "You make answers understandable to a 5 year old")
query("why is the sky blue?")
#> 
#> ── Answer ──────────────────────────────────────────────────────────────────────
#> Oh, wow! That's a great question! *excited* The sky is blue because of a thing
#> called light. You know what light is? It's like when you shine a flashlight in
#> the dark and it makes everything bright and happy! *giggles* Well, the sun is
#> like a big ol' flashlight in the sky, and it shines its light on the Earth. And
#> that's why the sky is blue! *hugs* Do you like the blue sky? I do! It's so
#> pretty and makes me feel happy inside! *smiles*
```

By default, the package uses the “llama2” model. Change this via
`rollama_model`:

``` r
options(rollama_model = "mistral")
query("why is the sky blue?")
#> 
#> ── Answer ──────────────────────────────────────────────────────────────────────
#> The sky is blue because of something called "sky paint." Well, not really
#> paint, but tiny bits of things called "blue particles" that are in the air. The
#> sun makes these particles shine and when they shine, they make the sky look
#> blue to us! Isn't that cool? Just like how we use different colors of crayons
#> or paint to create pictures, the sky is painted blue by these special blue
#> particles!
```
