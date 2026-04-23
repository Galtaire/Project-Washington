DROP TABLE IF EXISTS listings;
CREATE TABLE listings (
	`zip` INT,
    `type` VARCHAR(50),
    `year_built` INT,
    `list_price` INT,
    `last_sold_price` INT,
    `list_to_sold_ratio` DECIMAL(19,4),
    `sqft` INT,
    `price_per_sqft` DECIMAL(19,4),
    `stories` INT,
    `beds` INT,
    `baths` INT,
    `baths_full` INT,
    `baths_full_calc` INT,
    `garage` INT);
    
DROP TABLE IF EXISTS zip;
CREATE TABLE `zip` (
	`zip` INT NOT NULL,
    `county` VARCHAR(255) NOT NULL,
    `area_code` VARCHAR(100) NOT NULL,
    `latitude` DECIMAL(14,2) NOT NULL,
    `longtitude` DECIMAL(14,2) NOT NULL,
    `est_population` INT NOT NULL);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/washington/washington_real_estate.csv'
INTO TABLE `listings`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS (
	@v_zip,
    `type`,
    @v_year_built,
    @v_list_price,
    @v_last_sold_price,
    @v_list_to_sold_ratio,
    @v_sqft,
    @v_price_per_sqft,
    @v_stories,
    @v_beds,
    @v_baths,
    @v_baths_full,
    @v_baths_full_calc,
    @v_garage
    )
SET `zip` = NULLIF(@v_zip, ''),
	`year_built` = NULLIF(@v_year_built, ''),
    `list_price` = NULLIF(@v_list_price, ''),
    `last_sold_price` = NULLIF(@v_last_sold_price, ''),
    `list_to_sold_ratio` = NULLIF(@v_list_to_sold_ratio, ''),
    `sqft` = NULLIF(@v_sqft, ''),
    `price_per_sqft` = NULLIF(@v_price_per_sqft, ''),
    `stories` = NULLIF(@v_stories, ''),
    `beds` = NULLIF(@v_beds, ''),
    `baths` = NULLIF(@v_baths, ''),
    `baths_full` = NULLIF(@v_baths_full, ''),
    `baths_full_calc` = NULLIF(@v_baths_full_calc, ''),
    `garage` = NULLIF(@v_garage, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/washington/washington_zip.csv'
INTO TABLE `zip`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS (
	`zip`,
    `county`,
    `area_code`,
    `latitude`,
    `longtitude`,
    `est_population`);

DROP TABLE IF EXISTS listings1;
CREATE TABLE listings1 AS 
SELECT * FROM listings;

DROP TABLE IF EXISTS zip1;
CREATE TABLE zip1 AS 
SELECT * FROM zip;

ALTER TABLE listings1
ADD COLUMN `id` INT AUTO_INCREMENT FIRST,
ADD PRIMARY KEY (`id`);

ALTER TABLE zip1
ADD COLUMN `id` INT AUTO_INCREMENT FIRST,
ADD PRIMARY KEY (`id`);

UPDATE listings1
SET `type` = TRIM(`type`);

UPDATE zip1 
SET `county` = TRIM(`county`);

UPDATE zip1
SET county = 'King County' 
WHERE zip IN (98082, 98189);

SELECT list_price,
    last_sold_price,
    sqft,
    price_per_sqft,
	COALESCE(price_per_sqft, (last_sold_price/sqft), 0)
FROM listings1;
    
UPDATE listings1
SET price_per_sqft = (last_sold_price/sqft)
WHERE price_per_sqft IS NULL 
	AND last_sold_price IS NOT NULL
    AND sqft IS NOT NULL;
-- Fixing NULL Values in Price_Per_Sqft 

SELECT *
FROM listings1
WHERE price_per_sqft IS NULL
	AND last_sold_price IS NOT NULL
    AND sqft IS NOT NULL;

UPDATE listings1
SET garage = 0
WHERE garage IS NULL;

WITH checker AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY 
			year_built, 
			list_price, 
			last_sold_price, 
			list_to_sold_ratio) AS rownum
	FROM listings1)
SELECT *
FROM checker 
WHERE rownum > 2;
-- Checking for Duplicate Listings

UPDATE listings1  
SET type = 'Single Family' 
WHERE type = 'single_family';

UPDATE listings1  
SET type = 'Mobile' 
WHERE type = 'mobile';

UPDATE listings1  
SET type = 'Townhome' 
WHERE type = 'townhomes';

UPDATE listings1  
SET type = 'Condominium' 
WHERE type = 'condo';

UPDATE listings1  
SET type = 'Multi-Family' 
WHERE type = 'multi_family';

###### VIEWS - PowerBI

CREATE OR REPLACE VIEW v_total_listings AS
SELECT COUNT(*) AS Total_Listings
FROM listings1;

CREATE OR REPLACE VIEW v_expensive_counties AS
SELECT 	z1.county,
			ROUND(AVG(l1.sqft),2) AS Average_sqft, 
				ROUND(AVG(l1.price_per_sqft),2) AS Average_sqft_Price,
					ROUND(AVG(l1.list_price),2) AS Average_Listing_Price
FROM listings1 AS l1
JOIN zip1 AS z1
	ON l1.zip = z1.zip
WHERE l1.list_price IS NOT NULL
	AND `type` <> 'farm'
    AND `type` <> 'land'
    AND `type` <> 'coop'
    AND `type` <> 'other'
GROUP BY z1.county
ORDER BY Average_Listing_Price DESC
LIMIT 10;

CREATE OR REPLACE VIEW v_high_competition AS
SELECT	l1.type,
		z1.county,
		z1.zip,
        z1.latitude,
        z1.longtitude,
		l1.year_built,
		l1.last_sold_price,
        ROUND(l1.list_to_sold_ratio, 2) AS 'List-Sold_Ratio',
        l1.sqft,
        ROUND(l1.price_per_sqft, 2) AS 'Price_per_Sqft'
FROM listings1 AS l1
JOIN zip1 AS z1
	ON l1.zip = z1.zip
WHERE list_to_sold_ratio >= 1
	AND l1.type NOT IN ('farm', 'land', 'coop', 'other')
ORDER BY list_to_sold_ratio DESC;


CREATE OR REPLACE VIEW v_highest_bid_index AS
SELECT 	z1.county,
		l1.zip,
        COUNT(*) AS 'Total_Sales',
        ROUND(AVG(l1.list_to_sold_ratio),2) AS 'Bidding_Index'
FROM listings1 AS l1 
JOIN zip1 AS z1
	ON l1.zip = z1.zip
WHERE l1.list_to_sold_ratio BETWEEN 0.9 AND 2.0
GROUP BY z1.county, l1.zip
HAVING Total_Sales > 10
ORDER BY bidding_index DESC;

CREATE OR REPLACE VIEW v_avg_price_sqft AS
SELECT 	z1.zip,
		z1.county,
		l1.type,
        ROUND(AVG(l1.price_per_sqft), 2) AS 'Avg_Price_Per_Sqft' 
FROM listings1 AS l1
LEFT JOIN zip1 AS z1 
	ON l1.zip = z1.zip
WHERE l1.price_per_sqft IS NOT NULL
	AND z1.zip IS NOT NULL
GROUP BY z1.zip, z1.county, l1.type
ORDER BY z1.zip;

CREATE OR REPLACE VIEW v_best_price_market_analysis AS
SELECT 
    l1.type,
    z1.county,
    z1.latitude,
    z1.longtitude,
	ROUND(l1.price_per_sqft, 2) AS 'Price_Per_Sqft',
    ROUND(AVG(l1.price_per_sqft) OVER(PARTITION BY z1.county, l1.type), 2) AS 'Avg_Market_Price_Per_Sqft',
    ROUND(l1.price_per_sqft - AVG(l1.price_per_sqft) OVER(PARTITION BY z1.county, l1.type),2) AS 'Price_vs_Market'
FROM listings1 AS l1
JOIN zip1 AS z1 
	ON l1.zip = z1.zip
WHERE l1.price_per_sqft IS NOT NULL
	AND l1.year_built >= 1970
    AND l1.type NOT IN ('farm', 'land', 'coop', 'other')
ORDER BY Price_vs_Market ASC;

CREATE OR REPLACE VIEW v_county_population AS
SELECT 	county, 
		SUM(est_population) AS 'Est_County_Population' 
FROM zip1
GROUP BY county
ORDER BY Est_County_Population DESC;

CREATE OR REPLACE VIEW v_market_capitalization AS
SELECT 
    z1.county,
    COUNT(l1.zip) AS 'Total_Listings',
    (	SELECT SUM(est_population) 
		FROM zip1 
        WHERE county = z1.county	) AS 'Estimated_Population',
    SUM(l1.last_sold_price) AS 'Sales_Volume'
FROM listings1 AS l1
JOIN zip1 AS z1 ON l1.zip = z1.zip
WHERE l1.last_sold_price IS NOT NULL 
  AND l1.type NOT IN ('farm', 'land', 'coop', 'other')
GROUP BY z1.county;

CREATE OR REPLACE VIEW v_home_type AS
SELECT DISTINCT(type) FROM listings1
WHERE type NOT IN ('farm', 'land', 'coop', 'other');
-- Home types

CREATE OR REPLACE VIEW v_list_price_per_type AS
SELECT 	l1.type, 
		l1.list_price, 
		l1.sqft, 
        l1.price_per_sqft,
        z1.zip, 
        z1.county,
        z1.latitude,
        z1.longtitude
FROM listings1 AS l1
JOIN zip1 AS z1 
	ON l1.zip = z1.zip
WHERE list_price IS NOT NULL
	AND type NOT IN ('farm', 'land', 'coop', 'other')
ORDER BY type ASC, list_price DESC;


