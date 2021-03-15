source(here::here("draft/functions.R"))

redo_modals <- F

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
  filter(code %in% c("cinms", "hihwnms")) %>% 
  pwalk(render_sanctuary)

# rmarkdown render
# File  not found in resource path
# Error: pandoc document conversion failed with error 99
# Called from: pandoc_convert

# /Applications/RStudio.app/Contents/MacOS/pandoc/pandoc +RTS -K512m -RTS _sanctuary_template.utf8.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output s_fknms.html --email-obfuscation none --self-contained --standalone --section-divs --template /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --css libs/styles.css --include-before-body /var/folders/2r/grqvdjfn04361tzk8mh60st40000gn/T//RtmpNpYAlp/rmarkdown-str1a8356c7bd87.html --variable navbar=1 --variable body_padding=45 --variable header_padding=50 --variable 'theme:yeti' --include-in-header /var/folders/2r/grqvdjfn04361tzk8mh60st40000gn/T//RtmpNpYAlp/rmarkdown-str1a83536c1693.html --mathjax --variable 'mathjax-url:https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'
# --lua-filter /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rmarkdown/rmd/lua/pagebreak.lua --lua-filter /Library/Frameworks/R.framework/Versions/4.0/Resources/library/rmarkdown/rmd/lua/latex-div.lua

# TODO: make update_sites_menu() so menu could be dynamic 
    
# modals ----

modals    <- get_sheet("modals", redo = redo_modals)
modal_pages <- modals %>% 
  group_by(sanctuary_code, modal_title) %>% 
  summarize() %>% 
  mutate(
    modal_html  = map2_chr(sanctuary_code, modal_title, modal_title_to_html_path)) %>% 
  select(sanctuary_code, modal_title, modal_html) # modal_pages 

if (redo_modals)
  pwalk(modal_pages, render_modal)

# *.Rmd's ----
setwd(here("draft"))
rmarkdown::render_site()



