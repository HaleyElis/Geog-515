###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 2: Wrangle
###
### Haley Meyrowitz
### Haley05@UNC.edu
###
### 04/06/2026
###

# Load libraries ----
library(sf)
library(dplyr)
library(readr)
library(stringr)
library(lubridate)

# Settings ----
target_crs <- 2263  # NAD83 / New York Long Island (ftUS)

dir.create("../../Data/Cleaned", showWarnings = FALSE, recursive = TRUE)

#----------------------------------------#
# 1. 311 Pigeon Complaints ----
#----------------------------------------#

pigeon_311 <- st_read(
  "../../Data/Raw/pigeon_311_unsanitary.gpkg",
  layer = "pigeon_311_unsanitary",
  quiet = TRUE
)

# Keep needed variables
pigeon_311 <- pigeon_311 %>%
  select(
    unique_key,
    created_date,
    complaint_type,
    descriptor,
    incident_address,
    city,
    latitude,
    longitude,
    geom
  )

# Clean coordinates and dates
pigeon_311 <- pigeon_311 %>%
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    created_date = as.POSIXct(created_date, tz = "UTC")
  )

# Remove empty geometries and transform CRS
pigeon_311 <- pigeon_311 %>%
  filter(!st_is_empty(geom)) %>%
  st_transform(target_crs)

#----------------------------------------#
# 2. Boroughs ----
#----------------------------------------#

nyc_boroughs <- st_read(
  "../../Data/Raw/nyc_borough_boundaries.gpkg",
  layer = "nyc_borough_boundaries",
  quiet = TRUE
) %>%
  filter(!st_is_empty(geom)) %>%
  st_transform(target_crs)

#----------------------------------------#
# 3. Neighborhoods (NTAs) ----
#----------------------------------------#

nyc_neighborhoods <- st_read(
  "../../Data/Raw/nyc_neighborhoods.gpkg",
  layer = "nyc_neighborhoods",
  quiet = TRUE
) %>%
  filter(!st_is_empty(geom)) %>%
  st_transform(target_crs)

#----------------------------------------#
# 4. Subway Routes and Stops ----
#----------------------------------------#

subway_routes <- st_read(
  "../../Data/Raw/nyc_subways.gpkg",
  layer = "nyc_subway_routes",
  quiet = TRUE
) %>%
  filter(!st_is_empty(geom)) %>%
  st_transform(target_crs)

subway_stops <- st_read(
  "../../Data/Raw/nyc_subways.gpkg",
  layer = "nyc_subway_stops",
  quiet = TRUE
) %>%
  filter(!st_is_empty(geom)) %>%
  st_transform(target_crs)

# Create a unique stop id if one is not already present
subway_stops <- subway_stops %>%
  mutate(stop_uid = row_number())

#----------------------------------------#
# 5. eBird Rock Pigeon Data (Manhattan only) ----
#----------------------------------------#

ebird_path <- "../../Data/Raw/ebd_US-NY-061_rocpig_smp_relFeb-2026/ebd_US-NY-061_rocpig_smp_relFeb-2026.txt"

ebird_raw <- read_tsv(
  ebird_path,
  guess_max = 100000,
  show_col_types = FALSE
)

# Standardize names
ebird_raw <- ebird_raw %>%
  rename_with(~ str_to_lower(.x)) %>%
  rename_with(~ str_replace_all(.x, " ", "_"))

# Clean and keep variables useful for this project
# Restrict to 2020-present so it aligns with the 311 complaint period
ebird_clean <- ebird_raw %>%
  select(
    common_name,
    scientific_name,
    observation_count,
    locality,
    locality_id,
    locality_type,
    latitude,
    longitude,
    observation_date,
    protocol_name,
    duration_minutes,
    effort_distance_km,
    number_observers,
    all_species_reported,
    approved,
    reviewed
  ) %>%
  filter(common_name == "Rock Pigeon") %>%
  filter(!is.na(latitude), !is.na(longitude)) %>%
  mutate(
    observation_date = as.Date(observation_date),
    approved = as.numeric(approved),
    reviewed = as.numeric(reviewed),
    observation_count_num = suppressWarnings(as.numeric(observation_count)),
    observation_count_use = ifelse(is.na(observation_count_num), 1, observation_count_num)
  ) %>%
  filter(observation_date >= as.Date("2020-01-01")) %>%
  filter(approved == 1)

ebird_sf <- st_as_sf(
  ebird_clean,
  coords = c("longitude", "latitude"),
  crs = 4326,
  remove = FALSE
) %>%
  st_transform(target_crs)

#----------------------------------------#
# 6. Join neighborhoods to point data ----
#----------------------------------------#

pigeon_311 <- st_join(pigeon_311, nyc_neighborhoods, join = st_intersects, left = TRUE)
ebird_sf  <- st_join(ebird_sf, nyc_neighborhoods, join = st_intersects, left = TRUE)

#----------------------------------------#
# 7. Distance to nearest subway stop ----
#----------------------------------------#

# 311 complaints
pigeon_311$nearest_stop_i <- st_nearest_feature(pigeon_311, subway_stops)
pigeon_311$nearest_stop_uid <- subway_stops$stop_uid[pigeon_311$nearest_stop_i]
pigeon_311$nearest_stop_name <- subway_stops$stop_name[pigeon_311$nearest_stop_i]
pigeon_311$dist_to_stop_ft <- as.numeric(
  st_distance(
    pigeon_311,
    subway_stops[pigeon_311$nearest_stop_i, ],
    by_element = TRUE
  )
)

# eBird observations
ebird_sf$nearest_stop_i <- st_nearest_feature(ebird_sf, subway_stops)
ebird_sf$nearest_stop_uid <- subway_stops$stop_uid[ebird_sf$nearest_stop_i]
ebird_sf$nearest_stop_name <- subway_stops$stop_name[ebird_sf$nearest_stop_i]
ebird_sf$dist_to_stop_ft <- as.numeric(
  st_distance(
    ebird_sf,
    subway_stops[ebird_sf$nearest_stop_i, ],
    by_element = TRUE
  )
)

# Distance bands for both datasets
make_dist_band <- function(x) {
  case_when(
    x <= 500  ~ "0-500 ft",
    x <= 1000 ~ "500-1000 ft",
    x <= 2000 ~ "1000-2000 ft",
    TRUE      ~ "2000+ ft"
  )
}

pigeon_311 <- pigeon_311 %>%
  mutate(dist_band = make_dist_band(dist_to_stop_ft))

ebird_sf <- ebird_sf %>%
  mutate(dist_band = make_dist_band(dist_to_stop_ft))

#----------------------------------------#
# 8. Write cleaned outputs ----
#----------------------------------------#

st_write(
  pigeon_311,
  dsn = "../../Data/Cleaned/pigeon_311_clean.gpkg",
  layer = "pigeon_311_clean",
  delete_dsn = TRUE,
  quiet = TRUE
)

st_write(
  nyc_boroughs,
  dsn = "../../Data/Cleaned/nyc_borough_boundaries_clean.gpkg",
  layer = "nyc_borough_boundaries_clean",
  delete_dsn = TRUE,
  quiet = TRUE
)

st_write(
  nyc_neighborhoods,
  dsn = "../../Data/Cleaned/nyc_neighborhoods_clean.gpkg",
  layer = "nyc_neighborhoods_clean",
  delete_dsn = TRUE,
  quiet = TRUE
)

out_subway_clean <- "../../Data/Cleaned/nyc_subways_clean.gpkg"
if (file.exists(out_subway_clean)) file.remove(out_subway_clean)

st_write(
  subway_routes,
  dsn = out_subway_clean,
  layer = "nyc_subway_routes_clean",
  delete_dsn = TRUE,
  quiet = TRUE
)

st_write(
  subway_stops,
  dsn = out_subway_clean,
  layer = "nyc_subway_stops_clean",
  quiet = TRUE
)

st_write(
  ebird_sf,
  dsn = "../../Data/Cleaned/ebird_rock_pigeon_clean.gpkg",
  layer = "ebird_rock_pigeon_clean",
  delete_dsn = TRUE,
  quiet = TRUE
)

#----------------------------------------#
# Confirmation ----
#----------------------------------------#

print(st_crs(pigeon_311))
print(st_crs(nyc_neighborhoods))
print(st_crs(subway_stops))
print(st_crs(ebird_sf))

print(nrow(pigeon_311))
print(nrow(ebird_sf))
