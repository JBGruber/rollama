devtools::document()
spelling::spell_check_package()
devtools::check()

# re-compute vignettes
setwd(here::here("vignettes"))
knitr::knit(
  "annotation.Rmd.orig",
  output = "annotation.Rmd"
)
knitr::knit(
  "image-annotation.Rmd.orig",
  output = "image-annotation.Rmd"
)
knitr::knit(
  "text-embedding.Rmd.orig",
  output = "text-embedding.Rmd"
)
knitr::knit(
  "structured_outputs.Rmd.orig",
  output = "structured_outputs.Rmd"
)

# render site to have a look
setwd(here::here())
pkgdown::build_site()

# submit to CRAN
usethis::use_version("minor")
rhub::check_for_cran()
devtools::submit_cran()

# once accepted by CRAN
usethis::use_github_release()
