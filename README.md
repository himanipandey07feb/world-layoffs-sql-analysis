# World Layoffs: Data Cleaning & Exploratory Analysis (MySQL)

A SQL project that cleans a global tech layoffs dataset and then explores it to find which companies, industries and countries were hit hardest.

## Tools
- MySQL (Workbench)
- SQL: CTEs, window functions (`ROW_NUMBER`, `DENSE_RANK`, running `SUM`), self-joins, `GROUP BY`

## Dataset
- File: `layoffs.csv` (4,615 raw records)
- Columns: company, location, industry, total_laid_off, percentage_laid_off, date, stage, funds_raised, country, source, date_added

## Files
| File | What it does |
|------|--------------|
| `layoffs.csv` | Raw dataset |
| `data_cleaning_project.sql` | Data cleaning |
| `data_cleaning_project2.sql` | Exploratory data analysis |

## Data cleaning steps
1. Created a staging table so the raw data stays untouched
2. Removed duplicates using `ROW_NUMBER()` with `PARTITION BY`
3. Standardized data: trimmed company names, merged Crypto labels, fixed "United States." and converted the date from text to `DATE`
4. Handled missing values: turned blanks into NULLs and filled missing industries from other rows of the same company with a self-join
5. Converted layoff columns from text to numeric types
6. Removed rows with no layoff numbers and dropped the helper column

## Analysis
- Highest single layoff and highest percentage laid off
- Companies that laid off 100% of staff, ordered by funds raised
- Total layoffs by company, industry, country, funding stage and year
- Monthly layoffs and a rolling (running) total
- Top 5 companies by layoffs in each year (`DENSE_RANK`)

## Key findings
- Amazon, Intel and Meta had the most layoffs in the dataset
- The United States accounts for the large majority of layoffs

## How to run
1. Create a schema named `world_layoffs`
2. Import `layoffs.csv` as a table named `layoffs` (Table Data Import Wizard)
3. Run `data_cleaning_project.sql`, then `data_cleaning_project2.sql`

## Author
Himani Pandey | LinkedIn
Himani Pandey | [LinkedIn](https://www.linkedin.com/in/himanipandey18)# world-layoffs-sql-analysis
A SQL project that cleans a global tech layoffs dataset and then explores it to find which companies, industries and countries were hit hardest.
