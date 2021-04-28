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

render_sanctuary <- function(code, name, type, ...){
  in_rmd  <- here("draft/_sanctuary_template.Rmd")
  out_htm <- here(glue("draft/s_{code}.html"))
  message(glue("RENDER SANCTUARY: {basename(in_rmd)} -> {basename(out_htm)}"))
  
  #browser()
  
  render(
    input       = in_rmd, 
    output_file = out_htm,
    clean       = F,
    params      = list(
      main      = glue("{name} {type}"),
      site_code = code,
      # scenes tab in [sanctsound_website-content - Google Sheets](https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/edit#gid=0)                    
      csv       = "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv&sheet=modals",
      svg       = glue("svg/{code}.svg")))}

#sites <- sites %>% filter(code == "fknms")
#sites <- sites %>% 
sites %>% 
  # filter(code %in% c("hihwnms", "fknms")) %>% # "cinms","fknms","hihwnms"
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
    inner_join(
      get_sheet("modals") %>% 
        filter(tab_name == "Time series") %>% 
        select(sanctuary_code, modal_title),
      by = c("sanctuary_code", "modal_title")) %>% 
    pwalk(render_modal)
}
  

# *.Rmd's ----
rmarkdown::render_site("./draft")
