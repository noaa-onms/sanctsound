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
  chromote, fs, glue, here)
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

screensave <- function(dataportal_link, file_img, sleep_seconds = 10, overwrite = T, ...){
  # i = 9
  # dataportal_link <- d_figs$dataportal_link[i]
  # file_img        <- d_figs$file_img[i]
  
  if (file.exists(file_img) & !overwrite)
    return(T)
  message(glue("{basename(file_img)}"))
  
  # get page with browser session
  b <- ChromoteSession$new()
  b$default_timeout = sleep_seconds*1000 # in milliseconds?
  message(glue("  Loading page", .trim = F))
  b$Page$navigate(dataportal_link, wait_ = TRUE)
  # p <- b$Page$loadEventFired(wait_ = FALSE)
  # str(b$wait_for(p))
  message(glue("  Sleeping for {sleep_seconds} seconds", .trim = F))
  Sys.sleep(sleep_seconds) # TODO: while loop if size output < 4KB, secs: 
  root_node <- try(b$DOM$getDocument()$root$nodeId) # TODO: errors out here if page not loaded
  if (!"integer" %in% class(root_node)){
    message("  root_node error")
    b$close()
    return(FALSE)
  } else {
    message("  page_loaded")
  }
    
  # get selector
  sel_res <- list(nodeIds = list()); 
  selector = NULL
  i = 1
  selectors <- c(".chartLayout", ".chart")
  while (length(sel_res$nodeIds) == 0){
    if (i > length(selectors)){
      #stop(glue("Doh! Ran out of selectors to be found at:\n  {dataportal_link}"))
      message(glue("  Doh! Ran out of selectors to be found",trim = F))
      b$close()
      return(FALSE)
    } else {
      selector <- selectors[i]
      sel_res <- b$DOM$querySelectorAll(root_node, selector = selector)
      message(glue("  selector {selector}: {c('NOT found','FOUND')[(length(sel_res$nodeIds) > 0) + 1]}", .trim=F))
      i = i + 1
    }
  }
  
  # get screenshot
  message(glue("  screenshot",trim = F))
  scr_res <- b$screenshot(
    filename = file_img,
    selector = selector,
    region   = "padding")
  
  if (!file.exists(file_img)){
    message("  !file.exists(file_img)")
    b$close()
    return(FALSE)
  }
  
  # close browser session
  b$close()
  message("  check file_img size")
  sz <- fs::file_info(file_img) %>% pull(size)
  if (sz < fs_bytes("5KB")){
    message("  file_img size < 5KB")
    file_delete(file_img)
    return(FALSE) 
  }
  
  message("  NEW all good :)")
  return(TRUE)
}

secs_sleep_v <- c(10,30,60,200,400)

d_screens <- bind_rows(
  d_figs,
  d_measures) %>% 
  mutate(
    is_done = FALSE)

# d_screens %>% 
#   filter(str_detect(dataportal_link, "HI06")) %>% 
#   select(dataportal_link, file_img) # %>% write_csv("tmp.csv")

# idx <- which(
#   basename(d_figs$file_img) == "figures_sanctsound.CI01.detections.dolphin-detections.136980.hour.histogram.png")

i_secs <- 1
while(
  sum(d_screens$is_done) != nrow(d_screens) &
  i_secs <= length(secs_sleep_v)){
  
  secs_sleep <- secs_sleep_v[i_secs]
  
  d_screens_todo <- d_screens %>% 
    filter(!is_done) %>% 
    mutate(
      is_done_todo = map2_lgl(
        dataportal_link, file_img, function(x, y){
          screensave(x, y, sleep_seconds = secs_sleep, overwrite = F) }))
  
  d_screens <- d_screens %>% 
    left_join(
      d_screens_todo %>% 
        select(file_img, is_done_todo), 
      by = "file_img") %>% 
    mutate(
      is_done = ifelse(is_done_todo, TRUE, is_done))
  
  i_secs <- i_secs + 1
}

stopifnot(d_screens %>% filter(!is_done) %>% sum() == 0)

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
