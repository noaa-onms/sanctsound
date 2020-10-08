source(here::here("functions.R"))

redo_modals <- F

modals    <- get_sheet("modals", redo = T)

modal_pages <- modals %>% 
  group_by(sanctuary_code, modal_title) %>% 
  summarize() %>% 
  mutate(
    modal_html  = map2_chr(sanctuary_code, modal_title, modal_title_to_html_path)) %>% 
  select(sanctuary_code, modal_title, modal_html) # modal_pages 

# modals %>% 
#   #filter(modal_title == "Seal bombs") %>% 
#   filter(modal_title == "Giant sea bass") %>% 
#   View()
# modal_pages <- filter(modal_pages, modal_title == "Seal bombs")
pwalk(modal_pages, render_modal)

# create/render modals by iterating over svg links in csv ----
# for (i in 1:nrow(d_modals)){ # i=5
#   # paths
#   htm <- d_modals$link[i]
#   rmd <- path_ext_set(htm, "Rmd")
#   
#   #if (htm == "modals/ca-sheephead.html") browser()
#   
#   # create Rmd, if doesn't exist
#   if (!file.exists(rmd)) file.create(rmd)
#   
#   # render Rmd to html, if Rmd newer or redoing
#   if (file.exists(htm)){
#     rmd_newer <- file_info(rmd)$modification_time > file_info(htm)$modification_time
#   } else {
#     rmd_newer <- T
#   }
#   if (rmd_newer | redo_modals){
#     render_modal(rmd)
#   }
# }

# render website, ie Rmds in root ----
# walk(list.files(".", "*\\.md$"), render_page)
# walk(
#   list.files(".", "*\\.html$"), 
#   function(x) file.copy(x, file.path("docs", x)))
rmarkdown::render_site()

# fs::file_touch("docs/.nojekyll")

# shortcuts w/out full render:
# file.copy("libs", "docs", recursive=T)
# file.copy("svg", "docs", recursive=T)
# file.copy("modals", "docs", recursive=T)


