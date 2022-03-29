# I placed images given by the dataportal_link in folders with a naming scheme using uniquely identifiable tabs and fields from sanctsound website content:
# - figures
#   file naming scheme: house_figures_{modal_id}_{tab_name}.png
#   output folder: figures_detections_from_Ben
# - measures
#   file naming scheme: house_measures_{sanctuary_code}_{file_type}.png
#   output folder: measure_plots_from_Ben

if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
shelf(
  chromote, here)
source(here::here("draft/functions.R"))
# from functions.R:
# modals  <- get_sheet("modals")
# figures <- get_sheet("figures")
measures  <- get_sheet("measures")

dir_measures = "/Users/bbest/My Drive/projects/noaa-sanctsound/Database_WebPortal/Measure/measure_plots_from_Ben"
dir_figs = "/Users/bbest/My Drive/projects/noaa-sanctsound/Database_WebPortal/figures_detections/figures_detections_from_Ben"

d_measures <- measure %>% 
  filter(!is.na(dataportal_link)) %>% 
  mutate(
    file_img = glue("{dir_measures}/house_measures_{sanctuary_code}_{file_type}.png"),
    base_img = basename(file_img)) %>% 
  # select(sanctuary_code, file_type, base_img) %>% View()
  select(dataportal_link, file_img)
d_measures

d_figs <- figures %>% 
  filter(!is.na(dataportal_link)) %>% 
  mutate(
    file_img = glue("{dir_figs}/house_figures_{modal_id}_{str_replace(tab_name, ' ', '-')}.png"),
    base_img = basename(file_img)) %>% 
  # select(modal_id, tab_name, base_img) %>% View()
  select(dataportal_link, file_img)
d_figs

screensave <- function(dataportal_link, file_img, ...){
  # i = 2
  # dataportal_link <- d_figs$dataportal_link[i]
  # file_img        <- d_figs$file_img[i]
  
  message(glue("{basename(dataportal_link)}\n  -> {basename(file_img)}"))
  
  if (file.exists(file_img)){
    message(glue("  file exists: {basename(file_img)}", .trim = F))
    return()
  }
  
  # get page with browser session
  b <- ChromoteSession$new()
  b$default_timeout = 100 # in seconds
  b$Page$navigate(dataportal_link, wait_ = FALSE)
  p <- b$Page$loadEventFired(wait_ = FALSE)
  str(b$wait_for(p))
  Sys.sleep(60)
  root_node <- b$DOM$getDocument()$root$nodeId
  
  # get selector
  sel_res <- list(nodeIds = list()); selector = NULL
  i = 1
  selectors <- c(".chartLayout", ".chart")
  while (length(sel_res$nodeIds) == 0){
    
    if (i > length(selectors))
      stop(glue("Doh! Ran out of selectors to be found at:\n  {dataportal_link}"))
    
    selector <- selectors[i]
    
    sel_res <- b$DOM$querySelectorAll(root_node, selector = selector)
    message(glue("  selector {selector}: {c('NOT found','FOUND')[(length(sel_res$nodeIds) > 0) + 1]}", .trim=F))
    
    i = i + 1
  }
  
  # get screenshot
  scr_res <- b$screenshot(
    filename = file_img,
    selector = selector,
    region   = "padding")
  
  # close browser session
  b$close()
}

d_figs %>% 
  pwalk(screensave)

d_measures %>% 
  pwalk(screensave)

# library(magick)
# # {width}x{height}+{x}+{y}
# image_crop(image, "100x150+50") #: crop out width:100px and height:150px starting +50px from the left
# image_read(img_1) %>% 
#   image_crop("1319x469+26+233") %>% 
#   image_write(img_2)
