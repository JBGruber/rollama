devtools::document()
spelling::spell_check_package()
devtools::check()

# re-compute vignettes
setwd(here::here("vignettes"))
knitr::knit("vignettes/annotation.Rmd.orig", output = "vignettes/annotation.Rmd")
knitr::knit("vignettes/image-annotation.Rmd.orig", output = "vignettes/image-annotation.Rmd")
knitr::knit("vignettes/text-embedding.Rmd.orig", output = "vignettes/text-embedding.Rmd")

# render site to have a look
setwd(here::here())
pkgdown::build_site()

# submit to CRAN
usethis::use_version("minor")
rhub::check_for_cran()
devtools::submit_cran()

# once accepted by CRAN
usethis::use_github_release()
