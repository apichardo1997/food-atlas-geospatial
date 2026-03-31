# Geospatial Final Project: Full Reference

**Course:** Geospatial Data Science (Professor Bruno Conte)
**Deadline:** 2026-04-08
**Team:** Ana, Tina, Megan Yeo, Lisbeth Nordmeyer
**Submission:** One single PDF document (notebook format) containing the entire pipeline

---

## Research Question

To what extent do geographic and socioeconomic factors explain bilateral dietary similarity between countries?

---

## Final Paper Structure & Who Did What

| # | Section | Owner | Source File |
|---|---------|-------|-------------|
| 1 | Introduction | Collaborative | Google Doc |
| 2 | Literature Review | Megan (started), expanded collaboratively | Google Doc |
| 3 | Data Description | Collaborative | Google Doc + Megan's Rmd |
| 4 | Methodology (FK index + regression spec) | Collaborative | Google Doc + Megan's Rmd |
| 5 | Data Cleaning Code | Megan | `Cleaning Code.R` / `megan_geospatialprojectcode.Rmd` |
| 6 | Non-Geographic Dataset (trade, gravity, GDP) | Tina | `final_project_tw.R` / `final_project_tw.rmd` (Sections 1.1-1.6) |
| 7 | Geographic Variables: Distance, Borders, Coast | Tina | `final_project_tw.R` (Sections 2.1-2.6) |
| 8 | Geographic Variables: Climate Similarity | Ana | `climate_similarity.R` / `climate_similarity.Rmd` |
| 9 | Geographic Variables: Elevation Similarity | Megan | `elevation_calculation.R` / `megan_geospatialprojectcode.Rmd` |
| 10 | Regressions (with all geo vars) | Lisbeth | Code below / `Geospatial-Final-Regression (1).pdf` |
| 11 | Results Discussion | Lisbeth | `Geospatial-Final-Regression (1).pdf` (pages 6-7) |
| 12 | Maps: Food Similarity (avg, China, seafood) | Tina | `final_project_tw.R` / `final_project_tw.rmd` (Sections 4-5) |
| 13 | Maps: Climate Similarity | Ana | `climate_maps.R` / `climate_maps_interactive.R` |
| 14 | Maps: Elevation Similarity | Megan | `megan_geospatialprojectcode.Rmd` |
| 15 | Conclusion | Lisbeth (draft), needs expanding | `Geospatial-Final-Regression (1).pdf` (page 7) |

---

## Variable Order (consistent across Data, Methodology, Results sections)

| # | Variable | Type | Who Computed | Hypothesis |
|---|----------|------|-------------|------------|
| 1 | Food similarity index (DV) | Bilateral, continuous 0-100 | Megan | -- |
| 2 | Distance (pop-weighted centroids) | Bilateral, log km | Tina | Closer = more similar |
| 3 | Shared borders | Bilateral, binary | Tina | Neighbors = more similar |
| 4 | Coastal access (diff in distance to coast) | Bilateral, log km | Tina | Similar coast access = more similar (seafood) |
| 5 | Climate similarity (Koppen zone overlap) | Bilateral, 0-100 | Ana | Same climate = more similar |
| 6 | Elevation similarity (pop-weighted) | Bilateral, log diff | Megan | Similar elevation = more similar |
| 7 | Bilateral trade | Bilateral, log USD | Tina | More trade = more similar |
| 8 | GDP per capita difference | Bilateral, log USD | Tina | Larger gap = less similar |
| 9 | FTA/WTO membership | Bilateral, binary | Tina (CEPII) | Trade agreement = more similar |
| 10 | Common official language | Bilateral, binary | Tina (CEPII) | Shared language = more similar |
| 11 | Religious proximity | Bilateral, continuous | Tina (CEPII) | More similar religion = more similar |
| 12 | Common colonizer post-1945 | Bilateral, binary | Tina (CEPII) | Shared colonizer = more similar |
| 13 | Colonial relationship post-1945 | Bilateral, binary | Tina (CEPII) | Colonial ties = more similar |

---

## Data Sources & Links

| Data | Source | Link |
|------|--------|------|
| FAO Food Balance Sheets | UN FAO | https://www.fao.org/faostat/en/#data/FBS |
| M49 Country Codes | UN Statistics Division | https://unstats.un.org/unsd/methodology/m49/ |
| CEPII Gravity Dataset (V2022) | CEPII | http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8 |
| BACI Trade Data (HS22, V2026) | CEPII | http://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37 |
| World Bank GDP per capita (PPP) | World Bank | https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD |
| Koppen-Geiger Climate Zones (1991-2020) | Beck et al. (2023) | https://www.gloh2o.org/koppen/ |
| Population Grid | WorldPop | https://www.worldpop.org/ |
| Elevation Raster | R `elevatr` package | https://cran.r-project.org/package=elevatr |
| World Country Polygons | Natural Earth (`rnaturalearth`) | https://www.naturalearthdata.com/ |
| Coastline | Natural Earth | https://www.naturalearthdata.com/ |
| Country Food Similarity Index (inspiration) | ObjectiveLists | https://objectivelists.com/country-food-similarity-index/ |

---

## Key References

- Finger, J. M., & Kreinin, M. E. (1979). A Measure of 'Export Similarity' and Its Possible Uses. *The Economic Journal*, 89(356), 905-912. https://www.jstor.org/stable/2231506
- Beck, H. E., et al. (2023). High-resolution (1 km) Koppen-Geiger maps for 1901-2099 based on constrained CMIP6 projections. *Scientific Data*.
- European Commission (2025). Eurobarometer survey on fishery and aquaculture products consumption. https://oceans-and-fisheries.ec.europa.eu/news/eurobarometer-survey-shows-new-trends-fishery-and-aquaculture-products-consumption-2025-02-20_en
- Wang, Y., et al. (2023). Dietary patterns on the Tibetan Plateau. *PMC*. https://pmc.ncbi.nlm.nih.gov/articles/PMC10181060/
- Mertens, E., et al. (2018). Dietary patterns across European countries. *PMC*. https://pmc.ncbi.nlm.nih.gov/articles/PMC6561990/
- Zhu, C., et al. (2013). Regional food similarity in China. *PMC*. https://pmc.ncbi.nlm.nih.gov/articles/PMC3832477/
- Bitconsin-Junior, A., et al. (2020). Food-related perceptions across regions of Brazil. https://doi.org/10.1016/j.foodqual.2019.103779
- Rong, S., et al. (2021). Comparative dietary guidelines. https://doi.org/10.1016/j.tifs.2021.01.009
- Traill, W. B., et al. (2014). Nutrition transition and globalization. https://doi.org/10.1111/nure.12134
- Balder, H. F., et al. (2003). Dietary patterns across populations.

---

## Lisbeth's Regression Code (Final Version)

This replaces Tina's regression section. Includes climate_similarity and elevation_similarity.
Data source: `data_final_geo.csv` (merged dataset with all variables).

```r
library(data.table)
library(dplyr)
library(tidyr)
library(fixest)

# ---------------- LOAD FINAL DATA -----------------

reg_data <- fread("../Data/Processed/data_final_geo.csv")

# ---------------- DATA PREPARATION ----------------

reg_data <- reg_data %>%
  mutate(
    year = as.integer(year),

    # Trade
    trade_total = replace_na(trade_total, 0),
    log_trade = log1p(trade_total),

    # Distance measures
    log_pop_dist = if_else(
      !is.na(pop_dist_km) & pop_dist_km > 0,
      log(pop_dist_km),
      NA_real_
    ),
    log_diff_dist_coast_km = log1p(diff_dist_coast_km),

    # GDP difference
    gdp_pc_diff = if_else(
      is.na(gdp_pc_diff) & !is.na(gdp_pc_o) & !is.na(gdp_pc_d),
      abs(gdp_pc_o - gdp_pc_d),
      gdp_pc_diff
    ),
    log_gdp_diff = if_else(
      !is.na(gdp_pc_diff) & gdp_pc_diff > 0,
      log(gdp_pc_diff),
      NA_real_
    ),

    # Make sure controls are numeric
    shared_border = as.numeric(shared_border),
    fta_wto_2021 = as.numeric(fta_wto_2021),
    comlang_off_2021 = as.numeric(comlang_off_2021),
    comrelig_2021 = as.numeric(comrelig_2021),
    comcol_2021 = as.numeric(comcol_2021),
    col45_2021 = as.numeric(col45_2021),

    # Additional geographic variables
    climate_similarity = as.numeric(climate_similarity),
    elevation_similarity = as.numeric(elevation_similarity)
  )

# Inspect missing values
reg_data %>%
  summarise(
    missing_similarity = sum(is.na(similarity)),
    missing_log_pop_dist = sum(is.na(log_pop_dist)),
    missing_log_diff_dist_coast_km = sum(is.na(log_diff_dist_coast_km)),
    missing_climate_similarity = sum(is.na(climate_similarity)),
    missing_elevation_similarity = sum(is.na(elevation_similarity)),
    missing_log_trade = sum(is.na(log_trade)),
    missing_log_gdp_diff = sum(is.na(log_gdp_diff))
  )

# ---------------- REGRESSIONS ---------------------

# (1) 2010: no country fixed effects
m2010_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_trade +
    fta_wto_2021 + comlang_off_2021 + comrelig_2021 +
    comcol_2021 + col45_2021,
  data = reg_data %>% filter(year == 2010),
  vcov = ~iso3_o + iso3_d
)

# (2) 2023: no country fixed effects
m2023_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_trade +
    fta_wto_2021 + comlang_off_2021 + comrelig_2021 +
    comcol_2021 + col45_2021,
  data = reg_data %>% filter(year == 2023),
  vcov = ~iso3_o + iso3_d
)

# (3) 2010: with country fixed effects
m2010_fe_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_trade +
    fta_wto_2021 + comlang_off_2021 + comrelig_2021 +
    comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2010),
  vcov = ~iso3_o + iso3_d
)

# (4) 2023: with country fixed effects
m2023_fe_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_trade +
    fta_wto_2021 + comlang_off_2021 + comrelig_2021 +
    comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2023),
  vcov = ~iso3_o + iso3_d
)

# (5) 2010: with country fixed effects and GDP difference
m2010_fe_gdp_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_gdp_diff +
    log_trade + fta_wto_2021 + comlang_off_2021 +
    comrelig_2021 + comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2010),
  vcov = ~iso3_o + iso3_d
)

# (6) 2023: with country fixed effects and GDP difference
m2023_fe_gdp_clim_elev <- feols(
  similarity ~ log_pop_dist + log_diff_dist_coast_km + shared_border +
    climate_similarity + elevation_similarity + log_gdp_diff +
    log_trade + fta_wto_2021 + comlang_off_2021 +
    comrelig_2021 + comcol_2021 + col45_2021 | iso3_o + iso3_d,
  data = reg_data %>% filter(year == 2023),
  vcov = ~iso3_o + iso3_d
)

# ---------------- RESULTS TABLE -------------------

etable(
  m2010_clim_elev,
  m2023_clim_elev,
  m2010_fe_clim_elev,
  m2023_fe_clim_elev,
  m2010_fe_gdp_clim_elev,
  m2023_fe_gdp_clim_elev,
  fitstat = ~n + r2
)
```

---

## Lisbeth's Results Discussion (from PDF pages 6-7)

Overall, the findings provide strong and consistent evidence that geographic and environmental factors play a central role in shaping dietary similarity between countries. Geographic distance emerges as one of the most robust determinants. Across all specifications, the coefficient on the logarithm of population-weighted distance is negative and highly significant, indicating that countries that are geographically closer tend to have more similar diets. This result is consistent with standard gravity-type findings and supports the idea that proximity facilitates similarities in food availability, agricultural conditions, and consumption patterns.

We also find evidence that geographic features beyond simple distance matter. Differences in access to the coast are negatively associated with dietary similarity, suggesting that countries with similar proximity to the sea tend to exhibit more similar consumption patterns, likely reflecting the importance of seafood and maritime trade. While this effect weakens somewhat once country fixed effects are included, it remains economically meaningful. Similarly, sharing a common border is associated with greater dietary similarity, although this effect becomes statistically significant only after controlling for country fixed effects, indicating that neighboring countries share similarities beyond general geographic proximity.

Environmental similarity plays a particularly strong and consistent role. Both climate similarity and elevation similarity are positively and highly significant across all specifications. Countries that share similar climate zones or elevation profiles tend to have significantly more similar diets, even after controlling for country fixed effects and other covariates. These findings highlight the importance of environmental conditions in shaping agricultural production and food availability, and constitute one of the key contributions of this paper.

Turning to economic factors, bilateral trade is positively associated with dietary similarity in models without fixed effects, but loses statistical significance once country fixed effects are included. This suggests that the observed relationship between trade and dietary similarity may be driven by underlying country characteristics or reverse causality, rather than a direct causal effect. Differences in GDP per capita appear to play a role, but do not substantially alter the main geographic coefficients, indicating that income differences are of secondary importance compared to geographic and environmental factors.

Cultural and historical variables show more mixed results. Shared language and religion are positively associated with dietary similarity in simpler specifications, but their effects become weaker or insignificant once fixed effects are included. In contrast, shared colonial ties and trade agreements remain positively associated with dietary similarity, with trade agreements showing a particularly strong and robust effect across all models.

Importantly, the estimated coefficients are remarkably stable between 2010 and 2023, suggesting that the role of geography and environmental conditions in shaping dietary similarity has remained persistent over time, despite increasing globalization.

Taken together, these results suggest that while globalization and economic integration contribute to dietary convergence, they do not fully offset the influence of geography. Instead, geographic proximity and environmental similarity remain the dominant forces shaping dietary patterns across countries. This finding complements existing evidence on the global "nutrition transition" (Traill et al., 2014), suggesting that while diets may be converging in some dimensions, fundamental geographic and environmental constraints continue to play a persistent role.

---

## Regression Results Summary (from PDF)

### Models without Fixed Effects (OLS)

| Variable | 2010 | 2023 |
|---|---|---|
| log_pop_dist | -1.029*** (0.242) | -0.890*** (0.245) |
| log_diff_dist_coast_km | -0.354*** (0.099) | -0.311** (0.094) |
| shared_border | 0.678 (0.450) | 0.693 (0.424) |
| climate_similarity | 0.031*** (0.005) | 0.030*** (0.005) |
| elevation_similarity | 0.294* (0.117) | 0.272* (0.121) |
| log_trade | 0.159*** (0.039) | 0.103** (0.038) |
| fta_wto_2021 | 2.362*** (0.417) | 2.427*** (0.430) |
| comlang_off_2021 | -0.951*** (0.278) | -0.569. (0.309) |
| comrelig_2021 | 1.761*** (0.480) | 1.644** (0.498) |
| comcol_2021 | 0.333 (0.452) | 0.207 (0.471) |
| col45_2021 | 0.681 (0.620) | 0.959. (0.571) |
| R2 | 0.261 | 0.216 |
| Observations | 9,870 | 10,011 |

### Models with Fixed Effects

| Variable | 2010 FE | 2023 FE | 2010 FE+GDP | 2023 FE+GDP |
|---|---|---|---|---|
| log_pop_dist | -1.415*** (0.170) | -1.340*** (0.172) | -1.358*** (0.161) | -1.268*** (0.157) |
| log_diff_dist_coast_km | -0.162* (0.065) | -0.112. (0.060) | -0.130* (0.055) | -0.108* (0.050) |
| shared_border | 1.169* (0.512) | 1.116* (0.524) | 1.022* (0.495) | 0.947. (0.506) |
| climate_similarity | 0.055*** (0.007) | 0.055*** (0.007) | 0.054*** (0.007) | 0.053*** (0.006) |
| elevation_similarity | 0.236*** (0.056) | 0.187** (0.057) | 0.198*** (0.055) | 0.130* (0.055) |
| log_trade | 0.027 (0.026) | -0.009 (0.026) | 0.025 (0.027) | -0.011 (0.025) |
| fta_wto_2021 | 1.506*** (0.358) | 1.358*** (0.364) | 1.224*** (0.322) | 0.999** (0.323) |
| comlang_off_2021 | -0.477* (0.209) | -0.301 (0.198) | -0.550** (0.210) | -0.411* (0.186) |
| comrelig_2021 | -0.177 (0.364) | -0.330 (0.352) | -0.114 (0.324) | -0.069 (0.323) |
| comcol_2021 | 0.731* (0.293) | 0.787** (0.270) | 0.789* (0.323) | 0.893** (0.295) |
| col45_2021 | 0.087 (0.454) | 0.112 (0.369) | 0.365 (0.433) | 0.424 (0.354) |
| log_gdp_diff | -- | -- | -0.873*** (0.115) | -0.852*** (0.107) |
| R2 | 0.668 | 0.673 | 0.707 | 0.706 |
| Observations | 9,868 | 10,009 | 8,909 | 9,314 |

---

## Key Findings

1. **Distance** is the most robust determinant -- closer countries eat more similarly (significant across all 6 models)
2. **Climate similarity** is highly significant everywhere (0.03-0.05***) -- one of the key contributions
3. **Elevation similarity** is significant across all models, stronger with FE
4. **Trade** matters without FE but washes out with FE (likely endogenous)
5. **FTA/WTO** is robust and strong across all models
6. **GDP difference** significant when added, R2 jumps to ~0.71
7. **Cultural vars** are mixed -- language/religion weaken with FE, colonial ties remain
8. **Results are stable between 2010 and 2023** -- geography's role persists despite globalization

---

## Google Drive Folder

https://drive.google.com/drive/folders/1iH-QjCdlcBYelGr_3OldDKZ0F7w8gOoW?usp=drive_link

## Google Doc (Main Write-up)

https://docs.google.com/document/d/1vPK8T5bukUtkznIlp4LncChQ9pjTLGY4nAFcQsl_c0o/edit
