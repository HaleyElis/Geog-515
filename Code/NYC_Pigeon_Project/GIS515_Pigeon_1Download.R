###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 1: Download
###
### Haley Meyrowitz
### Haley05@UNC.edu
###
### 04/06/2026
###

# Load libraries
library(sf)
library(dplyr)

#----------------------------------------#
# 1. 311 Pigeon Complaints ----
#----------------------------------------#

base <- "https://data.cityofnewyork.us/resource/erm2-nwe9.geojson"

soql <- "
SELECT unique_key, created_date, complaint_type, descriptor,
       incident_address, city, latitude, longitude, location
WHERE complaint_type = 'Unsanitary Pigeon Condition'
LIMIT 50000
"

url <- paste0(base, "?$query=", utils::URLencode(soql, reserved = TRUE))

pigeon_311 <- st_read(url)

st_write(pigeon_311, "../../Data/Raw/pigeon_311.gpkg", delete_dsn = TRUE)

#----------------------------------------#
# 2. Subway Data ----
#----------------------------------------#

subway_routes <- st_read("https://data.ny.gov/resource/s692-irgq.geojson")
subway_stops  <- st_read("https://data.ny.gov/resource/39hk-dx4f.geojson")

st_write(subway_routes, "../../Data/Raw/subway.gpkg", "routes", delete_dsn = TRUE)
st_write(subway_stops,  "../../Data/Raw/subway.gpkg", "stops")

#----------------------------------------#
# 3. Neighborhoods ----
#----------------------------------------#

library(nycgeo)

nta <- nyc_boundaries(geography = "nta")

st_write(nta, "../../Data/Raw/nyc_neighborhoods.gpkg", delete_dsn = TRUE)

#----------------------------------------#
# 4. eBird ----
#----------------------------------------#
ebird_path <- "../../Data/Raw/ebd_US-NY-061_rocpig_smp_relFeb-2026/ebd_US-NY-061_rocpig_smp_relFeb-2026.txt"

if (!file.exists(ebird_path)) {
  warning("eBird file not found in ../../Data/Raw/. Place the downloaded txt file there before running Script 2.")
} else {
  message("eBird file found: ", ebird_path)
}

#----------------------------------------#
# Confirmation ----
#----------------------------------------#

print(st_layers("../../Data/Raw/pigeon_311_unsanitary.gpkg"))
print(st_layers("../../Data/Raw/nyc_borough_boundaries.gpkg"))
print(st_layers("../../Data/Raw/nyc_neighborhoods.gpkg"))
print(st_layers("../../Data/Raw/nyc_subways.gpkg"))
