SELECT * FROM listings1;
SELECT * FROM zip1;
SELECT *
FROM listings1
JOIN zip1
	ON listings1.zip = zip1.zip;

#######################################################################################################################

SELECT DISTINCT(`type`)
FROM listings1;
-- Types of Homes

SELECT COUNT(*) AS Total_Listings
FROM listings1;
-- Total Listings

SELECT DISTINCT(county)
FROM zip1;
-- List of Counties

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
-- Top 10 Most Expensive Counties to buy a Home in Washington

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
-- List of Homes with High Competition (1.0 and above in List_to_Sold_ratio) 

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
-- List of Counties with the Highest Bidding Index (competition per county)

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
-- Average Price Per Sqft by County, Zip, and Type 

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
-- Market Analysis for Modern Homes with the best price per sqft vs avg market (renovation potential)

SELECT 	county, 
		SUM(est_population) AS 'Est_County_Population' 
FROM zip1
GROUP BY county
ORDER BY Est_County_Population DESC;
-- Total Population by County

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
-- Market Capitalization and Demographic Reach Analysis - Analysis for Investment opportunities, buy&sell opportunities


SELECT DISTINCT(type) FROM listings1
WHERE type NOT IN ('farm', 'land', 'coop', 'other');
-- Home types

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
-- price_list and location per type












