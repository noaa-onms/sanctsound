source(here::here("draft/functions.R"))

redo_modals <- T

# nav menus in _site.yml ----

update_sounds_menu()
update_stories_menu()
# Error: arrange() failed at implicit mutate() step. 
# x Could not create a temporary column for `..3`.
# ℹ `..3` is `sanctuary_code`.

# sanctuaries ----
sites <- read_csv(here("draft/data/nms_sites.csv"), col_types = cols()) %>% 
  arrange(code)

#sites <- sites %>% filter(code == "fknms")
#sites <- sites %>% 
sites %>% 
  filter(code %in% c("cinms","hihwnms")) %>% # "cinms","fknms","hihwnms"
  pwalk(render_sanctuary)

# TODO: make update_sites_menu() so menu could be dynamic 
    
# modals ----
modals    <- get_sheet("modals", redo = redo_modals)
modal_pages <- modals %>% 
  group_by(sanctuary_code, modal_title) %>% 
  summarize() %>% 
  mutate(
    modal_html  = map2_chr(sanctuary_code, modal_title, modal_title_to_html_path)) %>% 
  select(sanctuary_code, modal_title, modal_html) # modal_pages 

if (redo_modals){
  modal_pages %>%
    # "Daily patterns" -> "Time series"
    # inner_join(
    #   get_sheet("modals") %>% 
    #     filter(tab_name == "Time series") %>% 
    #     select(sanctuary_code, modal_title),
    #   by = c("sanctuary_code", "modal_title")) %>% 
    pwalk(render_modal)
}
  

# *.Rmd's ----
rmarkdown::render_site("./draft")
