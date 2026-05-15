/*
=========================================================
Project: US Household Income Analysis
File: 01_data_cleaning.sql
Purpose:
    Clean and standardize the US household income dataset
    before exploratory analysis.

Main Cleaning Steps:
    1. Inspect row counts
    2. Identify and remove duplicate records
    3. Standardize state names
    4. Correct known location errors
    5. Standardize place types
    6. Check missing or invalid land/water values
	7. Remove Records with Critical Missing Geographic data
	8. Final cleaning validation
	
Tables Used:
    us_household_income
    us_household_income_statistics
=========================================================
*/




USE us_project;

/* =====================================================
   1. Initial Row Count Check
===================================================== */

SELECT COUNT(*) AS income_row_count
FROM us_household_income;

SELECT COUNT(*) AS statistics_row_count
FROM us_household_income_statistics;





/* =====================================================
    2. Identify and Remove Duplicate Records
===================================================== */

-- 2.1 Check duplicate ids
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(*) > 1;


-- 2.2 Identify duplicate rows
SELECT 
    row_id,
    id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY row_id) AS row_num
FROM us_household_income;


-- 2.3 Remove duplicate rows while keeping the first record
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT 
            row_id,
            id,
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY row_id) AS row_num
        FROM us_household_income
    ) AS duplicates
    WHERE row_num > 1
);


-- 2.4 Verify duplicate removal
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(*) > 1;





/* =====================================================
   3. Standardize State Names
===================================================== */

-- 3.1 Check distinct state names before standardization
SELECT DISTINCT State_Name
FROM us_household_income
ORDER BY State_Name;


-- 3.2 Remove leading and trailing spaces from state names
UPDATE us_household_income
SET State_Name = TRIM(State_Name);


-- 3.3 Correct inconsistent capitalization
UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE LOWER(State_Name) = 'alabama';


-- 3.4 Correct misspelled state names
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE LOWER(State_Name) = 'georia';


-- 3.5 Verify state names after standardization
SELECT DISTINCT State_Name
FROM us_household_income
ORDER BY State_Name;





/* =====================================================
   4. Correct Known Location Errors
===================================================== */

-- 4.1 Review records in Autauga County to identify location inconsistencies
SELECT 
    row_id,
    id,
    State_Name,
    County,
    City,
    Place
FROM us_household_income
WHERE County = 'Autauga County'
ORDER BY row_id;


-- 4.2 Correct missing place value based on county and city information
UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County'
  AND City = 'Vinemont';


-- 4.3 Verify the corrected location record
SELECT 
    row_id,
    id,
    State_Name,
    County,
    City,
    Place
FROM us_household_income
WHERE County = 'Autauga County'
  AND City = 'Vinemont';





/* =====================================================
   5. Standardize Place Types
===================================================== */

-- 5.1 Check place type categories before standardization
SELECT 
    Type,
    COUNT(*) AS type_count
FROM us_household_income
GROUP BY Type
ORDER BY type_count DESC;


-- 5.2 Standardize place type labels
UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

UPDATE us_household_income
SET Type = 'CDP'
WHERE Type = 'CPD';


-- 5.3 Verify place type categories after standardization
SELECT 
    Type,
    COUNT(*) AS type_count
FROM us_household_income
GROUP BY Type
ORDER BY type_count DESC;





/* =====================================================
   6. Check Missing or Invalid Land/Water Values
===================================================== */

-- 6.1 Check records with missing or zero land area
SELECT 
    row_id,
    id,
    State_Name,
    County,
    City,
    ALand,
    AWater
FROM us_household_income
WHERE ALand = 0 OR ALand IS NULL;


-- 6.2 Check records with missing water area
SELECT 
    row_id,
    id,
    State_Name,
    County,
    City,
    ALand,
    AWater
FROM us_household_income
WHERE AWater IS NULL;


-- 6.3 Check overall land and water area ranges
SELECT 
    MIN(ALand) AS min_land_area,
    MAX(ALand) AS max_land_area,
    MIN(AWater) AS min_water_area,
    MAX(AWater) AS max_water_area
FROM us_household_income;


-- These records have zero land area. 
-- Since some may represent water-based areas or special geographic units,
-- they are kept for now but excluded from land-area-based analysis.






/* =====================================================
   7. Remove Records With Critical Missing Geographic Data
===================================================== */

-- 7.1 Identify records with critical missing geographic data
SELECT *
FROM us_household_income
WHERE Zip_Code IS NULL
  AND Area_Code IS NULL
  AND ALand IS NULL
  AND AWater IS NULL
  AND Lat IS NULL
  AND Lon IS NULL;


-- 7.2 Remove records with critical missing geographic data
DELETE FROM us_household_income
WHERE Zip_Code IS NULL
  AND Area_Code IS NULL
  AND ALand IS NULL
  AND AWater IS NULL
  AND Lat IS NULL
  AND Lon IS NULL;


-- 7.3 Verify critical missing records were removed
SELECT *
FROM us_household_income
WHERE Zip_Code IS NULL
  AND Area_Code IS NULL
  AND ALand IS NULL
  AND AWater IS NULL
  AND Lat IS NULL
  AND Lon IS NULL;





/* =====================================================
   8. Final cleaning validation
===================================================== */

-- Verify no duplicate ids remain
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM us_household_income
GROUP BY id
HAVING COUNT(*) > 1;


-- Verify standardized state names
SELECT DISTINCT State_Name
FROM us_household_income
ORDER BY State_Name;


-- Verify standardized type values
SELECT 
    Type,
    COUNT(*) AS type_count
FROM us_household_income
GROUP BY Type
ORDER BY type_count DESC;


-- Verify critical missing geographic records were removed
SELECT *
FROM us_household_income
WHERE Zip_Code IS NULL
  AND Area_Code IS NULL
  AND ALand IS NULL
  AND AWater IS NULL
  AND Lat IS NULL
  AND Lon IS NULL;
































