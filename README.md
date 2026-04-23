# 🏠 Washington State Real Estate: Market Dynamics & Investment Analysis

This project demonstrates a full-scale **ETL (Extract, Transform, and Load)** process and **EDA (Exploratory Data Analysis)** using MySQL. Raw housing and demographic data were transformed into a structured relational database to extract actionable insights regarding regional pricing trends, bidding competitiveness, and high-yield investment opportunities.

---

## 🏗️ Architecture and Design

### Phase 1: Data Ingestion
The first phase involved ingesting raw CSV files using the `LOAD DATA INFILE` command with advanced `NULLIF` handling to ensure numerical integrity:
* `washington_real_estate.csv`
* `washington_zip.csv`

#### 📊 Data Dimensions
* **Listings:** Property-specific data including home type, year built, list/sold prices, and physical attributes (sqft, beds, baths, garage).
* **Zip & Demographics:** Geospatial mapping of zip codes to counties, including latitude, longitude, and estimated population counts.

I established a **one-to-many relationship** branching from the `zip` table to the `listings` table, allowing for granular regional aggregation and demographic correlation.

---

## 🗺️ Relational Schema



---

### Phase 2: Staging, Cleaning, and Transformation
The second phase utilized a three-layer staging process to ensure data integrity:

1. **Staging #1 - Data Immutability:** Duplicated raw files into staging tables (`listings1`, `zip1`) to preserve original data while standardizing text casing (`TRIM`) and assigning Primary Keys.
2. **Staging #2 - Quality Assurance:** Validated data integrity by auditing for `NULL` values. Manually rectified regional mapping errors (e.g., assigning specific zip codes to King County) and standardized missing garage counts to `0`.
3. **Staging #3 - Logical Imputation:** Restored missing metrics by calculating `price_per_sqft` where `last_sold_price` and `sqft` were available but the original field was null.

---

### Phase 3: Database Performance Optimization
To ensure rapid execution of complex analytical views and window functions, I applied B-Tree indexing to high-frequency join and filter columns:

```sql
CREATE INDEX idx_listings_zip ON listings1(zip);
CREATE INDEX idx_listings_type ON listings1(type);
CREATE INDEX idx_zip_county ON zip1(county);
