if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
shelf(
  chromote, here)
source(here::here("draft/functions.R"))

d_figures <- get_sheet("figures")
d_measure <- get_sheet("measure")

url <- "https://sanctsound.portal.axds.co/#sanctsound/chart/sanctsound.PM01.sound-levels.high-resolution-spectrogram.hour.spectrogram"
#browseURL(url)

b <- ChromoteSession$new(
  # parent = default_chromote_object(),
  # width  = 1366,
  # height = 768
  width  = 1280,
  height = 720
  # targetId = NULL,
  # wait_ = TRUE,
  # auto_events = NULL
  )

# b$view()
# b$Browser$getVersion()

b$Page$navigate(url)
#b$Page$loadEventFired()
Sys.sleep(30)

b$screenshot(
  filename = "screen_1280×720_chart-padding.png",
  selector = ".chartLayout",
  region   = "padding")

# Saves to screenshot.png
# img_1 <- "screen_1366x768.png"
# img_2 <- "screen_1366x768_crop.png"
img_1 <- "screen_1280×720.png"
img_2 <- "screen_1280×720_crop.png"

b$screenshot(img_1)

# 1280×720

library(magick)
# {width}x{height}+{x}+{y}
image_crop(image, "100x150+50") #: crop out width:100px and height:150px starting +50px from the left
image_read(img_1) %>% 
  image_crop("1319x469+26+233") %>% 
  image_write(img_2)



b$screenshot(
  filename = "screen_1366x768_scale-2.png",
  scale = 2)
b$screenshot(
  filename = "screen_1366x768_scale-0.5.png",
  scale = 0.5)

# https://rstudio.github.io/chromote/reference/ChromoteSession.html#method-screenshot-
b$screenshot(
  filename = "screen_1366x768_select-chart.png",
  selector = ".chartLayout.clearfix")
  # cliprect = NULL,
  # region   = c("content", "padding", "border", "margin"),
  # expand   = NULL,
  # scale    = 1,
  # show     = FALSE,
  # delay    = 3,
  # wait_    = TRUE)

# Takes a screenshot of elements picked out by CSS selector
b$screenshot("sidebar.png", selector = ".sidebar")

# webshot2 ----

library(webshot2)
# Specific height and width
webshot(
  url      = url, 
  # file     = "webshot_1600x900_select-chart.png",
  file     = "webshot_1600x900.png",
  vwidth   = 1600, 
  vheight  = 900, 
  #selector = "div.chartLayout.clearfix",
  delay    = 20)

# webshot ----

install.packages("webshot")
webshot::install_phantomjs()
library(webshot)

webshot(
  url      = url, 
  # file     = "webshot_1600x900_select-chart.png",
  file     = "webshot_1600x900.png",
  vwidth   = 1600, 
  vheight  = 900,
  delay    = 10) 
  #selector = "div.chartLayout.clearfix",
  # delay    = 20)

