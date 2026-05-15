/*
=========================================================
Project: US Household Income Analysis
File: 02_exploratory_analysis.sql
Purpose:
    Explore household income patterns across states,
    cities, place types, and geographic characteristics
    using the cleaned US household income dataset.

Main Analysis Steps:
    1. Validate cleaned dataset
    2. Create analysis-ready income view
    3. Explore geographic characteristics by state
    4. Analyze state-level income distribution
    5. Compare high- and low-income states
    6. Analyze mean vs median income gap
    7. Analyze income by place type
    8. Analyze city-level income patterns

Tables Used:
    us_household_income
    us_household_income_statistics

View Created:
    vw_income_base
=========================================================
*/


USE us_project;


/* =====================================================
   1. Validate Cleaned Dataset
===================================================== */

-- 1.1 Check final row counts after data cleaning
SELECT 
    COUNT(*) AS income_row_count
FROM us_household_income;

SELECT 
    COUNT(*) AS statistics_row_count
FROM us_household_income_statistics;


-- 1.2 Verify no duplicate ids remain in the income table
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(*) > 1;


-- 1.3 Verify no duplicate ids exist in the statistics table
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM us_household_income_statistics
GROUP BY id
HAVING COUNT(*) > 1;


-- 1.4 Check for invalid or missing income values
SELECT 
    COUNT(*) AS invalid_income_records
FROM us_household_income_statistics
WHERE Mean IS NULL
   OR Median IS NULL
   OR Mean = 0
   OR Median = 0;




/* =====================================================
   2. Create Analysis-Ready Income View
===================================================== */

-- 2.1 Check unmatched records from the income table
SELECT 
    COUNT(*) AS unmatched_income_records
FROM us_household_income u
LEFT JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE us.id IS NULL;


-- 2.2 Check unmatched records from the statistics table
SELECT 
    COUNT(*) AS unmatched_statistics_records
FROM us_household_income_statistics us
LEFT JOIN us_household_income u
    ON us.id = u.id
WHERE u.id IS NULL;


-- 2.3 Create a reusable view for valid income analysis
CREATE OR REPLACE VIEW vw_income_base AS
SELECT 
    u.id,
    u.State_Name,
    u.County,
    u.City,
    u.Place,
    u.Type,
    u.ALand,
    u.AWater,
    us.Mean,
    us.Median,
    us.Stdev
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE us.Mean > 0
  AND us.Median > 0;

-- These records are not deleted from the source table.
-- They are excluded from vw_income_base for income analysis.


-- 2.4 Count valid records available for income analysis
SELECT 
    COUNT(*) AS analysis_ready_records
FROM vw_income_base;




/* =====================================================
   3. Explore Geographic Characteristics by State
===================================================== */

-- 3.1 Analyze total land and water area by state
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    SUM(ALand) AS total_land_area,
    SUM(AWater) AS total_water_area
FROM vw_income_base
GROUP BY State_Name
ORDER BY total_land_area DESC;


-- 3.2 Analyze states with the highest water area percentage
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    SUM(ALand) AS total_land_area,
    SUM(AWater) AS total_water_area,
    ROUND(SUM(AWater) / NULLIF(SUM(ALand) + SUM(AWater), 0) * 100,2) AS water_area_percentage
FROM vw_income_base
GROUP BY State_Name
ORDER BY water_area_percentage DESC
LIMIT 10;


-- 3.3 Compare geographic characteristics with average income by state
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    SUM(ALand) AS total_land_area,
    SUM(AWater) AS total_water_area,
    ROUND(SUM(AWater) / NULLIF(SUM(ALand) + SUM(AWater), 0) * 100,2) AS water_area_percentage,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income
FROM vw_income_base
GROUP BY State_Name
ORDER BY avg_mean_income DESC;




/* =====================================================
   4. Analyze State-Level Income Distribution
===================================================== */

-- 4.1 Analyze average income by state with income ranking
SELECT 
    State_Name,
    record_count,
    avg_mean_income,
    avg_median_income,
    RANK() OVER (ORDER BY avg_mean_income DESC) AS income_rank
FROM (
    SELECT 
        State_Name,
        COUNT(*) AS record_count,
        ROUND(AVG(Mean), 1) AS avg_mean_income,
        ROUND(AVG(Median), 1) AS avg_median_income
    FROM vw_income_base
    GROUP BY State_Name
    HAVING COUNT(*) >= 10
) AS state_income
ORDER BY income_rank;


-- 4.2 Analyze income range by state
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    MIN(Mean) AS min_mean_income,
    MAX(Mean) AS max_mean_income,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    MIN(Median) AS min_median_income,
    MAX(Median) AS max_median_income,
    ROUND(AVG(Median), 1) AS avg_median_income
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
ORDER BY avg_mean_income DESC;


-- 4.3 Analyze overall income distribution summary
SELECT 
    COUNT(*) AS record_count,
    MIN(Mean) AS min_mean_income,
    MAX(Mean) AS max_mean_income,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    MIN(Median) AS min_median_income,
    MAX(Median) AS max_median_income,
    ROUND(AVG(Median), 1) AS avg_median_income
FROM vw_income_base;


-- 4.4 Analyze income variability within states
WITH state_income_variation AS (
    SELECT
        State_Name,
        COUNT(*) AS record_count,
        AVG(Mean) AS avg_mean_income,
        STDDEV(Mean) AS income_stddev
    FROM vw_income_base
    GROUP BY State_Name
    HAVING COUNT(*) >= 10
)
SELECT
    State_Name,
    record_count,
    ROUND(avg_mean_income, 1) AS avg_mean_income,
    ROUND(income_stddev, 1) AS income_stddev,
    ROUND(income_stddev / NULLIF(avg_mean_income, 0) * 100, 2) AS income_variability_percentage
FROM state_income_variation
ORDER BY income_variability_percentage DESC
LIMIT 10;





/* =====================================================
   5. Compare High- and Low-Income States
===================================================== */

-- 5.1 Identify top 10 states by average mean income
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
ORDER BY avg_mean_income DESC
LIMIT 10;


-- 5.2 Identify bottom 10 states by average mean income
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
ORDER BY avg_mean_income ASC
LIMIT 10;


-- 5.3 Identify states with above-average mean income
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
   AND AVG(Mean) > (
       SELECT AVG(Mean)
       FROM vw_income_base
   )
ORDER BY avg_mean_income DESC;




/* =====================================================
   6. Analyze Mean vs Median Income Gap
===================================================== */

-- 6.1 Analyze states with the largest gap between mean and median income
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
ORDER BY mean_median_gap DESC
LIMIT 10;


-- 6.2 Analyze mean vs median gap as a percentage of median income
SELECT 
    State_Name,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap,
    ROUND((AVG(Mean) - AVG(Median)) / NULLIF(AVG(Median), 0) * 100,2) AS gap_percentage
FROM vw_income_base
GROUP BY State_Name
HAVING COUNT(*) >= 10
ORDER BY gap_percentage DESC
LIMIT 10;




/* =====================================================
   7. Analyze Income by Place Type
===================================================== */

-- 7.1 Analyze average income by all place types
-- Overview only: this query includes all place types regardless of sample size.
SELECT 
    Type,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
FROM vw_income_base
GROUP BY Type
ORDER BY avg_mean_income DESC;


-- 7.2 Analyze income by place type with sufficient sample size
SELECT 
    Type,
    record_count,
    avg_mean_income,
    avg_median_income,
    mean_median_gap,
    RANK() OVER (ORDER BY avg_mean_income DESC) AS type_income_rank
FROM (
    SELECT 
        Type,
        COUNT(*) AS record_count,
        ROUND(AVG(Mean), 1) AS avg_mean_income,
        ROUND(AVG(Median), 1) AS avg_median_income,
        ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
    FROM vw_income_base
    GROUP BY Type
    HAVING COUNT(*) >= 100
) AS type_income
ORDER BY type_income_rank;


-- 7.3 Review income range by place type across all categories
-- Overview/range check only: results should not be used alone for final conclusions.
SELECT 
    Type,
    COUNT(*) AS record_count,
    MIN(Mean) AS min_mean_income,
    MAX(Mean) AS max_mean_income,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    MIN(Median) AS min_median_income,
    MAX(Median) AS max_median_income,
    ROUND(AVG(Median), 1) AS avg_median_income
FROM vw_income_base
GROUP BY Type
ORDER BY avg_mean_income DESC;




/* =====================================================
   8. Analyze City-Level Income Patterns
===================================================== */

-- 8.1 Identify highest-income cities with sufficient sample size
SELECT 
    State_Name,
    City,
    record_count,
    avg_mean_income,
    avg_median_income,
    mean_median_gap,
    DENSE_RANK() OVER (ORDER BY avg_mean_income DESC) AS city_income_rank
FROM (
    SELECT 
        State_Name,
        City,
        COUNT(*) AS record_count,
        ROUND(AVG(Mean), 1) AS avg_mean_income,
        ROUND(AVG(Median), 1) AS avg_median_income,
        ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
    FROM vw_income_base
    GROUP BY State_Name, City
    HAVING COUNT(*) >= 5
) AS city_income
ORDER BY city_income_rank
LIMIT 20;


-- 8.2 Analyze cities with the largest mean vs median income gap
SELECT 
    State_Name,
    City,
    COUNT(*) AS record_count,
    ROUND(AVG(Mean), 1) AS avg_mean_income,
    ROUND(AVG(Median), 1) AS avg_median_income,
    ROUND(AVG(Mean) - AVG(Median), 1) AS mean_median_gap
FROM vw_income_base
GROUP BY State_Name, City
HAVING COUNT(*) >= 5
ORDER BY mean_median_gap DESC
LIMIT 20;