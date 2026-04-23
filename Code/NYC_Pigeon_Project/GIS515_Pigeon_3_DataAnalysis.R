###
### GEOG 515: Applied Spatial Data Science
# Project: "Don't Let The Pigeon Drive The... Subway?" ----
### Part 3: Data Analysis
###
### Haley Meyrowitz
### Haley05@UNC.edu
###
### 04/06/2026
###

# Load libraries ----
library(sf)
library(dplyr)
library(tmap)
library(spdep)

# Output folders ----
dir.create("../../Figures", showWarnings = FALSE, recursive = TRUE)
dir.create("../../Outputs", showWarnings = FALSE, recursive = TRUE)

#----------------------------------------#
# 1. Read cleaned data ----
#----------------------------------------#

pigeon_311 <- st_read(
  "../../Data/Cleaned/pigeon_311_clean.gpkg",
  layer = "pigeon_311_clean",
  quiet = TRUE
)

nyc_boroughs <- st_read(
  "../../Data/Cleaned/nyc_borough_boundaries_clean.gpkg",
  layer = "nyc_borough_boundaries_clean",
  quiet = TRUE
)

nyc_neighborhoods <- st_read(
  "../../Data/Cleaned/nyc_neighborhoods_clean.gpkg",
  layer = "nyc_neighborhoods_clean",
  quiet = TRUE
)

subway_routes <- st_read(
  "../../Data/Cleaned/nyc_subways_clean.gpkg",
  layer = "nyc_subway_routes_clean",
  quiet = TRUE
)

subway_stops <- st_read(
  "../../Data/Cleaned/nyc_subways_clean.gpkg",
  layer = "nyc_subway_stops_clean",
  quiet = TRUE
)

ebird_sf <- st_read(
  "../../Data/Cleaned/ebird_rock_pigeon_clean.gpkg",
  layer = "ebird_rock_pigeon_clean",
  quiet = TRUE
)

#----------------------------------------#
# 2. 311 complaints by distance band ----
#----------------------------------------#

complaints_by_band <- pigeon_311 %>%
  st_drop_geometry() %>%
  count(dist_band, name = "complaint_n") %>%
  arrange(factor(dist_band, levels = c("0-500 ft", "500-1000 ft", "1000-2000 ft", "2000+ ft")))

write.csv(
  complaints_by_band,
  "../../Outputs/complaints_by_distance_band.csv",
  row.names = FALSE
)

#----------------------------------------#
# 3. 311 complaints by nearest subway stop ----
#----------------------------------------#

complaints_by_stop <- pigeon_311 %>%
  st_drop_geometry() %>%
  group_by(nearest_stop_uid, nearest_stop_name) %>%
  summarize(complaint_n = n(), .groups = "drop") %>%
  arrange(desc(complaint_n))

subway_stop_counts <- subway_stops %>%
  left_join(complaints_by_stop, by = c("stop_uid" = "nearest_stop_uid")) %>%
  mutate(complaint_n = ifelse(is.na(complaint_n), 0, complaint_n))

write.csv(
  st_drop_geometry(complaints_by_stop),
  "../../Outputs/complaints_by_subway_stop.csv",
  row.names = FALSE
)

#----------------------------------------#
# 4. Neighborhood summaries ----
#----------------------------------------#

# Check which neighborhood name field exists
neighborhood_name_field <- if ("puma_name" %in% names(nyc_neighborhoods)) {
  "puma_name"
} else if ("puma_name" %in% names(nyc_neighborhoods)) {
  "puma_name"
} else {
  stop("No neighborhood name field found in neighborhood layer.")
}

# 311 complaints by neighborhood
neighborhood_311 <- pigeon_311 %>%
  st_drop_geometry() %>%
  count(.data[[neighborhood_name_field]], name = "complaint_n") %>%
  rename(neighborhood = .data[[neighborhood_name_field]])

# eBird observations by neighborhood (Manhattan only)
neighborhood_ebird <- ebird_sf %>%
  st_drop_geometry() %>%
  count(.data[[neighborhood_name_field]], name = "ebird_checklists") %>%
  rename(neighborhood = .data[[neighborhood_name_field]])

neighborhood_ebird_counts <- ebird_sf %>%
  st_drop_geometry() %>%
  group_by(.data[[neighborhood_name_field]]) %>%
  summarize(ebird_pigeon_total = sum(observation_count_use, na.rm = TRUE), .groups = "drop") %>%
  rename(neighborhood = .data[[neighborhood_name_field]])

nyc_neighborhoods_analysis <- nyc_neighborhoods %>%
  mutate(neighborhood = .data[[neighborhood_name_field]]) %>%
  left_join(neighborhood_311, by = "neighborhood") %>%
  left_join(neighborhood_ebird, by = "neighborhood") %>%
  left_join(neighborhood_ebird_counts, by = "neighborhood") %>%
  mutate(
    complaint_n = ifelse(is.na(complaint_n), 0, complaint_n),
    ebird_checklists = ifelse(is.na(ebird_checklists), 0, ebird_checklists),
    ebird_pigeon_total = ifelse(is.na(ebird_pigeon_total), 0, ebird_pigeon_total)
  )

write.csv(
  st_drop_geometry(nyc_neighborhoods_analysis),
  "../../Outputs/neighborhood_summary.csv",
  row.names = FALSE
)

#----------------------------------------#
# 5. Manhattan-only comparison: 311 vs eBird ----
#----------------------------------------#
manhattan_neighborhoods <- nyc_neighborhoods_analysis %>%
  st_filter(ebird_sf, .predicate = st_intersects)

manhattan_compare <- nyc_neighborhoods_analysis %>%
  st_drop_geometry() %>%
  filter(ebird_checklists > 0) %>%   # keeps only Manhattan neighborhoods
  select(neighborhood, complaint_n, ebird_checklists, ebird_pigeon_total)

write.csv(
  manhattan_compare,
  "../../Outputs/manhattan_311_ebird_comparison.csv",
  row.names = FALSE
)

#----------------------------------------#
# 6. Spatial autocorrelation: Moran's I ----
#----------------------------------------#

nb <- poly2nb(nyc_neighborhoods_analysis)
lw <- nb2listw(nb, style = "W", zero.policy = TRUE)

moran_global <- moran.test(
  nyc_neighborhoods_analysis$complaint_n,
  lw,
  zero.policy = TRUE
)

print(moran_global)

local_moran <- localmoran(
  nyc_neighborhoods_analysis$complaint_n,
  lw,
  zero.policy = TRUE
)

nyc_neighborhoods_analysis$local_moran_i <- local_moran[, 1]
nyc_neighborhoods_analysis$local_moran_p <- local_moran[, 5]
nyc_neighborhoods_analysis$local_moran_sig <- ifelse(
  nyc_neighborhoods_analysis$local_moran_p < 0.05,
  "Significant",
  "Not significant"
)

write.csv(
  st_drop_geometry(nyc_neighborhoods_analysis),
  "../../Outputs/neighborhood_summary_with_moran.csv",
  row.names = FALSE
)

#----------------------------------------#
# 7. Maps ----
#----------------------------------------#

tmap_mode("plot")

# Map 1: Raw complaints + subway infrastructure
map_overview <-
  tm_shape(nyc_boroughs) +
  tm_polygons(col = "gray92", border.col = "gray60") +
  tm_shape(subway_routes) +
  tm_lines(col = "gray70", lwd = 0.7, alpha = 0.6) +
  tm_shape(subway_stops) +
  tm_dots(col = "gray30", size = 0.03, alpha = 0.7) +
  tm_shape(pigeon_311) +
  tm_dots(col = "black", size = 0.01, alpha = 0.30) +
  tm_layout(
    title = "NYC 311 Unsanitary Pigeon Complaints and Subway Infrastructure",
    frame = FALSE,
    legend.outside = TRUE
  ) +
  tm_scale_bar(position = c("right", "bottom"))

# Map 2: Complaints assigned to nearest subway stop
map_stops <-
  tm_shape(nyc_boroughs) +
  tm_polygons(col = "gray95", border.col = "gray70") +
  tm_shape(subway_stop_counts) +
  tm_dots(
    col = "complaint_n",
    size = 0.08,
    palette = "Reds",
    title = "311 complaints\nassigned to nearest stop"
  ) +
  tm_layout(
    title = "311 Pigeon Complaints by Nearest Subway Stop",
    frame = FALSE,
    legend.outside = TRUE
  )

# Map 3: Neighborhood complaint counts
map_neighborhoods <-
  tm_shape(nyc_neighborhoods_analysis) +
  tm_polygons(
    col = "complaint_n",
    palette = "Reds",
    border.col = "gray40",
    title = "311 complaints"
  ) +
  tm_layout(
    title = "311 Unsanitary Pigeon Complaints by NYC Neighborhood",
    frame = FALSE,
    legend.outside = TRUE
  )

# Map 4: Local Moran's I statistic
map_local_moran <-
  tm_shape(nyc_neighborhoods_analysis) +
  tm_polygons(
    col = "local_moran_i",
    palette = "PuOr",
    style = "cont",
    border.col = "gray40",
    title = "Local Moran's I"
  ) +
  tm_layout(
    title = "Neighborhood-Level Spatial Autocorrelation of 311 Complaints",
    frame = FALSE,
    legend.outside = TRUE
  )

map_overview
map_stops
map_neighborhoods
map_local_moran
# Save maps

tmap_save(
  map_overview,
  filename = "../../Figures/map_overview_311_subway.png",
  width = 10,
  height = 7,
  dpi = 300
)

tmap_save(
  map_stops,
  filename = "../../Figures/map_subway_stop_counts.png",
  width = 10,
  height = 7,
  dpi = 300
)

tmap_save(
  map_neighborhoods,
  filename = "../../Figures/map_neighborhood_complaints.png",
  width = 10,
  height = 7,
  dpi = 300
)

tmap_save(
  map_local_moran,
  filename = "../../Figures/map_local_moran_complaints.png",
  width = 10,
  height = 7,
  dpi = 300
)

#----------------------------------------#
# 8. Console output for interpretation ----
#----------------------------------------#

print(complaints_by_band)
print(head(complaints_by_stop, 15))
print(cor(manhattan_compare$complaint_n, manhattan_compare$ebird_pigeon_total, use = "complete.obs"))
