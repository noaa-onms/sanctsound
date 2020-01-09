# library(here)
# library(glue)
# library(dplyr)
# library(purrr)
# library(fs)
# library(sf)
# library(sp)
# library(readr)

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
    ~code, ~name,
    "sbnms", "Stellwagen Bank",
    "grnms", "Gray’s Reef",
    "fknms", "Florida Keys",
    "ocnms", "Olympic Coast",
    "mbnms", "Monterey Bay",
    "cinms", "Channel Islands",
    "pmnm", "Papahānaumokuākea",
    "hihwnms", "Hawaiian Islands Humpback Whale") %>% 
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

