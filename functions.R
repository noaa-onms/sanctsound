library(here)
library(glue)
library(dplyr)
library(purrr)
library(fs)
library(sf)
library(sp)
library(readr)
library(leaflet)

#library(mapview)
#library(leaflet)

sites_csv <- here::here("data/nms_sites.csv")
sites_geo <- here::here("data/nms_sites.geojson")

get_nms_ply <- function(nms, dir_pfx = here::here()){
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

if (F){
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

map_site <- function(site_code){
  
  # site_code = "cinms"
  
  # SanctSound_DeploymentLocations v2 - Google Sheet
  sensors_csv = "https://docs.google.com/spreadsheets/d/1kU4mxt3W3fVd4T_L86ybxCkeaxILEZ1hmyu9r47X6JA/gviz/tq?tqx=out:csv&sheet=0"

  sensors <- read_csv(sensors_csv) %>% 
    filter(sanctuary_id == site_code) %>% 
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
  
  leaflet(width = "100%") %>% 
    addProviderTiles(providers$Esri.OceanBasemap) %>% 
    addPolygons(data = site) %>% 
    addCircleMarkers(
      data = sensors,
      color = "yellow", opacity = 0.7, fillOpacity = 0.5,
      popup = ~popup_html, label = ~site_id)
  
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


