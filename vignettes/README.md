Build the vignette with:

```r
knitr::knit("vignettes/annotation.Rmd.orig", output = "vignettes/annotation.Rmd")
knitr::knit("vignettes/image-annotation.Rmd.orig", output = "vignettes/image-annotation.Rmd")
knitr::knit("vignettes/text-embedding.Rmd.orig", output = "vignettes/text-embedding.Rmd")
knitr::knit("vignettes/hf-gguf.Rmd.orig", output = "vignettes/hf-gguf.Rmd")
# move figures to vignettes folder
file.copy("figures", "vignettes/", overwrite = TRUE, recursive = TRUE)
unlink("figures", recursive = TRUE)
```

The RMDs then only contain the results.
