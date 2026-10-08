-- ============================================================
-- WORLD LAYOFFS: DATA CLEANING (MySQL)
-- Steps: 1) remove duplicates  2) standardize data
--        3) handle NULL/blank values  4) drop unneeded rows/columns
-- ============================================================

SET SQL_SAFE_UPDATES = 0;

-- Staging table (keep the raw table untouched)
CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

INSERT INTO world_layoffs.layoffs_staging
SELECT * FROM world_layoffs.layoffs;

SELECT * FROM world_layoffs.layoffs_staging;


-- ------------------------------------------------------------
-- 1. REMOVE DUPLICATES
-- ------------------------------------------------------------
-- FIX: the old PARTITION BY listed `industry` twice and skipped `country`.
-- Now every business column is included once.
WITH duplicate_cte AS
(
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off,
                     percentage_laid_off, `date`, stage, country, funds_raised
    ) AS row_num
    FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Spot check one duplicated company
SELECT * FROM world_layoffs.layoffs_staging WHERE company = 'Casper';

-- NOTE: MySQL cannot DELETE directly from a CTE, so we copy into a second
-- staging table that has a row_num column, then delete from that.
-- FIX: total_laid_off and percentage_laid_off are kept as TEXT only for the
-- import step; they are converted to numbers in step 3.
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` int DEFAULT NULL,
  `country` text,
  `date_added` text,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off,
                 percentage_laid_off, `date`, stage, country, funds_raised
) AS row_num
FROM world_layoffs.layoffs_staging;

DELETE FROM layoffs_staging2
WHERE row_num > 1;


-- ------------------------------------------------------------
-- 2. STANDARDIZE DATA
-- ------------------------------------------------------------
-- Trim extra spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Merge Crypto, Crypto Currency, CryptoCurrency into one label
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Remove the trailing period in "United States."
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert the date from text (m/d/Y) to a real DATE column
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y')
WHERE `date` IS NOT NULL AND `date` <> '';

UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = '';

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ------------------------------------------------------------
-- 3. NULL AND BLANK VALUES
-- ------------------------------------------------------------
-- FIX: turn blank strings into real NULLs first, so every check below
-- (and the industry fill) works on both kinds of "missing".
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = '';
UPDATE layoffs_staging2 SET total_laid_off = NULL WHERE total_laid_off = '';
UPDATE layoffs_staging2 SET percentage_laid_off = NULL WHERE percentage_laid_off = '';

-- FIX: convert the two text columns to numeric types.
-- Before this, MAX() compared them as text (so '999' beat '22000').
ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off INT,
MODIFY COLUMN percentage_laid_off DOUBLE;

-- Which rows have a missing industry?
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
ORDER BY company;

-- Fill a missing industry from another row of the same company.
-- FIX: single correct UPDATE (the old version had a typo `indutry`
-- and a second duplicate update joined to the wrong table).
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Anything still missing? (e.g. companies that appear only once)
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- FIX: parentheses added. Without them, AND binds before OR and the
-- filter returns the wrong rows.
SELECT *
FROM layoffs_staging2
WHERE (total_laid_off IS NULL)
  AND (percentage_laid_off IS NULL);


-- ------------------------------------------------------------
-- 4. REMOVE ROWS AND COLUMNS WE DON'T NEED
-- ------------------------------------------------------------
-- Rows with no layoff numbers at all can't be used for analysis
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * FROM layoffs_staging2;