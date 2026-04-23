---
title: "NYC Pigeon & Subway Spatial Analysis"
course: "GEOG 515 – Spatial Data Analysis"
author: "Haley Meyrowitz"
date: "Spring 2026"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```
## Project Overview

This project analyzes spatial patterns of pigeon activity near New York City subway station entrances. It combines multiple datasets, including 311 complaints and eBird observations, to identify where pigeon activity is most concentrated and how it relates to subway infrastructure.

The project is designed to be fully reproducible, with a clear workflow from raw data collection through analysis and mapping.

------------------------------------------------------------------------

## Project Structure

The project follows a standard data science folder structure:

```         
Project/
│
├── Code/                # Project file and all R scripts
│   └── NYC_Pigeon_Project/
│
├── Data/
│   ├── Raw/             # Original downloaded data (unaltered)
│   └── Cleaned/         # Processed and analysis-ready data
│
├── Figures/             # Maps and visual outputs
├── Outputs/             # Tables, summaries, CSV outputs
└── Documents/           # Assignment materials
```

## Workflow Overview

The project is organized into sequential scripts that should be run in order:

```         
1Download → 2DataWrangling → 3DataAnalysis → 4Proximity
```

### 1. Download (`1Download.R`)

-   Pulls data from NYC Open Data APIs
-   Saves datasets to `Data/Raw/`
-   Includes:
    -   311 pigeon complaints
    -   Subway routes and stops
    -   Borough boundaries
    -   Neighborhoods

------------------------------------------------------------------------

### 2. Data Wrangling (`2DataWrangling.R`)

-   Cleans and standardizes datasets
-   Reprojects all data to a common CRS (EPSG:2263)
-   Creates spatial joins (e.g., neighborhoods)
-   Calculates distance to nearest subway stop
-   Outputs cleaned datasets to `Data/Cleaned/`

------------------------------------------------------------------------

### 3. Data Analysis (`3DataAnalysis.R`)

-   Uses only cleaned data
-   Produces:
    -   Summary tables (CSV files in `Outputs/`)
    -   Spatial statistics (e.g., Moran’s I)
    -   Maps (saved in `Figures/`)

------------------------------------------------------------------------

### 4. Proximity Analysis (`4Proximity.R`)

-   Focuses specifically on pigeon complaints near subway stops
-   Applies distance thresholds (e.g., within 500 ft)
-   Summarizes counts by subway station

------------------------------------------------------------------------

## Data Lineage

The data flows through the project as follows:

```         
Raw Data → Cleaned Data → Analysis Outputs → Figures
```

-   **Raw Data:** Downloaded or manually added (never edited)
-   **Cleaned Data:** Filtered, transformed, and spatially processed
-   **Outputs:** Tables and statistics derived from cleaned data
-   **Figures:** Maps created from analysis results

------------------------------------------------------------------------

## Naming Conventions

### Scripts

-   Numbered to reflect workflow order
-   Example:
    -   `GIS515_Pigeon_1Download.R`
    -   `GIS515_Pigeon_2DataWrangling.R`

### Data

-   Suffixes indicate processing stage:
    -   `_clean` → cleaned datasets
    -   `_preprocessed` → earlier versions (legacy naming)

------------------------------------------------------------------------

## Notes & Quirks

-   There are duplicate/older versions of some scripts (e.g., download scripts). The numbered versions are the most up-to-date.
-   Naming conventions are slightly inconsistent (`clean` vs `preprocessed`).
-   eBird data is not downloaded automatically and must be manually placed in the Raw folder.

------------------------------------------------------------------------

## Potential Improvements

If continuing development, the following improvements would be made:

-   Standardize naming conventions across all files
-   Remove outdated or duplicate scripts
-   Automate eBird data ingestion
-   Add a formal `README.md` (this document serves as a draft)
-   Possibly modularize scripts further for scalability

------------------------------------------------------------------------

## How to Run the Project

1.  Place all required data in `Data/Raw/`

    -   Ensure eBird dataset is present

2.  Open the RStudio project file (`.Rproj`)

3.  Run scripts in order:

    ```         
    1Download.R
    2DataWrangling.R
    3DataAnalysis.R
    4Proximity.R
    ```

------------------------------------------------------------------------

## Next Steps

The project will shift from identifying where pigeon complaints occur near subway infrastructure to evaluating whether these locations exhibit higher-than-expected levels of complaints, and whether these patterns reflect actual pigeon presence or reporting behavior.

------------------------------------------------------------------------

*If you are reviewing this project: you should be able to follow the workflow using this document*

