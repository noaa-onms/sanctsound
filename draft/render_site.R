if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
shelf(here)

source(here::here("draft/functions.R"))
skip_drive_auth <- F
redo_modals     <- T

# nav menus in _site.yml ----
update_sounds_menu()
update_stories_menu()

# sanctuaries ----
create_svg_csv()
sites <- read_csv(here("draft/data/nms_sites.csv"), col_types = cols()) %>%
  arrange(code)
sites %>%
  #filter(code %in% c("cinms","fknms","hihwnms")) %>% 
  # filter(code %in% c("cinms")) %>% 
  pwalk(render_sanctuary)

# modals ----
modals <- get_sheet("modals", redo = redo_modals)
modal_pages <- modals %>% 
  select(sanctuary_code, modal_title, modal_id) %>% 
  mutate(
    modal_html  = map_chr(modal_id, path_ext_set, "html")) %>% 
  arrange(modal_html)

if (redo_modals){
  modal_pages %>%
    # filter(modal_id == "cinms_fin-whales") %>% # pmnm_humpback-whales pmnm_minke-whales
    # filter(modal_id == "cinms_blue-whales") %>% # pmnm_humpback-whales pmnm_minke-whales
    # filter(modal_id == "pmnm_minke-whales") %>% # pmnm_humpback-whales pmnm_minke-whales
    # filter(modal_id %in% c(
    #   "ocnms_echosounders", 
    #   "hihwnms_vessels", 
    #   "ocnms_gray-whales", 
    #   "hihwnms_fish-chorus", 
    #   "cinms_wind-and-waves", 
    #   "ocnms_blue-whales")) %>% # pmnm_humpback-whales pmnm_minke-whales
    # View()
    # TODO: ∆ _modal_template to have chart-/question-captions like Blue whales; multiple Tabs like Vessels
    pwalk(render_modal)
}
  
# tiles ----
# tiles <- get_sheet("tiles", redo = F) %>% 
#   mutate(
#     path_relative = map_chr(gdrive_shareable_link, gdrive2path))
# for now manually added into _cards.html for index.Rmd 

# *.Rmd's ----
rmarkdown::render_site(here::here("draft"))
#rmarkdown::render("draft/sounds.Rmd")

# servr::httd(here::here("draft"))
# servr::daemon_stop(1)

