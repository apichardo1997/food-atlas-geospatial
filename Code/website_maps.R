## ------------------------------------------------------
## Generate Interactive Maps for Website
## Elevation tab + Geography tab
## ------------------------------------------------------

rm(list = ls())

library(sf)
library(rnaturalearth)
library(dplyr)
library(data.table)
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(countrycode)

setwd(file.path(Sys.getenv("HOME"),
  "Library/Mobile Documents/com~apple~CloudDocs/0000 BSE/Semester 2/Cas Inf/Project/Geospatial Final Project/Code"))

#--------------------------------------------#
#---- LOAD DATA -----------------------------#
#--------------------------------------------#

data_final_geo <- fread("../Data/Processed/data_final_geo.csv")
food_data      <- fread("../Data/Processed/food_data.csv")

countries_elev <- read_sf("../Data/Processed/countries_elevation.shp")

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  filter(iso_a3 != "ATA") %>%
  st_transform(4326)

#--------------------------------------------#
#---- ELEVATION MAP 1: WEIGHTED ELEVATION ---#
#--------------------------------------------#

# join elevation data to world polygons
elev_data <- countries_elev %>%
  st_drop_geometry() %>%
  select(ISO_A3, wghtd_l) %>%
  filter(!is.na(wghtd_l), !is.na(ISO_A3), ISO_A3 != "-99")

world_elev <- world %>%
  left_join(elev_data, by = c("iso_a3" = "ISO_A3"))

pal_elev <- colorNumeric(
  palette = viridisLite::plasma(100),
  domain = world_elev$wghtd_l,
  na.color = "#cccccc"
)

labels_elev <- sprintf(
  "<strong>%s</strong><br/>Pop-Weighted Elevation: %s m",
  world_elev$name,
  ifelse(is.na(world_elev$wghtd_l), "N/A", round(world_elev$wghtd_l, 0))
) %>% lapply(HTML)

map_elev <- leaflet(world_elev, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_elev(wghtd_l),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.8,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_elev,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal_elev, values = ~wghtd_l,
    title = "Pop-Weighted Elevation (m)",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_elev, "../Website/maps/interactive_elevation_map.html",
           selfcontained = TRUE, title = "Population-Weighted Average Elevation")
cat("Saved: interactive_elevation_map.html\n")

#--------------------------------------------#
#---- ELEVATION MAP 2: AVG SIMILARITY ------#
#--------------------------------------------#

# elevation_similarity is -log(abs(diff)), so higher = more similar
# aggregate to country-level average
avg_elev_sim <- bind_rows(
  data_final_geo %>% filter(year == 2023) %>% select(iso3 = iso3_o, elevation_similarity),
  data_final_geo %>% filter(year == 2023) %>% select(iso3 = iso3_d, elevation_similarity)
) %>%
  filter(!is.na(elevation_similarity), is.finite(elevation_similarity)) %>%
  group_by(iso3) %>%
  summarise(avg_elev_sim = round(mean(elevation_similarity, na.rm = TRUE), 2))

world_elev_sim <- world %>%
  left_join(avg_elev_sim, by = c("iso_a3" = "iso3"))

pal_elev_sim <- colorNumeric(
  palette = viridisLite::inferno(100, begin = 0.15),
  domain = world_elev_sim$avg_elev_sim,
  na.color = "#cccccc"
)

labels_elev_sim <- sprintf(
  "<strong>%s</strong><br/>Avg. Elevation Similarity: %s",
  world_elev_sim$name, world_elev_sim$avg_elev_sim
) %>% lapply(HTML)

map_elev_sim <- leaflet(world_elev_sim, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_elev_sim(avg_elev_sim),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.8,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_elev_sim,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal_elev_sim, values = ~avg_elev_sim,
    title = "Avg. Elevation Similarity",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_elev_sim, "../Website/maps/interactive_elevation_similarity.html",
           selfcontained = TRUE, title = "Average Elevation Similarity by Country")
cat("Saved: interactive_elevation_similarity.html\n")

#--------------------------------------------#
#---- GEOGRAPHY MAP 1: SEAFOOD SHARE -------#
#--------------------------------------------#

seafood_codes <- c(2761, 2762, 2763, 2764, 2765, 2766, 2767)

# food_data uses M49 codes, convert to ISO3
seafood_shares <- food_data %>%
  filter(item_code %in% seafood_codes) %>%
  mutate(iso3 = countrycode(area_code, origin = "un", destination = "iso3c")) %>%
  filter(!is.na(iso3)) %>%
  group_by(iso3) %>%
  summarise(seafood_pct = round(sum(share, na.rm = TRUE) * 100, 1))

world_seafood <- world %>%
  left_join(seafood_shares, by = c("iso_a3" = "iso3"))

pal_seafood <- colorNumeric(
  palette = viridisLite::mako(100, direction = -1),
  domain = world_seafood$seafood_pct,
  na.color = "#cccccc"
)

labels_seafood <- sprintf(
  "<strong>%s</strong><br/>Seafood: %s%% of diet",
  world_seafood$name,
  ifelse(is.na(world_seafood$seafood_pct), "N/A", world_seafood$seafood_pct)
) %>% lapply(HTML)

map_seafood <- leaflet(world_seafood, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_seafood(seafood_pct),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.8,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_seafood,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal_seafood, values = ~seafood_pct,
    title = "Seafood (% of diet)",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_seafood, "../Website/maps/interactive_seafood_share.html",
           selfcontained = TRUE, title = "Seafood Share of Total Diet (2023)")
cat("Saved: interactive_seafood_share.html\n")

#--------------------------------------------#
#---- GEOGRAPHY MAP 2: COASTAL ACCESS ------#
#--------------------------------------------#

# get coastal status per country from the data
coast_data <- data_final_geo %>%
  filter(year == 2023) %>%
  select(iso3 = iso3_o, coastal = coastal_o, dist_coast_km = dist_coast_km_o) %>%
  distinct() %>%
  filter(!is.na(iso3))

world_coast <- world %>%
  left_join(coast_data, by = c("iso_a3" = "iso3"))

# color: coastal = blue shades, landlocked = orange
pal_coast <- colorFactor(
  palette = c("#e34a33", "#3182bd"),
  domain = c(0, 1),
  na.color = "#cccccc"
)

labels_coast <- sprintf(
  "<strong>%s</strong><br/>%s%s",
  world_coast$name,
  ifelse(is.na(world_coast$coastal), "No data",
         ifelse(world_coast$coastal == 1, "Coastal",
                paste0("Landlocked (", round(world_coast$dist_coast_km, 0), " km to coast)"))),
  ""
) %>% lapply(HTML)

map_coast <- leaflet(world_coast, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_coast(coastal),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.7,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_coast,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    colors = c("#3182bd", "#e34a33"),
    labels = c("Coastal", "Landlocked"),
    title = "Coastal Access",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_coast, "../Website/maps/interactive_coastal_access.html",
           selfcontained = TRUE, title = "Coastal Access by Country")
cat("Saved: interactive_coastal_access.html\n")

cat("\n=== ALL WEBSITE MAPS DONE ===\n")
