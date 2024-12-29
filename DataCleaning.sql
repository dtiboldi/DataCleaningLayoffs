-- Data Cleaning Project - world_layoffs

# Ran into an issue right at the beginning as not all the records were importing from the csv file
# I had to troubleshoot and wanted to find a new way of uploading the file
# Discovered that I can use the MySQL Command-Line Client to upload the file so I had to install Homebrew on my Terminal and download MySQL Command Line
# In there, I tried to upload the .csv file with all the rows using this formula:
LOAD DATA LOCAL INFILE '/Users/daritib/Downloads/layoffs.csv'
INTO TABLE layoffs
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

# It didn't work so I ran this formula and discovered that my local-infile setting was turned off
SHOW VARIABLES LIKE 'local_infile';

# I had to create and modify the configuration file using nano to turn on the local-infile
# After a lot of troubleshooting, it updated
# Then I had to reboot the MySQL Command Line CLient and use this code again to create the table:
LOAD DATA LOCAL INFILE '/Users/daritib/Downloads/layoffs.csv'
INTO TABLE layoffs
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

# The table ended up adding all the data to the data that was already in there so I had to drop the table and recreate it

# This will show the number of records in the table layoffs
SELECT COUNT(*) FROM layoffs;

# Opening the layoffs table
SELECT *
FROM layoffs;

-- Data Cleaning Steps to Follow:
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. NULL Values or blank values
-- 4. Remove Any Columns or Rows

# Create a new table with the column names from layoffs so we don't work off of the raw data
CREATE TABLE layoffs_staging
LIKE layoffs;

# Open layoffs_staging
SELECT *
FROM layoffs_staging;

# Inserting the data from layoffs to layoffs_staging
INSERT layoffs_staging
SELECT *
FROM layoffs;

# We want to create a duplicate table so that incase we make a mistake, we still want to have the raw data available

-- Removing Duplicates

# This will add another column at the end which will show if that row shows up only once or more times
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`) AS row_num
FROM layoffs_staging;

# A CTE formula that shows us all the rows that are showing up more than once.. ie. duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# Looking into the company 'Casper' to see the duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

# A CTE formula that shows us all the rows that are showing up more than once.. ie. duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,
industry,total_laid_off,percentage_laid_off,`date`,stage,
country,funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


# Creating a new staging table to work on for deleting duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Pulling up our layoffs_staging2 table
SELECT *
FROM layoffs_staging2;

# Inserting our 'row_num' column at the end of our layoffs_staging2 table to show duplicates
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,
industry,total_laid_off,percentage_laid_off,`date`,stage,
country,funds_raised_millions) AS row_num
FROM layoffs_staging;

# Showing all the duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

# Deleting all the duplicates
# I ran into an error here and discovered that I wasn't allowed to Delete or Update so I had to make sure I unchecked that
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

# Turning off safe updates - getting the ability to delete or update
SET SQL_SAFE_UPDATES = 0;



-- Standardizing Data: finding issues in the Data and fixing it

# Saw some company names with white space at the beginning so I'm pulling up the company column and a column where the company column is trimmed
SELECT company, (TRIM(company))
FROM layoffs_staging2;

# Setting the company column to the new trimmed version
UPDATE layoffs_staging2
SET company = TRIM(company);

# I found that some of the industry records that were supposed to be 'Crypto' were written differently - like 'Crypto Currency'
# So I'm pulling up all the rows where the industry name starts with 'Crypto'
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

#Updating all the industry records to 'Crypto' where they start with 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# Looking into the country column in order
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

# Noticed that there was a United States with a '.' at the end so I'm pulling up all the rows where the country names that are like United States
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States';

# I'm pulling up the country column and a column where the country column is trimmed from the '.' at the end
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

# Setting the updated country column to the original country column
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

# Date is in the wrong definition or format
# Selecting the date column and another column where I fix the format and change it from string/text to date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

# Pulling up all the rows where str_to_date is null
SELECT *,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2
WHERE STR_TO_DATE(`date`, '%m/%d/%Y') IS NULL;

# Making all the NULL fields into date format with a random date
UPDATE layoffs_staging2
SET `date` = '12/12/2000'
WHERE `date` IS NULL;

# Now I'm changing all the date column into date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# And changing the definition to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

# Now I'm changing back all the date column fields that were NULL before to NULL
UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` = '2000-12-12';

# Taking a look at the date column in order to see if it worked
SELECT `date`
FROM layoffs_staging2
ORDER BY 1;


-- NULL Values or blank values


# Seeing all the rows where total_laid_off is 'NULL'
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

# Because the csv file uploaded the data in mostly text or integer format, the NULL values were either 'NULL' or '0'
# So I have to update all the fields that are supposed to be NULL to NULL as they are currently in the wrong format
# This formula changes the values that are 0 in total_laid_off to NULL
UPDATE layoffs_staging2
SET total_laid_off = NULL
WHERE total_laid_off = 0;

# This formula changes the values that are 'NULL' in percentage_laid_off to NULL
UPDATE layoffs_staging2
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

# This formula changes the values that are 'NULL' in industry to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = 'NULL';

# If there is no data in total_laid_off AND in percentage_laid_off I am able to delete these rows as they aren't very useful
#Selecting all the rows where there is NULL data in total_laid_off AND in percentage_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Selecting everything where the industry field is blank or NULL
SELECT *
FROM layoffs_staging2
WHERE industry = ''
OR industry IS NULL;

# Looking into Bally's Interactive as that was one of the companies
SELECT *
FROM layoffs_staging2
WHERE company = "Bally's Interactive";

# Looking into Airbnb as that was one of the companies
SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

# Joining the table to itself with the company name where the industry is NULL or blank with where that industry is not NULL
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

# Updating the industry name using the company as the join
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

# It didn't work so I had to change all the industry fields that were blank to NULL and ran the formula (above) again, and it worked
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Now seeing if there are any others left that are NULL still
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

# It was only this company that was still NULL in the industry column but there was no duplicates found for the company so I left it NULL
SELECT *
FROM layoffs_staging2
WHERE company = "Bally's Interactive";

# Selecting everything in layoffs_staging2
SELECT *
FROM layoffs_staging2;


-- Remove Any Columns or Rows


# Selecting all the rows where there is NULL data in total_laid_off AND in percentage_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Deleting all the rows where there is NULL data in total_laid_off AND in percentage_laid_off
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Selecting everything in layoffs_staging2
SELECT *
FROM layoffs_staging2;

# Dropping or deleting the column row_num
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;































