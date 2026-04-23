###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 3: Mapping
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
library(tmap)       ## static maps

#
# Read Data ----
#

library(sf)
library(tmap)

#----------------------------------------#
# Read CLEANED data ----
#----------------------------------------#

pigeon_311 <- st_read("../../Data/Cleaned/pigeon_311_unsanitary_preprocessed.gpkg")
pigeon_311 <- st_set_geometry(pigeon_311, "geom")  # keep geom as active geometry

nyc_boroughs <- st_read("../../Data/Cleaned/nyc_borough_boundaries_preprocessed.gpkg")

subway_routes <- st_read("../../Data/Cleaned/nyc_subways_preprocessed.gpkg",
                         layer = "nyc_subway_routes_preprocessed")

subway_stops  <- st_read("../../Data/Cleaned/nyc_subways_preprocessed.gpkg",
                         layer = "nyc_subway_stops_preprocessed")

#----------------------------------------#
# (Optional) sanity check CRS ----
#----------------------------------------#
# st_crs(pigeon_311); st_crs(nyc_boroughs); st_crs(subway_routes); st_crs(subway_stops)

#----------------------------------------#
# Map with tmap ----
#----------------------------------------#
tmap_mode("plot")

nyc_map <-
  tm_shape(nyc_boroughs) +
  tm_polygons(
    col = "boroname",
    palette = "Set2",
    border.col = "black",
    lwd = 1,
    title = "NYC Boroughs"
  ) +
  tm_shape(subway_routes) +
  tm_lines(col = "white", lwd = 1, alpha = 0.4) +
  tm_shape(subway_stops) +
  tm_dots(col = "white", size = 0.1, alpha = 0.9) +
  tm_shape(pigeon_311) +
  tm_dots(size = 0.02, col = "black", alpha = 0.35) +
  tm_scale_bar(position = c("right", "bottom")) +
  tm_layout(
    title = "Unsanitary Pigeon Complaints Near NYC Subway Infrastructure",
    title.size = 1.4,
    title.position = c("center", "top"),
    
    legend.outside = TRUE,
    legend.outside.position = "right",
    legend.title.size = 1,
    legend.text.size = 0.8,
    
    frame = FALSE
  )

print(nyc_map)

#----------------------------------------#
# Save map to PNG ----
#----------------------------------------#
dir.create("../../Figures", showWarnings = FALSE)

tmap_save(
  nyc_map,
  filename = "../../Figures/nyc_pigeons_subways_boroughs.png",
  width = 1600,
  dpi = 144
)