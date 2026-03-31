library(spData)
library(raster)
library(ncdf4)
library(terra)
library(exactextractr)
library(lubridate)
library(dplyr)
library(sf)
library(tidyr)
library(tiff)
library(elevatr)
library(mapview)


# Read in population grid and country boundaries
population = raster("/Users/megan/Documents/Masters/Term 2/Geospatial Data Science/Project/global_pop.tif") 
countries = read_sf("/Users/megan/Documents/Masters/Term 2/Geospatial Data Science/Project/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp") 
data_final <- read_csv("~/Documents/Masters/Term 2/Geospatial Data Science/Project/data_final.csv")

# Calculate elevation raster
elevation <- get_elev_raster(countries, z = 5)
countries_shape = vect(countries)
elevation_mask = mask(elevation, countries)
writeRaster(elevation_mask, "/Users/megan/Documents/Masters/Term 2/Geospatial Data Science/Project/elevation_mask.tif")

# Reproject Data
population <- rast(population)
elevation_mask <- rast(elevation_mask)
countries <- st_transform(countries, crs(elevation_mask))
population <- project(population, elevation_mask)

# Calculate mean elevation weighted by population
weighted = population * elevation_mask
weighted_sum = zonal(weighted, countries_shape, fun = "sum", na.rm = TRUE)
pop_sum = zonal(population, countries_shape, fun = "sum", na.rm = TRUE)
weighted_mean = weighted_sum / pop_sum
countries$weighted_elevation = weighted_mean$global_pop

# Merge data into panel
countries_o = countries %>% select(ISO_A3, weighted_elevation) %>%
  mutate(iso3_o = ISO_A3,
         weighted_elevation_o = weighted_elevation) %>%
  st_drop_geometry() %>%
  select(-c(ISO_A3, weighted_elevation))

countries_d = countries %>% select(ISO_A3, weighted_elevation) %>%
  mutate(iso3_d = ISO_A3,
         weighted_elevation_d = weighted_elevation) %>%
  st_drop_geometry() %>%
  select(-c(ISO_A3, weighted_elevation))

data_final = data_final %>% left_join(countries_o, by = "iso3_o")
data_final = data_final %>% left_join(countries_d, by = "iso3_d")

# Calculate elevation difference
data_final = data_final %>%
  mutate(elevation_difference = log(abs(weighted_elevation_o - weighted_elevation_d)))

data_final = data_final %>%
  select(-c(weighted_elevation_o, weighted_elevation_d))

write.csv(data_final,"/Users/megan/Documents/Masters/Term 2/Geospatial Data Science/Project/data_final_25Mar.csv", row.names = FALSE )
