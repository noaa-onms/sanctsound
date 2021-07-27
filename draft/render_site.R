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

# DEBUG
# # nav menus in _site.yml ----
# update_sounds_menu()
# update_stories_menu()
# 
# # sanctuaries ----
# sites <- read_csv(here("draft/data/nms_sites.csv"), col_types = cols()) %>% 
#   arrange(code)
# 
# sites %>% 
#   # filter(code %in% c("cinms","hihwnms")) %>% # "cinms","fknms","hihwnms"
#   pwalk(render_sanctuary)

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
    filter(
      sanctuary_code == "CINMS",
      modal_title    == "Humpback whales") %>%
    # "Time series"
    # inner_join(
    #   get_sheet("modals") %>%
    #     filter(
    #       tab_name == "Time series",
    #       !is.na(gdrive_shareable_link)) %>%
    #     select(sanctuary_code, modal_title),
    #   by = c("sanctuary_code", "modal_title")) %>%
    # "Daily patterns"
    # inner_join(
    #   get_sheet("modals") %>%
    #     filter(
    #       tab_name == "Daily patterns",
    #       !is.na(gdrive_shareable_link)) %>%
    #     select(sanctuary_code, modal_title),
    #   by = c("sanctuary_code", "modal_title")) %>%
    # CINMS: Container Ships/Smaller Vessels: Monthly pattern -> Monthly patterns
    # inner_join(
    #   get_sheet("modals") %>%
    #     filter(
    #       tab_name == "Monthly patterns",
    #       !is.na(gdrive_shareable_link)) %>%
    #     select(sanctuary_code, modal_title),
    #   by = c("sanctuary_code", "modal_title")) %>%
    pwalk(render_modal)
}
  

# *.Rmd's ----
rmarkdown::render_site("./draft")
