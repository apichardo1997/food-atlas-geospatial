# Geospatial Final Project: Determinants of Food Similarity

**Course:** Geospatial Data Science (Professor Bruno Conte)
**Date created:** 2026-03-25
**Deadline:** 2026-04-08 (two weeks from now)
**Team:** Ana, Tina, Megan Yeo, Lisbeth

---

## Research Question

*To what extent do geographic and socioeconomic factors explain bilateral dietary similarity between countries?*

Hook: globalization and dietary convergence. Do countries that are closer, trade more, or share cultural ties eat more similarly?

---

## Method

- **Finger-Kreinin Index** (overlap-in-distribution similarity score) to measure bilateral food similarity between every country pair
- Food items grouped into 3 categories with weighted similarity: **meat (30%)**, **starch (30%)**, **vegetables/vegetal products (40%)**
- Beverages excluded
- Similarity computed for **2010** and **2023** using FAO food supply data (kcal/day, Element Code 664)
- Countries filtered to M49 recognized countries only
- Regression of similarity index on trade, geographic, and cultural/institutional variables
- Models run with and without **country fixed effects** (origin + destination)
- Standard errors clustered by iso3_o and iso3_d

---

## Submission Requirements (from Professor Conte)

- **One single PDF document** containing the entire pipeline
- Must include **all relevant information** and **the code used to generate every output**
- A **notebook format** (like the assignments) is ideal but not required
- Code and analysis must be integrated -- not separate files
- Basically: R Markdown or Quarto notebook exported to PDF is the way to go

---

## Proposed Paper Structure

1. **Introduction** (motivation/RQ -- high weight): globalization & dietary convergence, clear research question, brief preview of data/method/findings
2. **Related Literature** (motivation): Finger & Kreinin (1979), 1-2 papers on dietary patterns and geography/development. Keep short, 1 paragraph max
3. **Data**: FAO food supply data, M49 country filter, how shares are constructed, beverage exclusion, descriptive stats
4. **Method**: Finger-Kreinin index formula, gravity-style regression specification
5. **Results**: regression tables, maps, interpretation
6. **Conclusion**

---

## What Is Done

### Megan
- Cleaned FAO food data (2023 initially, then also 2010)
- Classified food items into categories (meat, starch, vegetal_products, beverages) via `codes_updated.csv`
- Calculated food similarity scores using Finger-Kreinin index for all country pairs
- Could not 100% replicate the website rankings but method is sound
- Wrote intro and motivation / mini lit review on the Google Doc
- Will work on **elevation** variable (has code from a problem set)

### Tina
- Merged datasets: FAO similarity + CEPII Gravity + BACI trade + World Bank GDP
- Built `final_project_tw.R` -- the main regression script
- Ran first regressions for 2010 and 2023 (with and without fixed effects, with and without GDP)
- Results look as expected: trade and distance significant, cultural vars matter
- Uploaded `final_project_tw.R` and `data_final.csv` to the shared drive
- Working on **shared borders** and **distances** (population-weighted centroids because regular centroids are bad for countries with distant territories)
- Added **GDP per capita difference** as a regressor
- Working on **distance/access to coastline** (oceans and seas)
- Uses ISO-3 alphabetic codes

### Lisbeth
- Suggested constructing Finger-Kreinin index with all categories (not just food groups) to see geographic effects
- Raised question about whether categories might just be capturing geography
- Asked about extent of literature references needed for motivation

### Ana (You)
- Volunteered to look at geographical variables
- Assigned to work with **raster data** for the **Koppen climate zone** variable
- Volunteered to help with distance to water bodies but Tina took coastline, so coordinate with her

---

## What Needs To Be Done

### Geographic Variables (the main remaining work)
| Variable | Assigned To | Status | Notes |
|---|---|---|---|
| Elevation | Megan | In progress | Has code from a pset, will reuse |
| Koppen climate zones | Ana | Not started | Requires raster data |
| Distance to coastline / water bodies | Tina | In progress | Doing oceans and seas |
| Shared borders | Tina | Done (but refining) | Working on population-weighted centroids |
| Distances between countries | Tina | Done (from CEPII) | Eventually calculate with own geo data |

### Key Decisions Needed
- **How to measure geographic similarity between countries:** For continuous variables (elevation, distance from ocean), the agreed approach is to **log the values and take the absolute difference** (Tina already did this for GDP). For categorical variables (climate zones), use the **same overlap method as the food similarity index** -- compute each country's share of land area in each Koppen zone, then sum the min shares across zones for each country pair (Finger-Kreinin style)
- **Whether to extend to more years:** Tina asked about data from previous years for an interactive map of food similarity over time, but acknowledged time constraints
- **Scope of literature review:** Lisbeth asked how extensive the motivation/lit references need to be

### Writing & Assembly
- [ ] Finalize geographic variables and merge into `data_final.csv`
- [ ] Re-run regressions with geographic variables included
- [ ] Create maps / visualizations (interactive map of food similarity?)
- [ ] Write up Data and Method sections
- [ ] Write up Results section with regression tables
- [ ] Compile final paper/report

---

## Current Regression Results (Preliminary)

4 models run so far (without geographic variables):

| Variable | 2010 (no FE) | 2023 (no FE) | 2010 (FE) | 2023 (FE) |
|---|---|---|---|---|
| log_trade | 0.191*** | 0.121** | 0.026 | -0.002 |
| log_dist | -1.154*** | -1.070*** | -2.106*** | -2.035*** |
| comlang_off | -0.892*** | -0.477. | -0.212 | 0.036 |
| comrelig | 2.343*** | 2.258*** | 0.511 | 0.401 |
| comcol | 0.676 | 0.515 | 0.812* | 0.800** |
| col45 | -0.423 | -0.169 | -0.751 | -0.807 |
| fta_wto | 2.575*** | 2.631*** | 1.659*** | 1.490*** |
| R-squared | 0.203 | 0.167 | 0.628 | 0.633 |
| Observations | 10,440 | 10,585 | 10,438 | 10,583 |

GDP difference models also run but table not shown here.

---

## Data Sources

- **FAO Food Balance Sheets** (`FoodBalanceSheets_E_All_Data_(Normalized).csv`) -- food supply in kcal/capita/day
- **M49 country codes** (`m49_country_area_codes.csv`) -- to filter to recognized countries
- **Food category codes** (`codes_updated.csv`) -- maps food items to meat/starch/vegetal_products/beverages
- **CEPII Gravity dataset** (V2022) -- distance, common language, religion, colonial ties, FTA/WTO, social connectedness index
- **BACI trade data** (HS22, V2026) -- bilateral trade flows for 2023
- **World Bank GDP** -- GDP per capita for 2010 and 2023
- **Koppen Climate Explorer** (https://koppen.earth/) -- climate zone raster data
- **Copernicus Water Bodies** (https://land.copernicus.eu/en/products/water-bodies/water-bodies-global-v2-0-300m) -- water bodies raster data
- **Natural Earth** (`ne_countries` from `rnaturalearth` R package) -- world country polygons

---

## File Structure

```
Geospatial Final Project/
  Code/
    Cleaning Code.R              -- Megan's data cleaning + similarity calculation
    final_project_tw.R           -- Tina's merge + regression script
    climate_similarity.R         -- Ana's climate similarity calculation
    climate_similarity.Rmd       -- Ana's notebook version (for PDF)
    climate_maps.R               -- static map visualizations
    climate_maps_interactive.R   -- interactive Leaflet maps
  Data/
    Raw/
      FoodBalanceSheets_E_All_Data_(Normalized).csv
      FAOSTAT_data_3-15-2026.csv
      m49_country_area_codes.csv
      codes_updated.csv
      1991_2020/koppen_geiger_0p1.tif  -- Koppen raster
      koppen_geiger_tif.zip
      legend.txt
    Processed/
      food_data.csv              -- cleaned food data (2023)
      food_data_2010.csv         -- cleaned food data (2010)
      similarity_results.csv     -- food similarity index (2023)
      similarity_results_2010.csv -- food similarity index (2010)
      climate_similarity.csv     -- climate similarity index
      data_final.csv             -- merged regression dataset
  Maps/
    Static/                      -- PNG maps
    Interactive/                 -- HTML Leaflet maps (zoomable, hover)
  Notes/
    Motivation and Lit Review_.docx
    geospatial_ determinants of food similarity.docx
  PROJECT_OVERVIEW.md
```

---

## Ana's Part: Koppen Climate Zone Similarity

### Goal

Produce a dataset of **bilateral climate similarity scores** for every country pair, using the same overlap logic as the food similarity index. The output should be a CSV with columns `iso3_o`, `iso3_d`, `climate_similarity` that can be merged into `data_final.csv`.

---

### Step 0: Setup

Install and load packages. You need `terra` for rasters, `sf` for shapefiles, `rnaturalearth` for the world map (same one Tina uses), and `exactextractr` for fast raster extraction.

```r
library(terra)
library(sf)
library(rnaturalearth)
library(exactextractr)
library(dplyr)
library(tidyr)
```

---

### Step 1: Download the Koppen Raster

Go to **https://koppen.earth/** and download the climate classification raster. You want the **global GeoTIFF** file (something like `Beck_KG_V1_present_0p0083.tif` -- the present-day classification). Save it into your `Raw Data/` folder.

---

### Step 2: Load the Raster and the World Map

```r
# Load the Koppen raster
koppen_raster <- rast("Raw Data/Beck_KG_V1_present_0p0083.tif")

# Load the same world map Tina is using
world <- ne_countries(scale = "medium", returnclass = "sf")
```

The raster has integer values where each number corresponds to a Koppen climate class (e.g., 1 = Af (tropical rainforest), 2 = Am (tropical monsoon), etc.). The mapping should be in the documentation on the website.

---

### Step 3: Extract Climate Zones Per Country

For each country polygon, extract all the raster pixels that fall inside it. `exact_extract` gives you the pixel values and their coverage fractions (how much of each pixel is inside the polygon).

```r
# Extract pixel values per country
climate_extract <- exact_extract(koppen_raster, world, include_cols = "iso_a3")
```

This returns a list of data frames, one per country. Each row is a pixel with columns `value` (the Koppen class) and `coverage_fraction`.

---

### Step 4: Calculate Share of Land in Each Climate Zone

For each country, compute what fraction of its total land area falls in each Koppen zone. Use coverage_fraction as the weight (it accounts for partial pixels at borders).

```r
# Bind all countries into one data frame
climate_df <- bind_rows(climate_extract)

# Calculate share of each climate zone per country
climate_shares <- climate_df %>%
  filter(!is.na(value), value != 0) %>%       # 0 = ocean/water, drop it
  group_by(iso_a3, value) %>%
  summarise(area = sum(coverage_fraction), .groups = "drop") %>%
  group_by(iso_a3) %>%
  mutate(share = area / sum(area)) %>%         # share of land in this zone
  ungroup() %>%
  select(iso_a3, climate_zone = value, share)
```

At this point you have a table like:

| iso_a3 | climate_zone | share |
|--------|-------------|-------|
| ESP    | 3 (BSk)     | 0.45  |
| ESP    | 8 (Csa)     | 0.40  |
| ESP    | 5 (Cfb)     | 0.15  |
| FRA    | 5 (Cfb)     | 0.60  |
| FRA    | 8 (Csa)     | 0.20  |
| FRA    | 12 (Dfb)    | 0.20  |

---

### Step 5: Compute Bilateral Climate Similarity (Finger-Kreinin Overlap)

For every pair of countries, the climate similarity = sum of min(share_i, share_j) across all climate zones. This is the exact same logic Megan used for food.

```r
# Get all country pairs
countries <- unique(climate_shares$iso_a3)
pairs <- expand.grid(iso3_o = countries, iso3_d = countries,
                     stringsAsFactors = FALSE) %>%
  filter(iso3_o < iso3_d)   # keep unique pairs only

# Calculate overlap similarity for each pair
climate_similarity <- pairs %>%
  rowwise() %>%
  mutate(
    climate_similarity = {
      s1 <- climate_shares %>% filter(iso_a3 == iso3_o)
      s2 <- climate_shares %>% filter(iso_a3 == iso3_d)
      merged <- full_join(s1, s2, by = "climate_zone", suffix = c("_1", "_2")) %>%
        mutate(share_1 = replace_na(share_1, 0),
               share_2 = replace_na(share_2, 0))
      sum(pmin(merged$share_1, merged$share_2))
    }
  ) %>%
  ungroup()
```

The result is a score between 0 and 1 for each pair. You can multiply by 100 to match the food similarity scale if needed.

**Note:** the `rowwise()` loop over ~10,000+ pairs will be slow. If it's too slow, you can vectorize it by pivoting to a wide matrix and doing matrix operations -- but try the simple version first.

---

### Step 6: Save and Share

```r
write.csv(climate_similarity, "Processed Data/climate_similarity.csv", row.names = FALSE)
```

---

### Step 7: Merge Into the Final Dataset

Tina's `data_final.csv` uses `iso3_o` and `iso3_d` as keys. Your output already uses the same column names, so the merge is straightforward:

```r
data_final <- fread("Processed Data/data_final.csv")
data_final <- data_final %>%
  left_join(climate_similarity, by = c("iso3_o", "iso3_d"))
```

**Important:** `data_final` has pairs ordered with `iso3_o < iso3_d` alphabetically (from the similarity calculation). Make sure your pairs follow the same convention -- the `filter(iso3_o < iso3_d)` in Step 5 handles this.

---

### Sanity Checks

Once you have results, verify with a few intuitive pairs:
- **Spain & Italy** should have high climate similarity (both Mediterranean)
- **Norway & Brazil** should have low climate similarity
- **Germany & France** should be moderate-to-high (both temperate, but France has more Mediterranean)

Also check:
- How many countries matched between your raster extraction and `data_final`? Any ISO code mismatches?
- Any countries with `NA` or zero coverage? (small island nations might have too few pixels)

---

### Potential Issues to Watch For

1. **ISO code mismatches:** `ne_countries` sometimes uses `-99` or non-standard codes for disputed territories. Filter those out.
2. **Small island nations:** May have very few raster pixels. The overlap method still works but scores might be noisy.
3. **The raster might be large** (~1GB for high-res). If R crashes, use the coarser resolution version from koppen.earth.
4. **Pair direction:** Make sure your country pairs match the order in `data_final` (both should be `iso3_o < iso3_d` alphabetically).
