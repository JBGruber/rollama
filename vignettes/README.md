Build the vignette with:

```
knitr::knit("vignettes/annotation.Rmd.orig", output = "vignettes/annotation.Rmd")
knitr::knit("vignettes/image-annotation.Rmd.orig", output = "vignettes/image-annotation.Rmd")
```

This will use your `atrrr` token to run the commands.
The RMDs then only contain the results.
