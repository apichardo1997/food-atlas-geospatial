## ------------------------------------------------------
## Climate Similarity - Maps & Visualizations
## ------------------------------------------------------

rm(list = ls())

# ---- Packages ----
library(terra)
library(sf)
library(rnaturalearth)
library(dplyr)
library(tidyr)
library(data.table)
library(ggplot2)
library(viridis)
library(patchwork)
library(countrycode)

# Set path to current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#--------------------------------------------#
#---- LOAD DATA -----------------------------#
#--------------------------------------------#

climate_similarity <- fread("../Data/Processed/climate_similarity.csv")
world <- ne_countries(scale = "medium", returnclass = "sf")

# fix world for plotting (remove antarctica, crop to standard view)
world_plot <- world %>%
  filter(iso_a3 != "ATA") %>%
  st_transform(crs = "+proj=robin")  # robinson projection looks nice

#--------------------------------------------#
#---- MAP 1: AVG CLIMATE SIMILARITY ---------#
#--------------------------------------------#

# average climate similarity per country (across all partners)
avg_sim <- bind_rows(
  climate_similarity %>% select(iso3 = iso3_1, climate_similarity),
  climate_similarity %>% select(iso3 = iso3_2, climate_similarity)
) %>%
  group_by(iso3) %>%
  summarise(avg_climate_sim = mean(climate_similarity, na.rm = TRUE))

# merge with world map
world_avg <- world_plot %>%
  left_join(avg_sim, by = c("iso_a3" = "iso3"))

p1 <- ggplot(world_avg) +
  geom_sf(aes(fill = avg_climate_sim), color = "grey30", linewidth = 0.1) +
  scale_fill_viridis_c(
    option = "magma",
    na.value = "grey90",
    name = "Avg. Climate\nSimilarity",
    breaks = seq(10, 50, 10)
  ) +
  labs(
    title = "Average Climate Similarity by Country",
    subtitle = "How climatically similar is each country to the rest of the world (0-100 scale)",
    caption = "Source: Koppen-Geiger classification (Beck et al., 2023). Own calculations."
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5, margin = margin(b = 10)),
    plot.caption = element_text(size = 7, color = "grey50", hjust = 1),
    legend.position = "bottom",
    legend.key.width = unit(2, "cm"),
    legend.key.height = unit(0.3, "cm"),
    legend.title = element_text(size = 9),
    plot.margin = margin(10, 10, 10, 10)
  )

ggsave("../Maps/Static/map_avg_climate_similarity.png", p1, width = 14, height = 8, dpi = 300, bg = "white")

#--------------------------------------------#
#---- MAP 2: BILATERAL FROM SPAIN -----------#
#--------------------------------------------#

# show climate similarity of every country relative to spain
spain_sim <- climate_similarity %>%
  filter(iso3_1 == "ESP" | iso3_2 == "ESP") %>%
  mutate(partner = ifelse(iso3_1 == "ESP", iso3_2, iso3_1)) %>%
  select(partner, climate_similarity)

# add spain itself as 100
spain_sim <- bind_rows(spain_sim, data.frame(partner = "ESP", climate_similarity = 100))

world_spain <- world_plot %>%
  left_join(spain_sim, by = c("iso_a3" = "partner"))

p2 <- ggplot(world_spain) +
  geom_sf(aes(fill = climate_similarity), color = "grey30", linewidth = 0.1) +
  scale_fill_viridis_c(
    option = "inferno",
    na.value = "grey90",
    name = "Climate\nSimilarity\nto Spain",
    limits = c(0, 100)
  ) +
  labs(
    title = "Climate Similarity to Spain",
    subtitle = "Overlap in Koppen-Geiger climate zone distributions (0 = completely different, 100 = identical)",
    caption = "Source: Koppen-Geiger classification (Beck et al., 2023). Own calculations."
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5, margin = margin(b = 10)),
    plot.caption = element_text(size = 7, color = "grey50", hjust = 1),
    legend.position = "bottom",
    legend.key.width = unit(2, "cm"),
    legend.key.height = unit(0.3, "cm"),
    legend.title = element_text(size = 9),
    plot.margin = margin(10, 10, 10, 10)
  )

ggsave("../Maps/Static/map_spain_climate_similarity.png", p2, width = 14, height = 8, dpi = 300, bg = "white")

#--------------------------------------------#
#---- MAP 3: KOPPEN CLIMATE ZONES -----------#
#--------------------------------------------#

koppen_raster <- rast("../Data/Raw/1991_2020/koppen_geiger_0p1.tif")

# convert raster to data frame for ggplot
koppen_df <- as.data.frame(koppen_raster, xy = TRUE)
names(koppen_df) <- c("x", "y", "zone")
koppen_df <- koppen_df %>% filter(zone > 0)  # drop ocean

# koppen zone labels and colors (official Beck et al. colors)
koppen_info <- data.frame(
  zone = 1:30,
  label = c("Af","Am","Aw","BWh","BWk","BSh","BSk","Csa","Csb","Csc",
            "Cwa","Cwb","Cwc","Cfa","Cfb","Cfc","Dsa","Dsb","Dsc","Dsd",
            "Dwa","Dwb","Dwc","Dwd","Dfa","Dfb","Dfc","Dfd","ET","EF"),
  group = c(rep("Tropical", 3), rep("Arid", 4), rep("Temperate", 9),
            rep("Cold", 12), rep("Polar", 2))
)

# simplified color palette by major group
group_colors <- c(
  "Tropical" = "#0000FF",
  "Arid" = "#FF0000",
  "Temperate" = "#FFFF00",
  "Cold" = "#00FFFF",
  "Polar" = "#B2B2B2"
)

koppen_df <- koppen_df %>%
  left_join(koppen_info, by = "zone")

p3 <- ggplot(koppen_df) +
  geom_raster(aes(x = x, y = y, fill = group)) +
  scale_fill_manual(
    values = group_colors,
    name = "Climate Group"
  ) +
  coord_fixed(ratio = 1) +
  labs(
    title = "Koppen-Geiger Climate Classification",
    subtitle = "Major climate groups (1991-2020)",
    caption = "Source: Beck et al. (2023), 0.1° resolution."
  ) +
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5, margin = margin(b = 10)),
    plot.caption = element_text(size = 7, color = "grey50", hjust = 1),
    legend.position = "bottom",
    legend.title = element_text(size = 9),
    plot.margin = margin(10, 10, 10, 10),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave("../Maps/Static/map_koppen_zones.png", p3, width = 14, height = 7, dpi = 300, bg = "white")

#--------------------------------------------#
#---- MAP 4: TOP 3 BILATERAL COMPARISONS ---#
#--------------------------------------------#

# 3 interesting countries side by side: spain, japan, brazil
make_bilateral_map <- function(country_iso, country_name) {
  sim <- climate_similarity %>%
    filter(iso3_1 == country_iso | iso3_2 == country_iso) %>%
    mutate(partner = ifelse(iso3_1 == country_iso, iso3_2, iso3_1)) %>%
    select(partner, climate_similarity)
  sim <- bind_rows(sim, data.frame(partner = country_iso, climate_similarity = 100))

  world_map <- world_plot %>%
    left_join(sim, by = c("iso_a3" = "partner"))

  ggplot(world_map) +
    geom_sf(aes(fill = climate_similarity), color = "grey40", linewidth = 0.05) +
    scale_fill_viridis_c(option = "inferno", na.value = "grey90",
                         limits = c(0, 100), name = NULL) +
    labs(title = country_name) +
    theme_void() +
    theme(
      plot.title = element_text(size = 13, face = "bold", hjust = 0.5),
      legend.position = "none"
    )
}

p_spain <- make_bilateral_map("ESP", "Spain")
p_japan <- make_bilateral_map("JPN", "Japan")
p_brazil <- make_bilateral_map("BRA", "Brazil")

# combine with patchwork
p4 <- (p_spain | p_japan | p_brazil) +
  plot_annotation(
    title = "Climate Similarity from Three Perspectives",
    subtitle = "How climatically similar is each country to Spain, Japan, and Brazil?",
    caption = "Source: Koppen-Geiger classification (Beck et al., 2023). Own calculations.",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0.5),
      plot.caption = element_text(size = 7, color = "grey50", hjust = 1),
      plot.background = element_rect(fill = "white", color = NA)
    )
  )

ggsave("../Maps/Static/map_bilateral_comparison.png", p4, width = 18, height = 6, dpi = 300, bg = "white")

#--------------------------------------------#
#---- DONE ----------------------------------#
#--------------------------------------------#
