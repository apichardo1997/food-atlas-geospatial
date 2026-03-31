## ------------------------------------------------------
## Final Project - Climate Similarity (Koppen-Geiger)
## ------------------------------------------------------

rm(list = ls())

# ---- Packages ----
library(terra)
library(sf)
library(rnaturalearth)
library(exactextractr)
library(dplyr)
library(tidyr)
library(data.table)

# Set path to current directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

#--------------------------------------------#
#---- GENERATE CLIMATE SIMILARITY INDEX -----#
#--------------------------------------------#

### IMPORT ####

# Koppen-Geiger raster (1991-2020, 0.1 degree resolution)
# source: Beck et al. (2023), https://www.gloh2o.org/koppen/
koppen_raster <- rast("../Data/Raw/1991_2020/koppen_geiger_0p1.tif")

# world country polygons (same as tina):
world <- ne_countries(scale = "medium", returnclass = "sf")

### EXTRACT CLIMATE ZONES ####

# extract raster pixels per country:
climate_extract <- exact_extract(koppen_raster, world, include_cols = "iso_a3")
climate_df <- bind_rows(climate_extract)
names(climate_df)[names(climate_df) == "value"] <- "climate_zone"

### CALCULATE SHARES ####

# share of each climate zone per country (weighted by pixel coverage fraction)
# drop ocean pixels (value 0) and bad iso codes ("-99")
climate_shares <- climate_df %>%
  filter(!is.na(climate_zone), climate_zone != 0) %>%
  group_by(iso_a3, climate_zone) %>%
  summarise(area = sum(coverage_fraction), .groups = "drop") %>%
  group_by(iso_a3) %>%
  mutate(share = area / sum(area)) %>%
  ungroup() %>%
  select(iso_a3, climate_zone, share) %>%
  filter(!is.na(iso_a3), iso_a3 != "-99")

# sanity check: spain should be mostly BSk (7) and Csa (8)
climate_shares %>% filter(iso_a3 == "ESP") %>% arrange(desc(share))

#--------------------------------------------#
#---- COMPUTE BILATERAL SIMILARITY ----------#
#--------------------------------------------#

# same overlap method as the food similarity (finger-kreinin):
# similarity = sum of min(share_i, share_j) across all climate zones

# pivot to wide matrix for speed:
climate_wide <- climate_shares %>%
  pivot_wider(id_cols = iso_a3, names_from = climate_zone,
              values_from = share, values_fill = 0)

country_ids <- climate_wide$iso_a3
climate_mat <- as.matrix(climate_wide[, -1])
rownames(climate_mat) <- country_ids

# all unique pairs:
n <- length(country_ids)
pairs <- combn(n, 2)

# overlap similarity for each pair:
similarity_vec <- sapply(seq_len(ncol(pairs)), function(k) {
  sum(pmin(climate_mat[pairs[1, k], ], climate_mat[pairs[2, k], ]))
})

climate_similarity <- data.frame(
  iso3_1 = country_ids[pairs[1, ]],
  iso3_2 = country_ids[pairs[2, ]],
  climate_similarity = similarity_vec * 100  # scale to 0-100
)

#--------------------------------------------#
#---- SANITY CHECKS -------------------------#
#--------------------------------------------#

lookup <- function(c1, c2) {
  climate_similarity %>% filter(
    (iso3_1 == c1 & iso3_2 == c2) | (iso3_1 == c2 & iso3_2 == c1)
  )
}

lookup("ESP", "ITA")  # should be high (both mediterranean)
lookup("NOR", "BRA")  # should be low
lookup("DEU", "FRA")  # should be moderate-high

# top/bottom 10
climate_similarity %>% arrange(desc(climate_similarity)) %>% head(10)
climate_similarity %>% arrange(climate_similarity) %>% head(10)

#--------------------------------------------#
#---- SAVE & MERGE --------------------------#
#--------------------------------------------#

fwrite(climate_similarity, "../Data/Processed/climate_similarity.csv")

### MERGE INTO data_final ####

data_final <- fread("../Data/Processed/data_final.csv")

# remove if already exists (re-run safety):
if ("climate_similarity" %in% names(data_final)) {
  data_final[, climate_similarity := NULL]
}

# pairs in data_final are ordered by M49 code, not alphabetically
# so we create a canonical alphabetical key to match:
climate_sim_merge <- climate_similarity %>%
  mutate(key_1 = pmin(iso3_1, iso3_2), key_2 = pmax(iso3_1, iso3_2)) %>%
  select(key_1, key_2, climate_similarity)

data_final <- data_final %>%
  mutate(key_1 = pmin(iso3_o, iso3_d), key_2 = pmax(iso3_o, iso3_d)) %>%
  left_join(climate_sim_merge, by = c("key_1", "key_2")) %>%
  select(-key_1, -key_2)

# 21463 out of 22654 matched - thats 95% so ok
data_final %>%
  summarise(
    matched = sum(!is.na(climate_similarity)),
    missing = sum(is.na(climate_similarity)),
    total = n()
  )

fwrite(data_final, "../Data/Processed/data_final.csv")
