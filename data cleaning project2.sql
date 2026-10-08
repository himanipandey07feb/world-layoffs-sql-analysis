-- ============================================================
-- WORLD LAYOFFS: EXPLORATORY DATA ANALYSIS (MySQL)
-- ============================================================

SELECT * FROM world_layoffs.layoffs_staging2;

-- Biggest single layoff and highest percentage
-- (works correctly now that the columns are numeric)
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Companies that laid off 100% of staff (shut down), biggest funding first
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised DESC;

-- Total layoffs by company
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Date range of the data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- FIX: was ORDER BY 1 DESC (alphabetical). Now sorted by total layoffs.
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Total layoffs by country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Total layoffs by funding stage
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- FIX: SUM of percentages has no meaning, so it is replaced by the
-- average and the maximum percentage per company.
SELECT company,
       ROUND(AVG(percentage_laid_off), 2) AS avg_percentage_laid_off,
       MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;

-- Total layoffs per year
SELECT YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY 1 ASC;

-- Layoffs per month
-- FIX: uses the real `date` column with DATE_FORMAT.
SELECT DATE_FORMAT(`date`, '%Y-%m') AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Rolling (running) total of layoffs by month
-- FIX: the old filter used 'date' in quotes (a text string, so it never
-- filtered anything). Now it filters the real column.
WITH Rolling_total AS
(
    SELECT DATE_FORMAT(`date`, '%Y-%m') AS `MONTH`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL
    GROUP BY `MONTH`
)
SELECT `MONTH`, total_off,
       SUM(total_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM Rolling_total
ORDER BY `MONTH`;

-- Layoffs by company and year
SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Top 5 companies by layoffs in each year
WITH Company_year (company, years, total_laid_off) AS
(
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS
(
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM Company_year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;
