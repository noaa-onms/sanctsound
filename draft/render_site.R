if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
shelf(here)
source(here::here("draft/functions.R"))

redo_modals     <- T
skip_drive_auth <- F

# authenticate to GoogleDrive using Google Service Account's secret JSON
#   after Sharing with its email: shares@nms4gargle.iam.gserviceaccount.com
if (Sys.getenv("GITHUB_ACTIONS") == ""){
  message("GITHUB_ACTIONS environmental variable is empty")
  google_sa_json <- "/Users/bbest/My Drive (ben@ecoquants.com)/projects/nms-web/data/nms4gargle-774a9e9ec703.json"
  stopifnot(file.exists(google_sa_json))
  gsa_json_text <- readLines(google_sa_json) %>% paste(sep="\n")
} else {
  gsa_json_text <- Sys.getenv("GOOGLE_SA")
  message('nchar(Sys.getenv("GOOGLE_SA")): ', nchar(Sys.getenv("GOOGLE_SA")))
}
if (!skip_drive_auth){
  message("non-interactively authenticating to GoogleDrive with Google Service Account")
  drive_auth(path = gsa_json_text)
}

# nav menus in _site.yml ----
update_sounds_menu()
update_stories_menu()

# sanctuaries ----
sites <- read_csv(here("draft/data/nms_sites.csv"), col_types = cols()) %>%
  arrange(code)
sites %>%
  #filter(code %in% c("cinms","fknms","hihwnms")) %>% 
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
    # filter(modal_id == "pmnm_minke-whales") %>% # pmnm_humpback-whales pmnm_minke-whales
    filter(!modal_id %in% c("cinms_blue-whales", "cinms_vessels")) %>% # pmnm_humpback-whales pmnm_minke-whales
    # View()
    # TODO: ∆ _modal_template to have chart-/question-captions like Blue whales; multiple Tabs like Vessels
    pwalk(render_modal)
}
  
# tiles ----
tiles <- get_sheet("tiles", redo = F) %>% 
  mutate(
    path_relative = map_chr(gdrive_shareable_link, gdrive2path))
# for now manually added into _cards.html for index.Rmd 

# *.Rmd's ----
rmarkdown::render_site("./draft")

# servr::httd(here::here("draft"))
# servr::daemon_stop(1)

