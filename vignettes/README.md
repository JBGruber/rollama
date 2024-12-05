Build the vignette with:

```
knitr::knit("vignettes/annotation.Rmd.orig", output = "vignettes/annotation.Rmd")
knitr::knit("vignettes/image-annotation.Rmd.orig", output = "vignettes/image-annotation.Rmd")
knitr::knit("vignettes/text-embedding.Rmd.orig", output = "vignettes/text-embedding.Rmd")
knitr::knit("vignettes/hf-gguf.Rmd.orig", output = "vignettes/hf-gguf.Rmd")
```

The RMDs then only contain the results.
