library(spData)
library(raster)
library(ncdf4)
library(terra)
library(exactextractr)
library(lubridate)
library(dplyr)
library(sf)
library(tidyr)

food_data = read_csv("~/Documents/Masters/Term 2/Geospatial Data Science/Project/FoodBalanceSheets_E_All_Data_(Normalized).csv")
codes_updated <- read_csv("~/Documents/Masters/Term 2/Geospatial Data Science/Project/codes_updated.csv")
codes_updated = unique(codes_updated)
m49_country_area_codes <- read_csv("~/Documents/Masters/Term 2/Geospatial Data Science/Project/m49_country_area_codes.csv")

## DATA CLEANING
# Get latest year available
food_data = food_data %>% filter(Year == 2023)

# Filter for supply (using energy use/kcal/day)
food_data = food_data %>% filter(`Element Code` == 664)

# Merge in codes that classifies food into categories (starches, vegetal products, meat)
food_data = food_data %>% left_join(codes_updated, 
                                    by = "Item Code")
food_data = food_data %>% filter(!is.na(category))

# Calculate shares of total energy consumption
food_data = food_data %>%
  group_by(Area) %>% 
  mutate(share = Value/sum(Value)) %>%
  ungroup()

food_data = food_data %>%
  mutate(area_code = `Area Code (M49)`,
         element_code = `Element Code`,
         item_code = `Item Code`) %>%
  select(area_code, item_code, Area, Item, share, category)

food_data$area_code <- sub("^'", "", food_data$area_code)
food_data = food_data %>%
  mutate(area_code = as.numeric(area_code))

## CALCULATE SIMILARITY INDEX

# This uses an overlap in distribution method to calculate the similarity index
group_similarity <- function(df, c1, c2, groupname){
  
  d1 <- df %>% filter(area_code == c1, category == groupname)
  d2 <- df %>% filter(area_code == c2, category == groupname)
  
  merged <- full_join(d1, d2, by="Item", suffix=c("_1","_2")) %>%
    mutate(
      share_1 = replace_na(share_1,0),
      share_2 = replace_na(share_2,0)
    )
  
  sum(pmin(merged$share_1, merged$share_2))
}

food_data = food_data %>% filter(area_code %in% m49_country_area_codes$area_code) 
  
countries <- unique(food_data$area_code)
pairs <- expand.grid(c1 = countries, c2 = countries) %>%
  filter(c1 < c2)

food_data = food_data %>% filter(category != "beverages")

similarity_results <- pairs %>%
  rowwise() %>%
  mutate(
    sim_meat  = group_similarity(food_data, c1, c2, "meat"),
    sim_starch = group_similarity(food_data, c1, c2, "starch"),
    sim_fv = group_similarity(food_data, c1, c2, "vegetal_products"),
    
    similarity =
      100 * (
        0.30 * sim_meat +
          0.30 * sim_starch +
          0.40 * sim_fv
      )
  )

country_1_list = food_data %>% select(area_code, `Area`) %>%
  mutate("c1" = area_code,
         "country_1" = `Area`) %>%
  select(-c(area_code, `Area`)) %>%
  unique()

country_2_list = food_data %>% select(area_code, `Area`) %>%
  mutate("c2" = area_code,
         "country_2" = `Area`) %>%
  select(-c(area_code, `Area`)) %>%
  unique()

similarity_results = similarity_results %>%
  left_join(country_1_list,
            by = "c1")

similarity_results = similarity_results %>%
  left_join(country_2_list,
            by = "c2")

## PRELIMINARY ANALYSIS WITH SEAFOOD (IN PROGRESS)
seafood_codes = c(2761, 2762, 2763, 2764, 2765, 2766, 2767)
seafood_data = food_data %>% 
  filter(`Item Code` %in% seafood_codes) %>%
  group_by(Area) %>%
  summarize(share = sum(share))



  