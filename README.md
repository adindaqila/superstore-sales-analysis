# Sales Performance Analysis: Superstore
SQL analysis and a Looker Studio dashboard using the public Kaggle Superstore dataset. This project uses sample retail data, not real company data.

**Dashboard:** [View Looker Studio Dashboard](https://datastudio.google.com/reporting/c344b7f9-3223-4d6d-9cb1-1101f5c63686)

## Problem Statement
Analyze sales and profit patterns across time, region, product sub-category, and discount levels to identify where and when profitability is low.

## Tools
MySQL (MariaDB via phpMyAdmin) · Looker Studio · Excel

## Method
- Imported the CSV as text, then converted dates and numeric columns in SQL.
- Checked row counts, date conversion, and repeated order-product combinations.
- Analyzed sales, profit, profit margins, and discount bands.
- Built a one-page Looker Studio dashboard using aggregated query results.

## Key Results
- Total sales reached **$2.30M**, with **$286K profit** and a **12.5% profit margin**.
- Orders with discounts above 20% were associated with a combined loss of approximately $135K.
- The Central region had the lowest profit margin (7.9%) and the highest average discount (24.0%).
- Tables, Bookcases, and Supplies recorded overall losses.

## Recommendations
- Review the discount policy, particularly for discounts above 20%.

## Limitations
- This is a descriptive analysis; the findings show associations, not causation.
- The dataset contains public US retail sample data, not actual company data.
- The dataset does not include sufficient cost or promotion details to explain all loss patterns.

## Files
- `superstore_analysis.sql` — data checks, cleaning, and analysis queries.
- `data/` — CSV query results used for the dashboard.
- `dashboard/dashboard.png` — dashboard screenshot.
