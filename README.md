# US Household Income SQL Analysis

## Project Overview

This project analyzes U.S. household income patterns using SQL.

The goal is to clean and validate raw datasets, create an analysis-ready SQL view, and explore income patterns across states, cities, and place types.

The analysis focuses on:

- State-level income patterns
- Mean vs median income gaps
- Income variability across communities
- Income differences by place type
- City-level income rankings with sample-size filters
- Geographic context such as land area and water area

---

## Tools Used

- MySQL
- MySQL Workbench
- GitHub

## SQL Skills Applied

- Data cleaning
- Joins
- Views
- Common Table Expressions
- Window functions
- Aggregate functions
- Exploratory data analysis
- Sample-size filtering

---

## Dataset

This project uses two raw CSV files:

- `us_household_income.csv`
- `us_household_income_statistics.csv`

The raw data is stored in the `data/raw/` folder and kept unchanged.  
All cleaning and analysis steps are documented through SQL scripts.

---

## Project Structure

```text
US-Household-Income-SQL-Analysis/
│
├── data/
│   └── raw/
│       ├── us_household_income.csv
│       └── us_household_income_statistics.csv
│
├── sql/
│   ├── 01_data_cleaning.sql
│   └── 02_exploratory_analysis.sql
│
└── README.md
```

---

## Data Cleaning Process

The cleaning process was completed in `01_data_cleaning.sql`.

Main steps included:

- Checking row counts
- Removing duplicate records
- Standardizing state names and place type values
- Correcting spelling and location issues
- Checking missing or invalid land and water area values
- Removing records with critical missing geographic data
- Validating the cleaned dataset before analysis

---

## Exploratory Data Analysis

The analysis was completed in `02_exploratory_analysis.sql`.

I created a reusable SQL view called `vw_income_base` to join the geographic and income statistics tables and filter out invalid income records.

The EDA included:

- Ranking states by average income
- Comparing high- and low-income states
- Calculating mean vs median income gaps
- Measuring income variability within states
- Comparing income by place type
- Ranking cities after applying minimum sample-size filters

---

## Key Findings

The analysis showed clear income differences across states after filtering for valid income records.

The mean vs median income gap helped identify areas where average income may be influenced by higher-income communities.

Income variability was measured across geographic records within each state. This does not measure individual-level income inequality, but it helps show how much average income differs across communities.

Place-type and city-level comparisons were filtered by sample size to reduce the risk of misleading results from very small groups.

Geographic characteristics such as land area and water area were used for context, not as direct explanations for income differences.

---

## Limitations

This analysis is based on aggregated geographic and income data, not individual household-level records.

The dataset does not include population, cost of living, education level, employment type, industry, or local economic conditions. Because of this, the results should be interpreted as exploratory patterns rather than final explanations.

---

## Next Steps

Possible next steps include:

- Building a Power BI or Tableau dashboard
- Adding population data
- Comparing income with cost-of-living data
- Creating visualizations for state-level and city-level income patterns
