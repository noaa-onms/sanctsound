if (!require("sf")){
  install.packages(
    "sf", dependencies = c("Depends", "Imports"), type = "binary")
}
if (!require("librarian")){
  install.packages("librarian")
  library(librarian)
}
shelf(
  av, dplyr, DT, fs, glue, googledrive, googlesheets4, 
  here, htmltools, knitr, leaflet, lubridate,
  purrr, readr, rmarkdown, sf, shiny, 
  sp, stringr, tibble, tidyr, yaml)
here <- here::here
options(readr.show_col_types = F)

skip_drive_auth <- F

# authenticate to GoogleDrive using Google Service Account's secret JSON
#   after Sharing with its email: shares@nms4gargle.iam.gserviceaccount.com
if (Sys.getenv("GITHUB_ACTIONS") == ""){
  message("GITHUB_ACTIONS environmental variable is empty")
  # google_sa_json <- "/Users/bbest/My Drive (ben@ecoquants.com)/projects/nms-web/data/nms4gargle-774a9e9ec703.json"
  google_sa_json <- "/Users/bbest/My Drive/projects/nms-web/data/nms4gargle-774a9e9ec703.json"
  stopifnot(file.exists(google_sa_json))
  gsa_json_text <- readLines(google_sa_json) %>% paste(sep="\n")
} else {
  gsa_json_text <- Sys.getenv("GOOGLE_SA")
  message('nchar(Sys.getenv("GOOGLE_SA")): ', nchar(Sys.getenv("GOOGLE_SA")))
}
if (!skip_drive_auth){
  message("non-interactively authenticating to GoogleDrive with Google Service Account")
  drive_auth(path = gsa_json_text)
  gs4_auth(path = gsa_json_text)
}

# [sanctsound website content - Google Sheet]
gsheet <- "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/edit"
# OLD:
gsheet_pfx    <- "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv"
# modals_csv    <- glue("{gsheet_pfx}&sheet=modals")
# scenes_csv    <- glue("{gsheet_pfx}&sheet=scenes")
# locations_csv <- glue("{gsheet_pfx}&sheet=locations")
# metadata_csv  <- glue("{gsheet_pfx}&sheet=metadata")
# metadata_csv  <- glue("{gsheet_pfx}&sheet=metadata")

sites_csv <- here("draft/data/nms_sites.csv")
sites_geo <- here("draft/data/nms_sites.geojson")

figure <- function(
  img, caption="", alt="", align="center", size="col-md-6", header=""){
  
  stopifnot(align %in% c("center","left","right"))
  
  get_media_html <- function(img, alt=""){
    # img = "./images/questions/Equip_FKNMS_04_small.mp4"
    ext <- tolower(fs::path_ext(img))
    ifelse(
      ext %in% c("mp4"),
      glue(
        "<video class='video-fluid z-depth-1' autoplay loop controls muted>
          <source src='{img}' type='video/mp4' />
        </video>"),
      glue(
        "<img src='{img}' alt='{alt}' class='figure_img'
          data-enlargeable style='cursor: zoom-in'/>"))
  }
  
  if (length(img) == 2 && length(caption) == 1){
    if (length(alt) == 1)
      alt = c(alt, "")
    if (length(header) == 1)
      header = c(header, "")
    caption = markdown::markdownToHTML(text = caption, fragment.only=T)
    header  = sapply(header,  function(x) markdown::markdownToHTML(text = x, fragment.only=T))

    return(
      glue(
        "<!--html_preserve-->
        <figure class='figure col-md-12'>
          <div class='row'>
            <div class='col-md-6'>
              {header[1]}
              {get_media_html(img[1], alt[1])}
            </div>
            <div class='col-md-6'>
              {header[2]}
              {get_media_html(img[2], alt[2])}
            </div>
          </div>
          <figcaption class='figure-caption'>
            {caption}
          </figcaption>
        </figure>
        <!--/html_preserve-->"))
  }
  
  if (length(img) == 2 && length(caption) == 2){
    if (length(alt) == 1)
      alt = c(alt, "")
    if (length(header) == 1)
      header = c(header, "")
    
    caption = sapply(caption, function(x) markdown::markdownToHTML(text = caption, fragment.only=T))
    header  = sapply(header,  function(x) markdown::markdownToHTML(text = x, fragment.only=T))
    
    return(
      glue(
        "<!--html_preserve-->
        <figure class='figure col-md-12'>
          <div class='row'>
            <div class='col-md-6'>
              {header[1]}
              {get_media_html(img[1], alt[1])}
              <figcaption class='figure-caption'>
                {caption[1]}
              </figcaption>
            </div>
            <div class='col-md-6'>
              {header[2]}
              {get_media_html(img[2], alt[2])}
              <figcaption class='figure-caption'>
                {caption[2]}
              </figcaption>
            </div>
          </div>
        </figure>
        <!--/html_preserve-->"))
  }
  
  caption = markdown::markdownToHTML(text = caption, fragment.only=T)
  header  = markdown::markdownToHTML(text = header, fragment.only=T)
  
  if (length(img) != 2 && align == "center"){
    glue(
      "<!--html_preserve-->
      <center>
        <figure class='figure {size}'>
          {header}
          {get_media_html(img, alt)}
          <figcaption class='figure-caption'>
            {caption}
          </figcaption>
        </figure>
      </center>
      <!--/html_preserve-->")
  } else {
    glue(
      "<!--html_preserve-->
      <figure class='figure {size} clearfix' style='float:{align}'>
        {header}
        {get_media_html(img, alt)}
        <figcaption class='figure-caption'>
          {caption}
        </figcaption>
      </figure>
      <!--/html_preserve-->")
  }
}

get_sheet_csv <- function(sheet){
  glue("{gsheet_pfx}&sheet={sheet}")
}

get_sheet <- function(sheet, redo = F){
  # sheet = "figures"
  
  if (!exists(sheet, envir = globalenv()) | redo){
    # d <- get_sheet_csv(sheet) %>% 
    d <- read_sheet(gsheet, sheet) %>% 
      select(-starts_with("..."))
    msg <- glue("get_sheet(): read_csv(URL), assign to variable '{sheet}'\n  URL: {get_sheet_csv(sheet)}", .trim = F)
    message(as.character(msg))
    assign(sheet, d, envir = globalenv())
  } else {
    message(glue("get_sheet(): return variable '{sheet}' which already exists"))
  }
  get(sheet)
}
sanctuaries <- get_sheet("sanctuaries")
modals      <- get_sheet("modals")
figures     <- get_sheet("figures")
lookups     <- get_sheet("lookups")
# scenes      <- get_sheet("scenes")
locations   <- get_sheet("locations")
metadata    <- get_sheet("metadata")

get_nms_ply <- function(nms, dir_pfx = here("draft")){
  # get polygon for National Marine Sanctuary
  
  nms_shp <- glue("{dir_pfx}/data/shp/{nms}_py.shp")
  
  if (!file.exists(nms_shp)){
    # download if needed
    
    # https://sanctuaries.noaa.gov/library/imast_gis.html
    nms_url <- glue::glue("https://sanctuaries.noaa.gov/library/imast/{nms}_py2.zip")
    nms_zip <- here::here(glue::glue("draft/data/{nms}.zip"))
    shp_dir <- here::here("draft/data/shp")
    
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
  sites <- readr::read_csv(sites_csv, col_types = cols())
  
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
      source(here::here("draft/functions.R"))
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
      path_0    = here(glue("draft/images/{filename}")),
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

get_modal_file_tbl <- function(
  tab_name, 
  sanctuary_code = params$sanctuary_code,
  modal_title    = params$modal_title){
  
  # tab_name = "Sight"; sanctuary_code = params$sanctuary_code; modal_title = params$modal_title

  tbl <- get_sheet("modals") %>% 
    left_join(
      get_sheet("figures"),
      by = "modal_id") %>% 
    filter(
      sanctuary_code == !!sanctuary_code,
      modal_title    == !!modal_title,
      tab_name       == !!tab_name,
      !is.na(gdrive_shareable_link)) %>% 
    mutate(
      path_relative = map_chr(gdrive_shareable_link, gdrive2path)) %>% 
    filter(
      !is.na(path_relative))
  tbl
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

md_links_new_window <- function(s){
  str_replace_all(s, "\\[(.*?)\\]\\((.*?)\\)", "<a href='\\2' target='_blank'>\\1</a>")
}

map_site <- function(site_code, sites=NULL){
  # site_code = "cinms"; sites=na.omit(sounds$site_id)
  
  locations <- get_sheet("locations")
  
  sensors <- locations %>% 
    filter(
      sanctuary_id == site_code,
      !is.na(lon), !is.na(lat),
      use_for_map) %>% 
    mutate(
      popup_md   = glue("**{site_id}**: {tagline}"),
      popup_html = map_chr(popup_md, function(x){
        markdown::markdownToHTML(text = x, fragment.only=T) })) %>% 
    st_as_sf(coords = c("lon","lat"), crs = 4326, remove = F)
  
  if (!is.null(sites)){
    stopifnot(all(sites %in% sensors$site_id))
    sensors <- sensors %>% 
      filter(site_id %in% sites)
    sensor_options = labelOptions(noHide = T)
  } else {
    sensor_options = NULL
  }
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
        popup = ~popup_html, 
        label = ~site_id,
        labelOptions = sensor_options)
    # addAwesomeMarkers(
    #   data = sensors,
    #   icon = awesomeIcons(
    #     icon = 'microphone', library = 'fa',
    #     iconColor = 'black',
    #     markerColor = 'pink'),
    #   label = ~label_html)
  }
  
  map
}

map_sites <- function(){
  library(leaflet)
  library(htmltools)
  
  sites <- sf::read_sf(sites_geo) %>% 
    mutate(
      lbl = glue::glue("<a href='./s_{code}.html'><b>{name}</b></a>"))
  # to make clickable: add `.leaflet-tooltip { pointer-events: auto; }` to libs/styles.css
  site_labels <- sites$lbl %>% lapply(HTML)

  leaflet(
    data = sites, width = "100%") %>% 
    addProviderTiles(providers$Esri.OceanBasemap) %>% 
    addPolygons(
      label = site_labels, 
      labelOptions = labelOptions(
        interactive = T,
        permanent = T))

}

modal_title_to_html_path <- function(sanctuary_code, modal_title, pfx = here("draft/modals")){
  
  modal_html <- glue("{sanctuary_code}_{modal_title}") %>% 
    str_replace_all(" ", "-") %>% 
    str_to_lower() %>% 
    path_ext_set("html")
  path(pfx, modal_html)
  
}

na_factor <- function(x, na_label = "Other"){
  y <- factor(x, exclude=NULL)
  levels(y)[is.na(levels(y))] <- na_label
  y
}

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
      # csv       = "https://docs.google.com/spreadsheets/d/1zmbqDv9KjWLYD9fasDHtPXpRh5ScJibsCHn56DYhTd0/gviz/tq?tqx=out:csv&sheet=modals",
      csv       = "https://sanctsound.ioos.us/draft/data/svg.csv",
      svg       = glue("svg/{code}.svg")))
  }
render_modal <- function(
  sanctuary_code, modal_title, modal_html, modal_id, 
  rmd = here("draft/modals/_modal_template.Rmd")){
  
  message(glue("RENDER {basename(modal_html)}"))
  
  render(
    rmd, 
    params = list(
      sanctuary_code = sanctuary_code,
      modal_title    = modal_title),
    output_file   = modal_html)
}

render_page <- function(rmd){
  render(rmd, html_document(
    theme = site_config()$output$html_document$theme, 
    self_contained=F, lib_dir = here("draft/modals/modal_libs"), 
    mathjax = NULL))
}

audio_to_spectrogram_video <- function(path, path_mp4){
  
  # skip if running on Github since slow to generate, need to render on Mac laptop
  if (Sys.getenv("GITHUB_ACTIONS") != ""){
    message("Skipping audio_to_spectrogram_video() using ffmpeg since GITHUB_ACTIONS environmental variable is not empty")
    return(NA)
  }
  
  # install ffmpeg on Mac: brew install ffmpeg
  path_mp3 <- glue("{path_ext_remove(path)}_ffmpeg-clean.mp3")
  cmd <- glue("source ~/.bash_profile; ffmpeg -y -i {path} -codec:a libmp3lame -qscale:a 2 {path_mp3}")
  res <- system(cmd)
  
  # dyld: Library not loaded: /usr/local/opt/libffi/lib/libffi.7.dylib
  #   Referenced from: /usr/local/opt/p11-kit/lib/libp11-kit.0.dylib
  #   Reason: image not found
  # https://github.com/platformio/platform-lattice_ice40/issues/7#issuecomment-949301515
  #   cp /usr/local/opt/ntopng/libffi.7.dylib /usr/local/opt/libffi/lib/libffi.7.dylib
  
  if (res != 0)
    return(NA)
  
  out <- try(
    av_spectrogram_video(
      path_mp3, path_mp4, 
      width = 720, height = 480, res = 144, framerate = 25))
  # TODO: change color ramp inside this function around line: graphics::plot(fftdata, vline = i)
  
  if ("try-error" %in% class(out))
    return(NA)
  
  if (!file.exists(path_mp4))
    stop(glue("Why does path_mp4 {path_mp4} not exist?"))
  
  path_mp4
}

import_sounds <- function(redo = T){
  sounds_csv <- here("draft/data/sounds.csv")
  
  if (!file.exists(sounds_csv) | redo){
    tbl_sounds <- get_sheet("figures") %>% 
      filter(
        tab_name == "Sound",
        !is.na(gdrive_shareable_link)) %>% 
      mutate(
        snd_rel = map_chr(gdrive_shareable_link, gdrive2path, relative_pfx = "")) %>% 
      filter(
        !is.na(snd_rel)) %>%
      left_join(
        get_sheet("modals") %>% 
          select(modal_id, modal_title, sanctuary_code),
        by = "modal_id") %>% 
      left_join(
        get_sheet("lookups") %>%
          select(
            modal_title = icon_modal, icon_sound_subcategory),
        by = "modal_title") %>% 
      left_join(
        get_sheet("lookups") %>%
          select(icon_sound_subcategory = sound_subcategory, sound_category = sound_cat, sound_subcategory = sound_subcat),
        by = "icon_sound_subcategory") %>% 
      arrange(sound_category, sound_subcategory, modal_title, sanctuary_code)
    	  
    write_csv(tbl_sounds, sounds_csv)
  }

  read_csv(sounds_csv)
}

create_svg_csv <- function(redo = T){
  svg_csv <- here("draft/data/svg.csv")
  
  if (!file.exists(svg_csv) | redo){
    tbl_svg <- get_sheet("modals") %>% 
      select(modal_id, modal_title, sanctuary_code) %>% 
      left_join(
        get_sheet("lookups") %>%
          select(
            modal_title = icon_modal, icon_sound_subcategory),
        by = "modal_title") %>% 
      left_join(
        get_sheet("lookups") %>%
          select(icon_sound_subcategory = sound_subcategory, sound_category = sound_cat, sound_subcategory = sound_subcat),
        by = "icon_sound_subcategory") %>% 
      arrange(sanctuary_code, sound_category, sound_subcategory, modal_title) # 
    
    write_csv(tbl_svg, svg_csv)
  }

  read_csv(svg_csv)
}

import_stories <- function(redo = T){
  stories_csv <- here("draft/data/stories.csv")
  
  if (!file.exists(stories_csv) | redo){
    # View(tbl_stories)
    tbl_stories <- get_sheet("stories") %>% 
      filter(
        !is.na(image_gdrive_sharable_link)) %>% 
      mutate(
        img_rel = map_chr(image_gdrive_sharable_link, gdrive2path, relative_pfx = "")) %>% 
      filter(
        !is.na(img_rel))
    
    write_csv(tbl_stories, stories_csv)
  }
  
  tbl_stories <- read_csv(stories_csv, col_types = cols())
  
  rgns <- c(
    "National", 
    tbl_stories$region %>% setdiff("National") %>% sort())
  tbl_stories$region <- factor(
    tbl_stories$region,
    levels = rgns,
    ordered = T)
  
  tbl_stories %>% 
    arrange(region, sanctuary, title)
}

header2anchor <- function(header, pfx="stories.html"){
  # header <- "Bocaccio (CINMS)"
  
  anchor <- header %>% 
    tolower() %>% 
    str_replace_all(" ", "-") %>% 
    str_replace_all("[^A-z-]", "")
  glue("{pfx}#{anchor}")
}

story_grid_item <- function(title, img_rel, story_link, ...){
  if(is.na(story_link)){
    glue("
      <div class='grid-item'>
        <img src='{img_rel}' target='_blank'>
      </div>")
  } else {
    glue("
      <div class='grid-item'>
        <a href='{story_link}'>
        <img src='{img_rel}'>
        </a>
      </div>")
  }
}

story_card <- function(img_rel, story_link, title, title_style, title_size, ...){
  link_html <- ""
  if(!is.na(story_link))
    link_html <- glue("<a href='{story_link}' target='_blank' class='stretched-link'></a>")
  title_html <- ""
  if(!is.na(title)){
    css_style <- ifelse(!is.na(title_style), title_style, "black-white")
    font_size <- ifelse(!is.na(title_size), glue("style='font-size: {title_size}'"), "") # defaults to 1.3rem
    title_html <- glue("
      <div class='card-img-overlay d-flex'>
        <h4 class='card-title align-self-center mx-auto {css_style}' {font_size}>
          {title}
        </h4>
      </div>")
  }
  glue("
    <div class='card card-img-wrap'>
      <img class='card-img' src='{img_rel}'/>
      {link_html}
      {title_html}
    </div>") %>% 
    HTML() # .noWS="outside")

}
update_sounds_menu <- function(){
  
  # tbl_sounds <- import_sounds(redo=F) %>% 
  tbl_sounds <- import_sounds() %>% 
    left_join(
      get_sheet("sanctuaries") %>% 
        select(sanctuary_code, sanctuary_name = name, sanctuary_type = type),
      by = "sanctuary_code")
  
  site <- read_yaml(here("draft/_site.yml"))
  
  idx_sounds <- which(map_chr(site$navbar$left, "text") == "Sounds")
  
  sounds_menu <- tbl_sounds %>% 
    arrange(sound_category, modal_title, sanctuary_code) %>% 
    mutate(
      text_href = pmap(
        ., 
        function(modal_title, sanctuary_name, snd_rel, ...){
          txt <- glue("{modal_title} ({sanctuary_name})")
          list(
            text = txt, 
            href = header2anchor(txt, pfx = "sounds.html"))})) %>%
    group_by(sound_category) %>% 
    summarize(
      list_text_href = list(text_href)) %>% 
    mutate(
      category_menu = map2(
        sound_category, list_text_href,
        function(x, y)
          list(
            text = x,
            menu = y))) %>%
    pull(category_menu)
  
  sounds_menu <- c(list(list(
    text = "Example Sounds",
    href = "sounds.html"),
    list(text = "---------")),
    sounds_menu)
  
  site$navbar$left[[idx_sounds]]$menu = sounds_menu
  write_yaml(site, here("draft/_site.yml"))
}

update_stories_menu <- function(){
  
  tbl_stories <- import_stories() %>% 
    left_join(
      get_sheet("sanctuaries") %>% 
        select(sanctuary=sanctuary_code, sanctuary_name = name, sanctuary_type = type),
      by = "sanctuary")
  
  site <- read_yaml(here("draft/_site.yml"))
  
  idx_stories <- which(map_chr(site$navbar$left, "text") == "Stories")
  
  stories_menu <- tbl_stories %>%
    arrange(region, title) %>% 
    mutate(
      text_href = pmap(
        ., 
        function(region, title, sanctuary_name, ...){
          txt_sanctuary <- ifelse(
            is.na(sanctuary_name),
            "",
            glue(" ({sanctuary_name})"))
          txt <- glue("{title}{txt_sanctuary}")
          
          list(
            text = txt, 
            href = header2anchor(region, pfx = "stories.html"))})) %>%
    group_by(region) %>% 
    summarize(
      list_text_href = list(text_href)) %>% 
    mutate(
      region_menu = map2(
        region, list_text_href,
        function(x, y)
          list(
            text = x,
            menu = y))) %>%
    pull(region_menu)
  
  stories_menu <- c(list(list(
    text = "All Stories",
    href = "stories.html"),
    list(text = "---------")),
    stories_menu)
    
  site$navbar$left[[idx_stories]]$menu = stories_menu
  write_yaml(site, here("draft/_site.yml"))
}

gdrive2path <- function(gdrive_shareable_link, get_relative_path = T, relative_pfx = "../", redo = F, skip_spectrogram = F){
  
  # gdrive_shareable_link <- "https://drive.google.com/file/d/1_wWLplFmhEAEqmbsTA0D85yuAhmapc5a/view?usp=sharing"
  # gdrive_shareable_link <- tbl$gdrive_shareable_link; get_relative_path = T; redo = F
  # gdrive_shareable_link <- sound$sound_enhancement; get_relative_path = T; relative_pfx = "../", redo = F, skip_spectrogram = T; redo = F
  # gdrive_shareable_link <- "https://drive.google.com/file/d/1ExSIVhHbzWgZJe95EMli8EvpgkL2hpc4/view?usp=sharing"; get_relative_path = T; relative_pfx = "../"; redo = F; skip_spectrogram = F
  
  regex <- ifelse(
    str_detect(gdrive_shareable_link, "/file/"),
    "https://drive.google.com/file/d/(.*)/view.*",
    "https://drive.google.com/open\\?id=(.*)")
  gid <- str_replace(gdrive_shareable_link, regex, "\\1") %>%
    str_trim()
  
  fname <- try(drive_get(as_id(gid))$name)
  
  message(glue("gdrive_shareable_link: {gdrive_shareable_link}"))
  message(glue("  gid: {gid}"))
  
  if ("try-error" %in% class(fname))
    return(NA)
  
  fname_ok      <- fname %>% str_replace_all("/", "_")
  path          <- here(glue("draft/files/{fname_ok}"))
  path_relative <- glue("{relative_pfx}files/{fname_ok}")
  message(glue("  fname_ok: {fname}"))
  
  if (!file.exists(path) | redo)
    drive_download(as_id(gid), path, overwrite = T)
  
  x <- googledrive::drive_get(as_id(gid)) %>% 
    mutate(
      modified = map_chr(drive_resource, "modifiedTime"))
  y <- x$drive_resource[[1]]
  
  # TODO: check modifiedTime
  date_mod <- lubridate::as_datetime(x$drive_resource[[1]]$modifiedTime)
  
  if (path_ext(path) %in% c("mp3","wav") & !skip_spectrogram){
    
    # path <- "/Users/bbest/github/sanctsound/files/SanctSound_CI02_01_HumpbackWhale_20181103T074755.wav"
    # path = "/Users/bbest/github/sanctsound/files/output.mp3"
    path_mp4 <- path_ext_set(path, "mp4")
    
    if (!file.exists(path_mp4) | redo)
      path_mp4 <- audio_to_spectrogram_video(path, path_mp4)
    
    path          <- path_mp4
    path_relative <- glue("{relative_pfx}files/{basename(path_mp4)}")
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
      path_0    = here(glue("draft/images/{filename}")),
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

sight_sounds_md <- function(sight, sounds, type = "header", show_sites = F){
  
  has_sight          = F
  has_sounds         = F
  has_sound_enhanced = F
  if (nrow(sight) > 0)  has_sight = T
  if (nrow(sounds) > 0) has_sounds = T
  
  if(nrow(sounds) == 1 && is.na(sounds$caption))
    sound$caption <- ""
  
  md       <- ""
  md_sight <- glue("![{sight$caption}]({sight$path_relative})")
  # md_sound <- glue("
  #   <video controls>
  #   <source src='{sound$path_relative}' type='video/mp4'>
  #   Your browser does not support the video tag.
  #   </video>
  #   {sound$caption}")
  
  sounds_0 <- sounds
  sounds <- sounds_0 %>% 
    mutate(
      site_md = ifelse(!is.na(site_id), glue("\n\n### Site {site_id}\n", .trim = F), ""),
      md = glue("
        {site_md}
        <video controls>
         <source src='{path_relative}' type='video/mp4'/>Your browser does not support the video tag.
        </video>
        <p>
        {caption}
        </p>
        "),
      md = ifelse(
        !is.na(sound_enhancement),
        glue("
          {md}\
          <i class='fas fa-assistive-listening-systems fa-3x'></i>
          <audio controls><source src='{gdrive2path(sound_enhancement, skip_spectrogram=T)}' type='audio/wav'>
          Your browser does not support the audio element.</audio>\
          Listen to the same sound clip optimized for human hearing. 
          Many ocean animals can hear and produce sounds that humans cannot, 
          learn more <a href='..' target='_blank'>here<a/>.
          "),
        md))
  
  # if (has_sounds && !is.na(sound$sound_enhancement)){
  #   snd_enh_lnk <- gdrive2path(sound$sound_enhancement, skip_spectrogram=T)
  #   md_sound <- glue("
  #     {md_sound}\
  #     \
  #     <i class='fas fa-assistive-listening-systems fa-3x'></i> <audio controls><source src='{snd_enh_lnk}' type='audio/wav'>Your browser does not support the audio element.</audio>\
  #     \
  #     Listen to the same sound clip optimized for human hearing. Many ocean animals can hear and produce sounds that humans cannot, learn more <a href='..' target='_blank'>here<a/>.")
  # }

  if (has_sounds & has_sight)
    md <- glue(
"
### Sights & Sounds

<div class='container'><div class='row'>

<div class='col'>
  {md_sight}
</div>

<div class='col'>
  {paste(sounds$md, collapse='\n\n')}
</div>

</div></div>
")
  
  if (has_sight & !has_sounds)
    md <- glue(
"
### Sights

{md_sight}
")
  
  if (has_sounds & !has_sight & !show_sites)
    md <- glue(
      "### Sounds\n\n",
      "{paste(sounds$md, collapse='\n<br>\n')}")
  # cat(md)

  if (has_sounds & !has_sight & show_sites)
    md <- glue(
      "{paste(sounds$md, collapse='\n<br>\n')}")
  
  md
}
