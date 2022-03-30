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

dir_measures <- "/Users/bbest/My Drive/projects/noaa-sanctsound/Database_WebPortal/Measure/measure_plots_from_Ben"
dir_figs     <- "/Users/bbest/My Drive/projects/noaa-sanctsound/Database_WebPortal/figures_detections/figures_detections_from_Ben"

d_measures <- measures %>% 
  filter(!is.na(dataportal_link)) %>% 
  mutate(
    file_img = glue("{dir_measures}/measures_{basename(dataportal_link)}.png"),
    base_img = basename(file_img)) %>% 
  # select(dataportal_link, base_img) %>% View()
  select(dataportal_link, file_img)
d_measures

d_figs <- figures %>% 
  filter(!is.na(dataportal_link)) %>% 
  mutate(
    file_img = glue("{dir_figs}/figures_{basename(dataportal_link)}.png"),
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
  Sys.sleep(200) # TODO: while loop if size output < 4KB, secs: 10,30,60,200
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

# crop ALL figure from Hourly-patterns.png
library(magick)
imgs_in <- list.files(dir_figs, "no-bin.radar-hourly\\.png$", full.names = T)
for (img_in in imgs_in){ # img_in = imgs_in[1]
  img_out <- fs::path_ext_set(img_in, "_ALL.png")
  img_out <- glue("{fs::path_ext_remove(img_in)}_ALL.png")
  image_read(img_in) %>%
    image_crop("280x211+0+69") %>% # crop {width}x{height}+{x}+{y}
    image_write(img_out)
}
