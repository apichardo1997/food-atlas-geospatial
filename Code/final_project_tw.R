## ------------------------------------------------------
## Final Project
## ------------------------------------------------------

rm(list = ls())

# ---- Packages ----
#install.packages("arrow")
#install.packages("rnaturalearthdata")
#install.packages("fixest")
#install.packages("viridis")

library(sf)
library(spData)
library(dplyr)
library(tidyr)
library(ggplot2)
library(units)
library(leaflet)
library(fixest)
library(tibble)
library(rnaturalearth)
library(arrow)
library(data.table)
library(viridis)
library(grDevices)
library(htmlwidgets)
# #library(readxl)
# #library(units)
# library(terra)
# library(gdistance)
# library(raster)
# #library(haven)


# Set path to current directory
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))
getwd()

#--------------------------------------------#
#---- GENERATE DATASET - NON-GEOGRAPHICAL ---#
#--------------------------------------------#

### IMPORT ####
food_data_2023 <- fread("data/food_data_2023.csv")
food_data_2010 <- fread("data/food_data_2010.csv")
similarity_2010 <- fread("data/similarity_results_2010.csv")
similarity_2023 <- fread("data/similarity_results_2023.csv")
#gravity_preview <- fread("data/Gravity_csv_V202211/Countries_V202211.csv", nrows = 5)
gravity <- fread("data/Gravity_csv_V202211/Gravity_V202211.csv")[year >= 2010 & year <= 2021]
# BACI trade data:
trade_country <- fread("data/BACI_HS22_V202601/country_codes_V202601.csv")
trade2023 <- fread("data/BACI_HS22_V202601/BACI_HS22_Y2023_V202601.csv")
# World Bank GDP data:
gdp <- fread("data/world_bank_gdp/world_bank_gdp.csv", header=TRUE)

### CLEAN ####

# BACI TRADE #
# merge trade data:
baci <- trade2023 %>%
  left_join(trade_country, by = c("i" = "country_code")) %>%
  rename(iso3_o = country_iso3, country_name_o = country_name, iso2_o = country_iso2) %>%
  left_join(trade_country, by = c("j" = "country_code")) %>%
  rename(iso3_d = country_iso3, country_name_d = country_name, iso2_d = country_iso2)
baci_bilateral <- baci %>%
  group_by(t, iso3_o, iso3_d) %>%
  summarise(trade_value = sum(v, na.rm = TRUE), .groups = "drop") %>% 
  rename("year"="t", "trade_total"="trade_value")

# GRAVITY #
# condensed dataset with only relevant vars:
gravity_filtered <- gravity %>% 
  select(
    year,
    country_id_o, country_id_d,
    iso3_o, iso3_d,
    iso3num_o, iso3num_d,
    comlang_off,
    comrelig,
    col45,
    comcol,
    fta_wto,
    tradeflow_baci,
    scaled_sci_2021,
    dist,
    distcap
  ) %>% 
  # calculate total bilateral trade flows:
  group_by(pmin(iso3_o, iso3_d), pmax(iso3_o, iso3_d)) %>% 
  mutate(trade_total = sum(tradeflow_baci, na.rm = TRUE)) %>% 
  ungroup()

# GDP # 
gdp_clean <- gdp %>% 
  select("Country Code", "2010", "2023")

gdp_long <- gdp_clean %>%
  pivot_longer(
    cols = c("2010", "2023"),
    names_to = "year",
    values_to = "gdp_pc"
  ) %>%
  rename(iso3 = "Country Code") %>%
  mutate(year = as.integer(year))

# FAO FOOD #
similarity_merged <- bind_rows(
  similarity_2010 %>% mutate(year = 2010),
  similarity_2023 %>% mutate(year = 2023)
)
food_merged <- bind_rows(
  food_data_2010 %>% mutate(year = 2010),
  food_data_2023 %>% mutate(year = 2023)
)
# harmonize fao country code with ISO-3
#install.packages("countrycode")
library(countrycode)
similarity_merged <- similarity_merged %>% 
  mutate(iso3_o = countrycode(c1, origin = "un", destination = "iso3c"),
         iso3_d = countrycode(c2, origin = "un", destination = "iso3c")) %>% 
  rename("m49_1" = "c1", "m49_2"="c2")

food_merged <- food_merged %>% 
  mutate(iso3c = countrycode(area_code, origin = "un", destination = "iso3c"))

### FINAL MERGE ###

# gravity controls from 2021 only, with _2021 suffix
gravity_controls <- gravity %>%
  filter(year == 2021, country_exists_o==1, country_exists_d==1) %>% # drop countries that dont exist anymore
  select(iso3_o, iso3_d, comlang_off, comrelig, col45, comcol, fta_wto,
         scaled_sci_2021, dist, distcap) %>%
  rename_with(~ paste0(., "_2021"), -c(iso3_o, iso3_d, scaled_sci_2021))

# Trade from gravity for 2010
trade_2010 <- gravity %>% 
  filter(year == 2010) %>%
  select(iso3_o, iso3_d, tradeflow_baci) %>%
  group_by(iso3_o, iso3_d) %>%
  summarise(
    trade_total = sum(tradeflow_baci, na.rm = TRUE),
    .groups = "drop"
  )

# 2010 dataset
data_2010 <- similarity_merged %>%
  filter(year == 2010) %>%
  left_join(trade_2010,
            by = c("iso3_o", "iso3_d")) %>% 
  left_join(gravity_controls, by = c("iso3_o", "iso3_d")) %>%
  mutate(year = 2010)

# 2023 dataset
data_2023 <- similarity_merged %>%
  filter(year == 2023) %>%
  left_join(baci_bilateral %>% filter(year == 2023),
            by = c("iso3_o", "iso3_d", "year")) %>%
  left_join(gravity_controls, by = c("iso3_o", "iso3_d")) %>%
  mutate(year = 2023)

# bind into long format
data_final <- bind_rows(data_2010, data_2023) %>% 
  left_join(gdp_long, by = c("iso3_o" = "iso3", "year")) %>%
  rename(gdp_pc_o = gdp_pc) %>%
  left_join(gdp_long, by = c("iso3_d" = "iso3", "year")) %>%
  rename(gdp_pc_d = gdp_pc)

head(data_final)
data_final %>%
  summarise(missing_gdp = sum(is.na(gdp_pc_o) | is.na(gdp_pc_d)))
# 1765 rows missing - thats 8% so i guess ok

# calculate gdp diff
data_final <- data_final %>% 
  mutate(gdp_pc_diff = abs(gdp_pc_o - gdp_pc_d))

fwrite(data_final, "data/data_final.csv")

#--------------------------------------------#
#----- GENERATE DATASET - GEOGRAPHICAL ------#
#--------------------------------------------#

data_final <- fread("data/data_final.csv")

world_main <- ne_countries(scale = "medium", returnclass = "sf")
# populated places
cities_main <- ne_download(
  scale = "medium",
  type = "populated_places",
  category = "cultural",
  returnclass = "sf"
)
# rename vars to lowercase:
cities <- cities_main %>%
  rename_with(tolower)
coastline_main <- ne_download(
  scale = "medium",
  type = "coastline",
  category = "physical",
  returnclass = "sf"
)
### CENTROID DISTANCE ###

# keep only countries with valid ISO3
 world <- world_main %>%
  filter(!is.na(adm0_a3), adm0_a3 != "-99") %>%
  select(adm0_a3, geometry) %>% 
  group_by(adm0_a3) %>%
  summarise(geometry = st_union(geometry), .groups = "drop") %>%
  st_make_valid()

# better than centroid for weird polygons
world_pts <- st_point_on_surface(world)

# compute distances
dist_matrix <- st_distance(world_pts)

# convert to numeric km matrix
dist_matrix <- set_units(dist_matrix, "km")
dist_matrix <- drop_units(dist_matrix)

# explicitly assign ISO3 names to rows and columns
rownames(dist_matrix) <- world$adm0_a3
colnames(dist_matrix) <- world$adm0_a3

# reshape to long
dist_df <- as.data.frame(dist_matrix) %>%
  rownames_to_column("iso3_o") %>%
  pivot_longer(
    cols = -iso3_o,
    names_to = "iso3_d",
    values_to = "dist_km"
  ) %>%
  filter(iso3_o != iso3_d)

### POPULATION WEIGHTED CENTROID ###

# compute weighted centroid
coords <- st_coordinates(cities)

pop_centroids <- cities %>%
  mutate(
    x = coords[, 1],
    y = coords[, 2]
  ) %>%
  st_drop_geometry() %>%
  filter(!is.na(adm0_a3), adm0_a3 != "-99") %>% 
  filter(!is.na(pop_max)) %>% 
  group_by(adm0_a3) %>%
  summarise(
    x = weighted.mean(x, pop_max, na.rm = TRUE),
    y = weighted.mean(y, pop_max, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  st_as_sf(coords = c("x", "y"), crs = 4326)

# compute distances
pop_dist_matrix <- st_distance(pop_centroids)

# convert to numeric km matrix
pop_dist_matrix <- set_units(pop_dist_matrix, "km")
pop_dist_matrix <- drop_units(pop_dist_matrix)

# explicitly assign ISO3 names to rows and columns
rownames(pop_dist_matrix) <- pop_centroids$adm0_a3
colnames(pop_dist_matrix) <- pop_centroids$adm0_a3

# reshape to long
pop_dist_df <- as.data.frame(pop_dist_matrix) %>%
  rownames_to_column("iso3_o") %>%
  pivot_longer(
    cols = -iso3_o,
    names_to = "iso3_d",
    values_to = "pop_dist_km"
  ) %>%
  filter(iso3_o != iso3_d)

# look at only europe for sanity check
europe <- world_main %>%
  filter(continent == "Europe")

europe_centroids <- pop_centroids %>%
  semi_join(europe %>% st_drop_geometry(), by = "adm0_a3")

ggplot() +
  geom_sf(data = europe, fill = "gray90", color = "white", linewidth = 0.2) +
  geom_sf(data = europe_centroids, color = "red", size = 1) +
  #geom_sf(data = label_pts, color = "blue", size = 1) +
  geom_text(
    data = cbind(europe_centroids, st_coordinates(europe_centroids)),
    aes(X, Y, label = adm0_a3),
    size = 2,
    nudge_y = 0.8
  ) +
  coord_sf(
    xlim = c(-12, 40),
    ylim = c(35, 72),
    expand = FALSE
  ) +
  theme_minimal()

### SHARED BORDERS ###

# adjacency matrix: TRUE if polygons share a border
border_mat <- st_touches(world, sparse = FALSE)

# assign ISO3 names
dimnames(border_mat) <- list(world$adm0_a3, world$adm0_a3)

# convert to long
border_df <- as.data.frame(border_mat) %>%
  rownames_to_column("iso3_o") %>%
  pivot_longer(
    cols = -iso3_o,
    names_to = "iso3_d",
    values_to = "shared_border"
  ) %>%
  mutate(shared_border = as.integer(shared_border)) %>%
  filter(iso3_o != iso3_d)

### DISTANCE / ACCESS TO COAST ###

# make sure geometries are valid and use same CRS
world_coast <- world %>%
  st_transform(4326)

coastline_coast <- coastline_main %>%
  st_make_valid() %>%
  st_transform(4326)

# combine all coastline segments into one geometry
coast_union <- st_union(coastline_coast)

# 1 = country touches coastline, 0 = no access
coastal_dummy <- lengths(st_intersects(world_coast, coast_union)) > 0

# shortest distance from country polygon to coastline
# for coastal countries this should be 0
dist_to_coast <- st_distance(world_coast, coast_union)

coast_df <- world_coast %>%
  st_drop_geometry() %>%
  mutate(
    iso3 = adm0_a3,
    coastal = as.integer(coastal_dummy),
    dist_coast_km = as.numeric(set_units(dist_to_coast, "km"))
  ) %>%
  select(iso3, coastal, dist_coast_km)
# make sure distance to coast is 0 for coastal countries
coast_df <- coast_df %>%
  mutate(
    dist_coast_km = if_else(coastal==1, 0, dist_coast_km)
  )

# quick check
coast_df %>%
  arrange(desc(coastal), dist_coast_km) %>%
  head()

coast_df %>%
  filter(coastal == 0) %>%
  arrange(dist_coast_km) %>%
  head(20)


### FINAL MERGE ###

# merge with final data
data_final_geo <- data_final %>%
  # distance between points on surface
  left_join(dist_df, by = c("iso3_o", "iso3_d")) %>% 
  mutate(log_dist_centroid = log(dist_km)) %>% 
  # distance between population-weighted centroids
  left_join(pop_dist_df, by = c("iso3_o", "iso3_d")) %>% 
  mutate(log_dist_pop_centroid = log(pop_dist_km)) %>%  
  # shared border
  left_join(border_df, by = c("iso3_o", "iso3_d")) %>%
  mutate(shared_border = replace_na(shared_border, 0)) %>% 
  # coastal, distance to coastline
  left_join(coast_df, by = c("iso3_o" = "iso3")) %>%
  rename(
    coastal_o = coastal,
    dist_coast_km_o = dist_coast_km
  ) %>%
  left_join(coast_df, by = c("iso3_d" = "iso3")) %>%
  rename(
    coastal_d = coastal,
    dist_coast_km_d = dist_coast_km
  ) %>% 
  mutate(diff_dist_coast_km = abs(dist_coast_km_o - dist_coast_km_d))
  
# check with well-known cases
data_final_geo %>%
  filter((iso3_o == "DEU" & iso3_d == "LUX") |
           (iso3_o == "DEU" & iso3_d == "FRA") |
           (iso3_o == "FRA" & iso3_d == "ESP")) %>%
  select(iso3_o, iso3_d, coastal_o, coastal_d, dist_coast_km_o, dist_coast_km_d)

fwrite(data_final_geo, "data/data_final_geo")

#--------------------------------------------#
#-------------- REGRESSION ------------------#
#--------------------------------------------#

reg_data <- data_final_geo %>%
  mutate(
    trade_total = replace_na(trade_total, 0),
    log_trade = log1p(trade_total),
    log_dist = log(dist_2021),
    log_dist_geo  = log(dist_km), 
    log_pop_dist  = log(pop_dist_km), 
    log_gdp_diff = log(gdp_pc_diff),
    log_diff_dist_coast_km = log1p(diff_dist_coast_km)
  )

# 2010 no country-fixed effects
m2010 <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021,
  data = reg_data %>% filter(year == 2010),
  vcov = ~ iso3_o + iso3_d
)

# 2023 no country-fixed effects
m2023 <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021,
  data = reg_data %>% filter(year == 2023),
  vcov = ~ iso3_o + iso3_d
)


# 2010 with country-fixed effects
m2010_fe <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021| iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2010),
  vcov = ~ iso3_o + iso3_d
)

# 2023 with country-fixed effects
m2023_fe <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2023),
  vcov = ~ iso3_o + iso3_d
)

# 2010 with country-fixed effects with gdp
m2010_fe_gdp <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_gdp_diff + log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2010),
  vcov = ~ iso3_o + iso3_d
)

# 2023 with country-fixed effects with gdp
m2023_fe_gdp <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    log_gdp_diff + log_trade + fta_wto_2021 +
    comlang_off_2021 + comrelig_2021 + comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2023),
  vcov = ~ iso3_o + iso3_d
)

# Compare Results
etable(m2010, m2023, m2010_fe, m2023_fe, m2010_fe_gdp, m2023_fe_gdp, fitstat = ~ n + r2)


#--------------------------------------------#
#--------- VISUALIZATIONS - MAPS ------------#
#--------------------------------------------#

### STATIC: WORLD MAP OF FOOD SIMILARITY ###

# aggregate to country level (average similarity across all pairs)
similarity_map <- data_final_geo %>%
  group_by(iso3_o, year) %>%
  summarise(mean_similarity = mean(similarity, na.rm = TRUE), .groups = "drop")

world_map <- ne_countries(scale = "medium", returnclass = "sf") %>%
  select(adm0_a3, geometry)

map_data <- world_map %>%
  left_join(similarity_map, by = c("adm0_a3" = "iso3_o"))

plot_data <- map_data %>%
  filter(year %in% c(2010, 2023))

ggplot(data = plot_data) +
  # background: all countries, repeated in each facet
  geom_sf(
    data = world_map,
    fill = "grey80",
    color = "white",
    linewidth = 0.1,
    inherit.aes = FALSE
  ) +
  # overlay: only countries that have similarity values
  geom_sf(
    aes(fill = mean_similarity),
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "grey80",
    name = "Avg. Food\nSimilarity"
  ) +
  facet_wrap(~ year) +
  labs(
    title = "Average Food Similarity by Country: 2010 vs 2023",
    caption = "Source: Own calculations"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")


### INTERACTIVE: WORLD MAP OF FOOD SIMILARITY ###

# repeat all countries for both years
world_panel <- bind_rows(
  world_main %>% select(adm0_a3, geometry) %>% mutate(year = 2010),
  world_main %>% select(adm0_a3, geometry) %>% mutate(year = 2023)
)

# join average similarity by country and year
map_avg_leaflet <- world_panel %>%
  left_join(similarity_map, by = c("adm0_a3" = "iso3_o", "year" = "year")) %>%
  st_transform(4326) %>%
  mutate(
    hover_label = paste0(
      adm0_a3, ": ",
      ifelse(is.na(mean_similarity), "NA", paste0(round(mean_similarity, 1), "%"))
    )
  )

sim_range <- map_avg_leaflet %>%
  filter(!is.na(mean_similarity)) %>%
  summarise(
    min_sim = min(mean_similarity),
    max_sim = max(mean_similarity)
  )

pal <- colorNumeric(
  palette = "plasma",
  domain = c(sim_range$min_sim, sim_range$max_sim),
  na.color = "grey"
)

avg_similarity_leaflet <- leaflet(map_avg_leaflet) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    data = dplyr::filter(map_avg_leaflet, year == 2010),
    fillColor = ~ pal(mean_similarity),
    fillOpacity = 0.8,
    color = "white",
    weight = 0.5,
    group = "2010",
    highlight = highlightOptions(
      weight = 2,
      color = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = ~ hover_label,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px",
      direction = "auto"
    )
  ) %>%
  addPolygons(
    data = dplyr::filter(map_avg_leaflet, year == 2023),
    fillColor = ~ pal(mean_similarity),
    fillOpacity = 0.8,
    color = "white",
    weight = 0.5,
    group = "2023",
    highlight = highlightOptions(
      weight = 2,
      color = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = ~ hover_label,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px",
      direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal,
    values = map_avg_leaflet$mean_similarity[!is.na(map_avg_leaflet$mean_similarity)],
    title = "Avg. Food Similarity (%)",
    position = "bottomright",
    na.label = "No data",
    opacity = 0.8
  ) %>%
  addLayersControl(
    baseGroups = c("2010", "2023"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  setView(lng = 0, lat = 20, zoom = 2)

# Save as html object:
saveWidget(
  avg_similarity_leaflet,  
  file = "output/average_similarity_map.html",
  selfcontained = TRUE
)

### STATIC: WORLD MAP OF FOOD SIMILARITY TO CHINA ###

# similarity to China only
china_similarity <- similarity_merged %>%
  filter(year %in% c(2010, 2023),
         iso3_o == "CHN" | iso3_d == "CHN") %>%
  mutate(
    iso3 = if_else(iso3_o == "CHN", iso3_d, iso3_o)
  ) %>%
  select(iso3, year, similarity)

# add China itself
china_similarity <- bind_rows(
  china_similarity,
  tibble(
    iso3 = "CHN",
    year = c(2010, 2023),
    similarity = 100
  )
)

world_map <- ne_countries(scale = "medium", returnclass = "sf") %>%
  select(adm0_a3, geometry)

map_china <- world_map %>%
  left_join(china_similarity, by = c("adm0_a3" = "iso3")) %>%
  filter(year %in% c(2010, 2023))

plot_data <- map_china

world_map_bg <- bind_rows(
  world_map %>% mutate(year = 2010),
  world_map %>% mutate(year = 2023)
)

# max among non-China countries only
non_china_max <- plot_data %>%
  filter(adm0_a3 != "CHN", !is.na(similarity)) %>%
  summarise(max_sim = max(similarity)) %>%
  pull(max_sim)

ggplot() +
  geom_sf(
    data = world_map_bg,
    fill = "grey80",
    color = "white",
    linewidth = 0.1,
    inherit.aes = FALSE
  ) +
  geom_sf(
    data = plot_data,
    aes(fill = similarity),
    color = "white",
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    option = "plasma",
    limits = c(0, non_china_max),
    oob = scales::squish,
    na.value = "grey80",
    name = "Similarity\nto China"
  ) +
  facet_wrap(~ year) +
  labs(
    title = "Food Similarity to China: 2010 vs 2023",
    caption = "Source: Own calculations"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")


### INTERACTIVE: SIMILARITY TO CHINA ###

# repeat all countries for both years
world_panel <- bind_rows(
  world_main %>% select(adm0_a3, geometry) %>% mutate(year = 2010),
  world_main %>% select(adm0_a3, geometry) %>% mutate(year = 2023)
)

# join by country and year
map_china_leaflet <- world_panel %>%
  left_join(china_similarity, by = c("adm0_a3" = "iso3", "year" = "year")) %>% 
  st_transform(4326) %>%
  mutate(
    hover_label = paste0(
      adm0_a3, ": ",
      ifelse(is.na(similarity), "NA", paste0(round(similarity, 1), "%"))
    )
  )

non_china_range <- map_china_leaflet %>%
  filter(adm0_a3 != "CHN", !is.na(similarity)) %>%
  summarise(
    min_sim = min(similarity),
    max_sim = max(similarity)
  )

pal <- colorNumeric(
  palette = "plasma",
  domain = c(non_china_range$min_sim, non_china_range$max_sim),
  na.color = "grey"
)

china_similarity_leaflet <- leaflet(map_china_leaflet) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    data = dplyr::filter(map_china_leaflet, year == 2010),
    fillColor = ~ ifelse(adm0_a3 == "CHN", "pink", pal(similarity)),
    fillOpacity = 0.8,
    color = "white",
    weight = 0.5,
    group = "2010",
    highlight = highlightOptions(
      weight = 2,
      color = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = ~ hover_label,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px",
      direction = "auto"
    )
  ) %>%
  addPolygons(
    data = dplyr::filter(map_china_leaflet, year == 2023),
    fillColor = ~ ifelse(adm0_a3 == "CHN", "#222222", pal(similarity)),
    fillOpacity = 0.8,
    color = "white",
    weight = 0.5,
    group = "2023",
    highlight = highlightOptions(
      weight = 2,
      color = "#666",
      fillOpacity = 0.9,
      bringToFront = TRUE
    ),
    label = ~ hover_label,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "13px",
      direction = "auto"
    )
  ) %>%
  addLegend(
    pal = pal,
    values = map_china_leaflet$similarity[
      map_china_leaflet$adm0_a3 != "CHN" & !is.na(map_china_leaflet$similarity)
    ],
    title = "Similarity to China (%)",
    position = "bottomright",
    na.label = "No data",
    opacity = 0.8
  ) %>%
  addLayersControl(
    baseGroups = c("2010", "2023"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  setView(lng = 100, lat = 30, zoom = 2)

# Save as html object:
saveWidget(
  china_similarity_leaflet,  
  file = "output/similarity_to_china_map.html",
  selfcontained = TRUE
)

### STATIC MAP: SEAFOOD SHARE IN DIET ###

seafood_codes <- c(2761, 2762, 2763, 2764, 2765, 2766, 2767)

seafood_shares <- food_merged %>%
  filter(item_code %in% seafood_codes) %>%
  group_by(iso3c) %>%
  summarise(seafood_share = sum(share, na.rm = TRUE), .groups = "drop")

map_seafood <- world_main %>%
  select(adm0_a3, geometry) %>%
  left_join(seafood_shares, by = c("adm0_a3" = "iso3c"))

ggplot(map_seafood) +
  geom_sf(aes(fill = seafood_share * 100), color = "white", linewidth = 0.1) +
  scale_fill_viridis_c(option = "mako", na.value = "grey80",
                       name = "Seafood Share\n(% of diet)",
                       trans = "sqrt") +
  labs(title = "Seafood Share of Total Diet (2023)",
       subtitle = "Share of total caloric intake from seafood products",
       caption = "Source: FAO Food Balance Sheets") +
  theme_minimal() +
  theme(legend.position = "right")


#--------------------------------------------#
#--------- VISUALIZATIONS - OTHER -----------#
#--------------------------------------------#

### 2. DISTRIBUTION OF FOOD SIMILARITY ###

ggplot(data_final_geo, aes(x = similarity, fill = factor(year), color = factor(year))) +
  geom_density(alpha = 0.4) +
  scale_fill_manual(values = c("2010" = "#2166ac", "2023" = "#d6604d"),
                    name = "Year") +
  scale_color_manual(values = c("2010" = "#2166ac", "2023" = "#d6604d"),
                     name = "Year") +
  labs(title = "Distribution of Pairwise Food Similarity",
       x = "Food Similarity",
       y = "Density",
       caption = "Source: Own calculations") +
  theme_minimal()

# by subcategory
data_final_geo %>%
  select(year, sim_meat, sim_starch, sim_fv) %>%
  pivot_longer(cols = -year, names_to = "category", values_to = "similarity") %>%
  mutate(category = recode(category,
                           sim_meat = "Meat",
                           sim_starch = "Starch",
                           sim_fv = "Fruits & Vegetables")) %>%
  ggplot(aes(x = similarity, fill = factor(year), color = factor(year))) +
  geom_density(alpha = 0.4) +
  scale_fill_manual(values = c("2010" = "#2166ac", "2023" = "#d6604d"), name = "Year") +
  scale_color_manual(values = c("2010" = "#2166ac", "2023" = "#d6604d"), name = "Year") +
  facet_wrap(~ category) +
  labs(title = "Distribution of Food Similarity by Category",
       x = "Similarity", y = "Density",
       caption = "Source: Own calculations") +
  theme_minimal()