## ------------------------------------------------------
## Climate Similarity - Interactive Maps (Leaflet)
## ------------------------------------------------------

rm(list = ls())

# ---- Packages ----
library(sf)
library(rnaturalearth)
library(dplyr)
library(data.table)
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(RColorBrewer)

# Set path to current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#--------------------------------------------#
#---- LOAD DATA -----------------------------#
#--------------------------------------------#

climate_similarity <- fread("../Data/Processed/climate_similarity.csv")
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  filter(iso_a3 != "ATA")  # drop antarctica

# make sure its in WGS84 for leaflet
world <- st_transform(world, 4326)

#--------------------------------------------#
#---- MAP 1: AVG CLIMATE SIMILARITY ---------#
#--------------------------------------------#

# average climate similarity per country
avg_sim <- bind_rows(
  climate_similarity %>% select(iso3 = iso3_1, climate_similarity),
  climate_similarity %>% select(iso3 = iso3_2, climate_similarity)
) %>%
  group_by(iso3) %>%
  summarise(avg_climate_sim = round(mean(climate_similarity, na.rm = TRUE), 1))

world_avg <- world %>%
  left_join(avg_sim, by = c("iso_a3" = "iso3"))

# color palette (matching our static maps)
pal_avg <- colorNumeric(
  palette = viridisLite::inferno(100, begin = 0.15),
  domain = world_avg$avg_climate_sim,
  na.color = "#cccccc"
)

# hover labels
labels_avg <- sprintf(
  "<strong>%s</strong><br/>Avg. Climate Similarity: %s",
  world_avg$name, world_avg$avg_climate_sim
) %>% lapply(HTML)

map_avg <- leaflet(world_avg, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_avg(avg_climate_sim),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.8,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_avg,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal_avg, values = ~avg_climate_sim,
    title = "Avg. Climate Similarity (%)",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_avg, "../Maps/Interactive/interactive_avg_climate_similarity.html",
           selfcontained = TRUE, title = "Average Climate Similarity by Country")

#--------------------------------------------#
#---- MAP 2: BILATERAL FROM SPAIN -----------#
#--------------------------------------------#

spain_sim <- climate_similarity %>%
  filter(iso3_1 == "ESP" | iso3_2 == "ESP") %>%
  mutate(
    partner = ifelse(iso3_1 == "ESP", iso3_2, iso3_1),
    climate_similarity = round(climate_similarity, 1)
  ) %>%
  select(partner, climate_similarity)
spain_sim <- bind_rows(spain_sim, data.frame(partner = "ESP", climate_similarity = 100))

world_spain <- world %>%
  left_join(spain_sim, by = c("iso_a3" = "partner"))

pal_spain <- colorNumeric(
  palette = viridisLite::inferno(100, begin = 0.15),
  domain = c(0, 100),
  na.color = "#cccccc"
)

labels_spain <- sprintf(
  "<strong>%s</strong><br/>Climate Similarity to Spain: %s%%",
  world_spain$name, world_spain$climate_similarity
) %>% lapply(HTML)

map_spain <- leaflet(world_spain, options = leafletOptions(minZoom = 2)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal_spain(climate_similarity),
    weight = 0.5,
    color = "#666666",
    fillOpacity = 0.8,
    highlightOptions = highlightOptions(
      weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
    ),
    label = labels_spain,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px", direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal_spain, values = c(0, 100),
    title = "Climate Similarity to Spain (%)",
    position = "bottomright", opacity = 0.8
  ) %>%
  setView(lng = 20, lat = 20, zoom = 2)

saveWidget(map_spain, "../Maps/Interactive/interactive_spain_climate_similarity.html",
           selfcontained = TRUE, title = "Climate Similarity to Spain")

#--------------------------------------------#
#---- MAP 3: COUNTRY PICKER (ALL-IN-ONE) ----#
#--------------------------------------------#

# this one lets you pick any country and see its similarity to everyone
# we precompute all countries and build a dropdown

# get list of all countries in our data
all_countries <- sort(unique(c(climate_similarity$iso3_1, climate_similarity$iso3_2)))

# function to make a map for any country
make_interactive_map <- function(country_iso) {
  sim <- climate_similarity %>%
    filter(iso3_1 == country_iso | iso3_2 == country_iso) %>%
    mutate(
      partner = ifelse(iso3_1 == country_iso, iso3_2, iso3_1),
      climate_similarity = round(climate_similarity, 1)
    ) %>%
    select(partner, climate_similarity)
  sim <- bind_rows(sim, data.frame(partner = country_iso, climate_similarity = 100))

  world_map <- world %>%
    left_join(sim, by = c("iso_a3" = "partner"))

  country_name <- world_map %>%
    filter(iso_a3 == country_iso) %>%
    pull(name) %>%
    first()

  pal <- colorNumeric(
    palette = viridisLite::inferno(100, begin = 0.15),
    domain = c(0, 100),
    na.color = "#cccccc"
  )

  labels <- sprintf(
    "<strong>%s</strong><br/>Climate Similarity to %s: %s%%",
    world_map$name, country_name, world_map$climate_similarity
  ) %>% lapply(HTML)

  leaflet(world_map, options = leafletOptions(minZoom = 2)) %>%
    addProviderTiles(providers$CartoDB.Positron) %>%
    addPolygons(
      fillColor = ~pal(climate_similarity),
      weight = 0.5, color = "#666666", fillOpacity = 0.8,
      highlightOptions = highlightOptions(
        weight = 2, color = "#333333", fillOpacity = 0.9, bringToFront = TRUE
      ),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "13px", direction = "auto"
      )
    ) %>%
    addLegend(
      pal = pal, values = c(0, 100),
      title = paste0("Climate Similarity to ", country_name, " (%)"),
      position = "bottomright", opacity = 0.8
    ) %>%
    setView(lng = 20, lat = 20, zoom = 2)
}

# generate maps for a few interesting countries
interesting <- c("ESP", "JPN", "BRA", "USA", "NGA", "AUS", "IND", "DEU")

for (iso in interesting) {
  country_name <- world %>% filter(iso_a3 == iso) %>% pull(name) %>% first()
  m <- make_interactive_map(iso)
  filename <- paste0("../Maps/Interactive/interactive_", tolower(iso), "_climate_similarity.html")
  saveWidget(m, filename, selfcontained = TRUE,
             title = paste("Climate Similarity to", country_name))
  cat("Saved:", filename, "\n")
}

cat("\n=== ALL INTERACTIVE MAPS DONE ===\n")
