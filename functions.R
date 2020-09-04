if (!require(librarian)){
  remotes::install_github("DesiQuintans/librarian")
  library(librarian)
}
shelf(
  # multimedia
  av,
  # spatial
  leaflet, sf, sp,
  # tidyverse
  dplyr, googledrive, purrr, readr, tibble, tidyr,
  # report
  DT, knitr, rmarkdown,
  # utility
  fs, glue, here, stringr)
here <- here::here

gsheet_pfx    <- "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv"
modals_csv    <- glue("{gsheet_pfx}&sheet=modals")
scenes_csv    <- glue("{gsheet_pfx}&sheet=scenes")
locations_csv <- glue("{gsheet_pfx}&sheet=locations")
metadata_csv  <- glue("{gsheet_pfx}&sheet=metadata")

sites_csv <- here("data/nms_sites.csv")
sites_geo <- here("data/nms_sites.geojson")

get_sheet <- function(sheet, redo = F){
  # sheet = "modals"
  if (!exists(sheet, envir = globalenv()) | redo){
    sheet_csv <- get(glue("{sheet}_csv"))
    d <- read_csv(sheet_csv) %>% 
      select(-starts_with("X"))
    assign(sheet, d, envir = globalenv())}
  get(sheet)
}

modals    <- get_sheet("modals")
scenes    <- get_sheet("scenes")
locations <- get_sheet("locations")
metadata  <- get_sheet("metadata")

get_nms_ply <- function(nms, dir_pfx = here()){
  # get polygon for National Marine Sanctuary
  
  nms_shp <- glue("{dir_pfx}/data/shp/{nms}_py.shp")
  
  if (!file.exists(nms_shp)){
    # download if needed
    
    # https://sanctuaries.noaa.gov/library/imast_gis.html
    nms_url <- glue::glue("https://sanctuaries.noaa.gov/library/imast/{nms}_py2.zip")
    nms_zip <- here::here(glue::glue("data/{nms}.zip"))
    shp_dir <- here::here("data/shp")
    
    download.file(nms_url, nms_zip)
    unzip(nms_zip, exdir = shp_dir)
    fs::file_delete(nms_zip)
  }
  # read and convert to standard geographic projection
  sf::read_sf(nms_shp) %>%
    sf::st_transform(4326)
}

if (!file.exists(sites_csv)){
  sites <- tibble::tribble(
    ~code    , ~name,
    "cinms"  , "Channel Islands",
    "fknms"  , "Florida Keys",
    "grnms"  , "Gray’s Reef",
    "hihwnms", "Hawaiian Islands Humpback Whale",
    "mbnms"  , "Monterey Bay",
    "ocnms"  , "Olympic Coast",
    "pmnm"   , "Papahānaumokuākea",
    "sbnms"  , "Stellwagen Bank") %>% 
    dplyr::mutate(
      sf       = purrr::map(code, get_nms_ply),
      geometry = purrr::map(sf, function(x) sf::st_cast(sf::st_combine(x), "MULTIPOLYGON") %>% .[[1]])) %>% 
    dplyr::select(-sf) %>% 
    sf::st_sf(crs = 4326) %>% 
    sf::as("Spatial") %>% 
    sp::spTransform("+proj=longlat +datum=WGS84 +lon_wrap=180") %>% 
    sf::st_as_sf()
  
  readr::write_sf(sites, sites_geo, delete_dsn = T)
  
  sites %>% 
    sf::st_drop_geometry() %>% 
    readr::write_csv(sites_csv)
  
}

create_sanctuary_pages <- function(){
  sites <- readr::read_csv(sites_csv)
  
  site_rmd <- function(code, name){
    rmd <- glue::glue("s_{code}.Rmd")
    
    lns <- glue::glue('
      ---
      title: "{{name}}"
      params:
        site_code: "{{code}}"
      ---
      ```{r setup, include=FALSE}
      knitr::opts_chunk$set(echo = F)
      ```
      ```{r}
      source(here::here("functions.R"))
      map_site(params$site_code)
      ```
      ', .open = "{{", .close = "}}")
    
    writeLines(lns,rmd)
  }
  purrr::walk2(sites$code, sites$name, site_rmd)
}

get_modal_tbl <- function(modal_title = NULL, rmd = NULL){
  # rmd = "cinms_dolphins.Rmd"; modal_title = NULL

  stopifnot(sum(!is.null(modal_title), !is.null(rmd)) == 1)
  
  modals    <- get_sheet("modals")
  scenes    <- get_sheet("scenes")
  
  if (!is.null(modal_title)){
    modal_tbl <- modals %>% 
      filter(modal_title == !!modal_title)
  }
  
  if (!is.null(rmd)){
    fname <- path_ext_remove(rmd)
    
    modal_title <- scenes %>% 
      filter(file_name == fname) %>% 
      pull(modal_title)
    
    modal_tbl <- modals %>% 
      filter(modal_title == !!modal_title)
  }
  modal_tbl
}

get_modal_tab_content <- function(tab_name, modal_title = NULL, rmd = NULL){
  
  # tab_name <- "Sight"; rmd = "cinms_dolphins.Rmd"; modal_title = NULL; 
  modal_tbl <- get_modal_tbl(modal_title = modal_title, rmd = rmd)
  
  # Sight
  # modal_tbl %>% 
  #   filter(tab_name == !!tab_name)
  
  imgs <- modals %>% 
    filter(tolower(path_ext(filename)) %in% exts$imgs) %>% 
    mutate(
      gdrive_id = str_replace(
        gdrive_shareable_link, 
        "https://drive.google.com/file/d/(.*)/view\\?usp=sharing", 
        "\\1"),
      gdrive_dl = glue("https://drive.google.com/uc?id={gdrive_id}&export=download"),
      path_0    = here(glue("images/{filename}")),
      path_w    = glue("{path_ext_remove(path_0)}_w{image_width_inches}in.{path_ext(path_0)}"),
      path_r    = glue("../images/{basename(path_w)}"))
  
  snds <- modals %>% 
    filter(tolower(path_ext(filename)) %in% exts$snds) %>% 
    mutate(
      gdrive_id = str_replace(
        gdrive_shareable_link, 
        "https://drive.google.com/file/d/(.*)/view\\?usp=sharing", 
        "\\1"),
      gdrive_dl = glue("https://drive.google.com/uc?id={gdrive_id}&export=download"),
      path_0    = here(glue("sounds/{filename}")),
      path_m    = glue("{path_ext_remove(path_0)}.mp4"), # movie
      path_r    = glue("../sounds/{basename(path_m)}"))  # relative path
  
  list(imgs=imgs, snds=snds)
}

glink_to_gid <- function(glink){
  # expecting from gdrive_shareable_link
  # glink = "https://drive.google.com/file/d/1_wWLplFmhEAEqmbsTA0D85yuAhmapc5a/view?usp=sharing" 
  str_replace(
    glink, 
    "https://drive.google.com/file/d/(.*)/view\\?usp=sharing", 
    "\\1")
}

img_convert <- function(path_from, path_to, overwrite=F, width_in=6.5, dpi=150){
  width <- width_in * dpi
  
  if(is.na(path_from) | is.na(path_to)) return(NA)
  
  #browser()
  
  cmd <- glue('
  in="{path_from}"
  out_jpg="{path_to}"
  convert "$in" -trim -units pixelsperinch -density {dpi} -resize {width} "$out_jpg"')
  
  if (file.exists(path_to) & !overwrite) return(F)
  
  message(cmd)
  system(cmd)
  
  paths_01 <- glue("{path_ext_remove(path_to)}-{c(0,1)}.jpg")
  if (all(file.exists(paths_01))){
    file_copy(paths_01[2], path_to, overwrite = T)
    file_delete(paths_01)
  }
  #message(glue("{path_from}\t\n -> {path_to}\n", .trim = F))
}

map_site <- function(site_code){
  
  # site_code = "cinms"
  # site_code = "fknms"
  
  # SanctSound_DeploymentLocations v2 - Google Sheet
  sensors_csv = "https://docs.google.com/spreadsheets/d/1kU4mxt3W3fVd4T_L86ybxCkeaxILEZ1hmyu9r47X6JA/gviz/tq?tqx=out:csv&sheet=0"
  
  sensors <- read_csv(sensors_csv) %>% 
    filter(
      sanctuary_id == site_code,
      !is.na(lon), !is.na(lat)) %>% 
    mutate(
      popup_md   = glue("**{site_id}**: {tagline}"),
      popup_html = map_chr(popup_md, function(x) markdown::markdownToHTML(text = x, fragment.only=T))) %>% 
    st_as_sf(coords = c("lon","lat"), crs = 4326, remove = F)
  
  #library(leaflet)
  
  site <- sf::read_sf(sites_geo) %>% 
    dplyr::filter(code == site_code) %>% 
    mutate(
      geometry = (geometry + c(360,90)) %% c(-360) - c(0,-360+90)) %>%
    st_set_geometry("geometry") %>%
    st_set_crs(4326)  
  
  map <- leaflet(width = "100%") %>% 
    addProviderTiles(providers$Esri.OceanBasemap) %>% 
    addPolygons(data = site)
  
  if (nrow(sensors) > 0){
    map <- map %>% 
      addCircleMarkers(
        data = sensors,
        color = "yellow", opacity = 0.7, fillOpacity = 0.5,
        popup = ~popup_html, label = ~site_id)
  }
  map
  # addAwesomeMarkers(
  #   data = sensors, 
  #   icon = awesomeIcons(
  #     icon = 'microphone', library = 'fa',
  #     iconColor = 'black',
  #     markerColor = 'pink'), 
  #   label = ~label_html)
  #addMarkers(data = sensors, options = markerOptions())
}

map_sites <- function(){
  library(leaflet)
  
  sites <- sf::read_sf(sites_geo)
  
  leaflet(
    data = sites,
    width = "100%") %>% 
    addProviderTiles(providers$Esri.OceanBasemap) %>% 
    addPolygons(
      label = ~name, 
      labelOptions = labelOptions(noHide = T),
      popup = ~glue::glue("<a href='s_{code}.html'><b>{name}</b></a>"))
}

render_modal <- function(rmd){
  rmds_theme_white <- c(
    "modals/barnacles.Rmd",
    "modals/mussels.Rmd")
  
  site_theme <- site_config()$output$html_document$theme
  rmd_theme  <- ifelse(rmd %in% rmds_theme_white, "cosmo", site_theme)
  
  render(rmd, html_document(
    theme = rmd_theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    # toc=T, toc_depth=3, toc_float=T,
    mathjax = NULL))
  
  htm <- fs::path_ext_set(rmd, "html")
  docs_htm <- glue("docs/{htm}")
  docs_rmd <- glue("docs/{rmd}")
  file.copy(rmd, docs_rmd, overwrite = T)
  file.copy(htm, docs_htm, overwrite = T)
}

render_page <- function(rmd){
  render(rmd, html_document(
    theme = site_config()$output$html_document$theme, 
    self_contained=F, lib_dir = here("modals/modal_libs"), 
    mathjax = NULL))
}

gdrive2path <- function(gdrive_shareable_link, get_relative_path = T, redo = F){
  
  #gdrive_shareable_link <- "https://drive.google.com/file/d/1_wWLplFmhEAEqmbsTA0D85yuAhmapc5a/view?usp=sharing"
  regex <- ifelse(
    str_detect(gdrive_shareable_link, "/file/"),
    "https://drive.google.com/file/d/(.*)/view.*",
    "https://drive.google.com/open\\?id=(.*)")
  gid <- str_replace(gdrive_shareable_link, regex, "\\1") %>%
    str_trim()
  
  message(glue("gdrive_shareable_link: {gdrive_shareable_link}"))
  message(glue("gid: {gid}"))
  
  fname <- try(drive_get(as_id(gid))$name)
  
  if (class(fname) == "try-error")
    return(NA)
  
  fname_ok      <- fname %>% str_replace_all("/", "_")
  path          <- here(glue("files/{fname_ok}"))
  path_relative <- glue("../files/{fname_ok}")
  
  if (!file.exists(path) | redo)
    drive_download(as_id(gid), path)
  
  if (path_ext(path) %in% c("mp3","wav")){
    
    # path <- "/Users/bbest/github/sanctsound/files/SanctSound_CI02_01_HumpbackWhale_20181103T074755.wav"
    # path = "/Users/bbest/github/sanctsound/files/output.mp3"
    path_mp4 <- path_ext_set(path, "mp4")
    
    if (!file.exists(path_mp4) | redo){
      
      path_mp3 <- glue("{path_ext_remove(path)}_ffmpeg-clean.mp3")
      cmd <- glue("ffmpeg -y -i {path} -codec:a libmp3lame -qscale:a 2 {path_mp3}")
      res <- system(cmd)
      if (res != 0)
        return(NA)

      out <- try(
        av_spectrogram_video(
          path_mp3, path_mp4, 
          width = 720, height = 480, res = 144, framerate = 25))
      # TODO: change color ramp inside this function around line: graphics::plot(fftdata, vline = i)
      
      if (class(out) == "try-error")
        return(NA)
    }
    
    path          <- path_mp4
    path_relative <- glue("../files/{basename(path_mp4)}")
  }
  
  if (get_relative_path)
    return(path_relative)
  
  path
}

update_modal_imgs_snds <- function(modals_csv = modals_csv){
  imgs_snds <- get_modal_imgs_snds(modals_csv)
  imgs <- imgs_snds$imgs
  snds <- imgs_snds$snds
  
  # download images
  imgs %>% 
    filter(!file_exists(path_0) | redo) %>% 
    select(gdrive_dl, path_0)
  pwalk(~download.file(.x, .y))
  
  # resize images to specified width
  imgs %>% 
    filter(!file_exists(path_w) | redo) %>% 
    select(path_0, path_w, image_width_inches) %>% 
    pwalk(~img_convert(..1, ..2, width_in = ..3))
  
  # download sounds
  snds %>% 
    filter(!file_exists(path_0) | redo) %>% 
    select(gdrive_dl, path_0) %>% 
    pwalk(~download.file(.x, .y))
  
  dir_wav <- "/Volumes/GoogleDrive/.shortcut-targets-by-id/1fyEXTbnbTjqgxvYHg3lXnr3JQzwxJa1y/SoundClips/Exemplar"
  snds <- tibble(
    path_wav = dir_ls(dir_wav, glob = "*.wav")) %>% 
    mutate(
      path_mp3 = path_ext_set(path_wav, "mp3"),
      av_info  = map(path_wav, av_media_info))
  
  # ,
  #     av_info  = map(path_mp3, av_media_info),
  #     )
  
  # av_media_info(snds$path_wav[1])
  # av_media_info(snds$path_wav[1])
  #   (dir_wav, glob = "*.wav"),
  # av_audio_convert()
  
  
  # info()
  # 
  #   list.files(, "wav$")
  
  imgs <- modals %>% 
    filter(tolower(path_ext(filename)) %in% exts$imgs) %>% 
    mutate(
      gdrive_id = str_replace(
        gdrive_shareable_link, 
        "https://drive.google.com/file/d/(.*)/view\\?usp=sharing", 
        "\\1"),
      gdrive_dl = glue("https://drive.google.com/uc?id={gdrive_id}&export=download"),
      path_0    = here(glue("images/{filename}")),
      path_w    = glue("{path_ext_remove(path_0)}_w{image_width_inches}in.{path_ext(path_0)}"),
      path_r    = glue("../images/{basename(path_w)}"))
  
  # snds %>% 
  #   filter(!file_exists(path_0) | redo) %>% 
  #   select(gdrive_dl, path_0) %>% 
  #   pwalk(~download.file(.x, .y))
  
  
  # convert to movie if not found
  # snd1 <- snds %>% 
  # #snds %>% 
  #   filter(!file_exists(path_m) | redo) %>% 
  #   select(path_0, path_m) %>% 
  #   head(1)
  #   pull(path_0)
  #   pwalk(
  #     ~av_spectrogram_video(
  #       ..1, output = ..2, 
  #       width = 1280, height = 720, res = 144))
  
  # wav <- snd1$path_0
  # mp3 <- path_ext_set(wav, "mp3")
  # mov <- snd1$path_m
  # 
  # av_audio_convert(wav, mp3) # , total_time = 3)
  
  # Specified sample rate 2000 is not supported
  # Error: FFMPEG error in 'avcodec_open2 (audio)': Invalid argument
  
  # snd_convert <- function()
  # 
  # #library(htmltools)
  # library(av)  # install.packages("av")
  # 
  # 
  # for (wav in wavs){
  #   mp3 <- glue("{path_ext_remove(wav)}_3s.mp4")
  #   mp4 <- glue("{path_ext_remove(wav)}_3s.mp4")
  #   
  #   #if (!file.exists(mp4)){
  #   if (F){
  #     av_audio_convert(wav, mp3, total_time = 3)
  #     
  #   }
  # }
  
  # mp4 <- file.path("data/wav", basename(path_ext_set(wav, "mp4")))
  # tags$video(id=basename(mp4), type = "video/mp4",src = mp4, controls = "controls")
  
}

sight_sound_md <- function(sight, sound, type = "header"){
  
  has_sight = F
  has_sound = F
  if (nrow(sight) > 0) has_sight = T
  if (nrow(sound) > 0) has_sound = T
  
  md <- case_when(
    has_sound & has_sight ~ glue(
      "
      ### Sights & Sounds
      
      <div class='row'>
      
      <div class='col-xs-6'>
        ![{sight$caption}]({sight$path_relative})
      </div>
      
      <div class='col-xs-6'>
        <video controls>
        <source src='{sound$path_relative}' type='video/mp4'>
        Your browser does not support the video tag.
        </video>
        {sound$caption}
      </div>
      
      </div>
      "),
    has_sight & !has_sound ~ glue(
      "
      ### Sights & Sounds
      
      ![{sight$caption}]({sight$path_relative})
      "),
    has_sound & !has_sight ~ glue(
      "
      ### Sounds
      
      <video controls>
      <source src='{sound$path_relative}' type='video/mp4'>
      Your browser does not support the video tag.
      </video>
      {sound$caption}
      "),
    TRUE ~ "")
  md
}
