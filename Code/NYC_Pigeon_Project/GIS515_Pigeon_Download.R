###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 1: Download
###
### Haley Meyrowitz
### Haley05@UNC.edu
###
### 02/16/2026
###

#----------------------------------------#
# Project Description   ----
#----------------------------------------#

#### // This project will analyze spatial patterns of pigeon activity at New York City subway station entrances. Using wildlife observation data combined with MTA entrance locations the study will identify pigeon hotspots associated with increased pigeon presence.//


#
# Load Libraries ----
#
library(sf) ## spatial data (vector)
library(dplyr)

#
# Read Data From the Internet ----
# 

#----------------------------------------#
# Data set 1: 311 Pigeon complaints: 01/2020-02/2026   ----
#----------------------------------------#
# "https://data.cityofnewyork.us/Social-Services/311-Service-Requests-from-2020-to-Present/erm2-nwe9/about_data"


## Base API endpoint URL
base <- "https://data.cityofnewyork.us/resource/erm2-nwe9.geojson" 

## SoQL query:
## Only download 311 pigeon related complaints, only columns of data needed, increase limit of rows
soql <- "
SELECT
  unique_key,
  created_date,
  complaint_type,
  descriptor,
  incident_address,
  city,
  latitude,
  longitude,
  location
WHERE complaint_type = 'Unsanitary Pigeon Condition'
ORDER BY created_date DESC
LIMIT 50000
"

## Combine base API and SoQL query
url <- paste0(base, "?$query=", utils::URLencode(soql, reserved = TRUE))

## Final read from web
pigeon_311_sf <- read_sf(url)

## To check the download worked properly, uncomment
## nrow(pigeon_311_sf)
## plot(st_geometry(pigeon_311_sf))
## names(pigeon_311_sf)

## Save original vector layer to hard drive as a .gpkg file ----
st_write(pigeon_311_sf,
         "../../Data/Raw/pigeon_311_unsanitary.gpkg",
         delete_dsn = TRUE)

#----------------------------------------#
# Data set 2: NYC Borough Boundaries (NYC Open Data)   ----
#----------------------------------------#
borough_url <- "https://data.cityofnewyork.us/resource/gthc-hcne.geojson?$limit=10"
nyc_boroughs <- read_sf(borough_url)

# Check data
# glimpse(nyc_boroughs)
# st_crs(nyc_boroughs)

# Define output path
out_boroughs <- "../../Data/Raw/nyc_borough_boundaries.gpkg"

# Write to GeoPackage
st_write(
  nyc_boroughs,
  dsn = out_boroughs,
  layer = "nyc_borough_boundaries",
  delete_dsn = TRUE
)

# Confirm it wrote correctly
st_layers(out_boroughs)

#----------------------------------------#
# Data set 3: NYC Subway Routes (NYC Open Data)  ----
#----------------------------------------#

subway_rt <- read_sf("https://data.ny.gov/resource/s692-irgq.geojson")
subway_stop <- read_sf("https://data.ny.gov/resource/39hk-dx4f.geojson")

# Check data
# glimpse(subway_rt)
# glimpse(subway_stop)
# st_crs(subway_rt)
# st_crs(subway_stop)

# Define output path
out_subway <- "../../Data/Raw/nyc_subways.gpkg"

# If the gpkg exists, remove it first
if (file.exists(out_subway)) file.remove(out_subway)

# Write subway routes (delete file first)
st_write(
  subway_rt,
  dsn = out_subway,
  layer = "nyc_subway_routes",
  delete_dsn = TRUE
)

# Add subway stops as another layer
st_write(
  subway_stop,
  dsn = out_subway,
  layer = "nyc_subway_stops"
)

# Confirm layers
st_layers(out_subway)
