library(rmarkdown)
library(here)
library(readr)
library(fs)
library(glue)
library(purrr)
library(dplyr)
here = here::here
source(here("functions.R"))

# parameters
csv         <- "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv&sheet=scenes"
redo_modals <- F

# download any missing images & sounds
get_gsheet_modals(modals_csv)

# read in links for svg
d <- read_csv(csv) %>% 
  mutate(dir = dirname(link)) %>% 
  select(-starts_with("X"))

d_modals <- d %>% 
  filter(dir != ".")

render_page <- function(rmd){
  render(rmd, html_document(
    theme = site_config()$output$html_document$theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    mathjax = NULL))
}

render_modal <- function(rmd){
  rmds_theme_white <- c(
    "modals/barnacles.Rmd",
    "modals/mussels.Rmd")
  
  site_theme <- site_config()$output$html_document$theme
  rmd_theme  <- ifelse(rmd %in% rmds_theme_white, "cosmo", site_theme)
  
  render(rmd, html_document(
    theme = rmd_theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    # toc=T, toc_depth=3, toc_float=T,
    mathjax = NULL))
  
  htm <- fs::path_ext_set(rmd, "html")
  docs_htm <- glue("docs/{htm}")
  docs_rmd <- glue("docs/{rmd}")
  file.copy(rmd, docs_rmd, overwrite = T)
  file.copy(htm, docs_htm, overwrite = T)
}

# render_modal("modals/key-human-activities.Rmd")
# render_modal("modals/rocky-map.Rmd")
# render_modal("modals/barnacles.Rmd")
# render_modal("modals/mussels.Rmd")
# render_modal("modals/halibut.Rmd")
# render_modal("modals/key-climate-ocean.Rmd")

# create/render modals by iterating over svg links in csv ----
for (i in 1:nrow(d_modals)){ # i=5
  # paths
  htm <- d_modals$link[i]
  rmd <- path_ext_set(htm, "Rmd")
  
  #if (htm == "modals/ca-sheephead.html") browser()
  
  # create Rmd, if doesn't exist
  if (!file.exists(rmd)) file.create(rmd)
  
  # render Rmd to html, if Rmd newer or redoing
  if (file.exists(htm)){
    rmd_newer <- file_info(rmd)$modification_time > file_info(htm)$modification_time
  } else {
    rmd_newer <- T
  }
  if (rmd_newer | redo_modals){
    render_modal(rmd)
  }
}

# render website, ie Rmds in root ----
walk(list.files(".", "*\\.md$"), render_page)
walk(
  list.files(".", "*\\.html$"), 
  function(x) file.copy(x, file.path("docs", x)))
rmarkdown::render_site()

fs::file_touch("docs/.nojekyll")

# shortcuts w/out full render:
# file.copy("libs", "docs", recursive=T)
# file.copy("svg", "docs", recursive=T)
# file.copy("modals", "docs", recursive=T)

