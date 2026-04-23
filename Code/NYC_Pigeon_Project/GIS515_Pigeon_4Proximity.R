###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 4: Proximity Analysis
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

library(sf)
library(dplyr)
library(tmap)

#----------------------------------------#
# Read cleaned data ----
#----------------------------------------#
pigeon_311 <- st_read("../../Data/Cleaned/pigeon_311_unsanitary_preprocessed.gpkg")
pigeon_311 <- st_set_geometry(pigeon_311, "geom")

subway_stops <- st_read("../../Data/Cleaned/nyc_subways_preprocessed.gpkg",
                        layer = "nyc_subway_stops_preprocessed")

nyc_boroughs <- st_read("../../Data/Cleaned/nyc_borough_boundaries_preprocessed.gpkg")

#----------------------------------------#
# Proximity settings ----
#----------------------------------------#
buffer_dist_ft <- 500

#----------------------------------------#
# Nearest-stop assignment ----
#----------------------------------------#

# Nearest stop index for each pigeon complaint
pigeon_311$nearest_stop_i <- st_nearest_feature(pigeon_311, subway_stops)

# Distance to that nearest stop (in CRS units = feet)
pigeon_311$dist_to_stop <- st_distance(
  pigeon_311,
  subway_stops[pigeon_311$nearest_stop_i, ],
  by_element = TRUE
)

# Convert to numeric feet
pigeon_311$dist_to_stop_ft <- as.numeric(pigeon_311$dist_to_stop)

# Keep only complaints within 500 ft of a stop
pigeons_within_buffer <- pigeon_311 %>%
  filter(dist_to_stop_ft <= buffer_dist_ft)

# Add stop_name to each complaint (by nearest stop)
pigeons_within_buffer$stop_name <- subway_stops$stop_name[pigeons_within_buffer$nearest_stop_i]

# Count pigeon complaints per stop
pigeon_counts <- pigeons_within_buffer %>%
  st_drop_geometry() %>%
  group_by(stop_name) %>%
  summarize(pigeon_reports = n()) %>%
  arrange(desc(pigeon_reports))

head(pigeon_counts, 10)

# Join counts back to all stops (0 if none)
subway_pigeon_counts <- subway_stops %>%
  left_join(pigeon_counts, by = "stop_name") %>%
  mutate(pigeon_reports = ifelse(is.na(pigeon_reports), 0, pigeon_reports))

#----------------------------------------#
# Map ----
#----------------------------------------#
tmap_mode("plot")

pigeon_stop_map <-
  tm_shape(nyc_boroughs) +
  tm_polygons(col = "boroname", palette = "gray", border.col = "black") +
  
  tm_shape(subway_pigeon_counts) +
  tm_dots(
    col = "pigeon_reports",
    palette = "Reds",
    size = 0.08,
    title = paste0("Pigeon complaints within ", buffer_dist_ft, " ft")
  ) +
  tm_layout(
    title = paste0("Unsanitary Pigeon Complaints within ", buffer_dist_ft, " ft of Subway Stops"),
    legend.outside = TRUE,
    frame = FALSE
  )

pigeon_stop_map

#tmap_save(
#  pigeon_stop_map,
#  filename = "../../Figures/pigeon_complaints_near_subway_stops.png",
#  width = 2000,
#  dpi = 300
#)

# Top 15 stops
pigeon_counts %>%
  filter(pigeon_reports > 0) %>%
  head(15)