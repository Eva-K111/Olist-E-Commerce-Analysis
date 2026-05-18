# Olist-E-Commerce-Analysis
End-to-end Business Intelligence project using SQL for data cleaning and Power BI for interactive visualization of Brazilian e-commerce data.
This project involves an end-to-end analysis of the Olist E-Commerce dataset, covering over 100,000 orders from 2016 to 2018. The goal was to transform raw, messy relational data into actionable business insights.
Tech Stack
Database Management: MySQL Workbench (Data Cleaning, Normalization, & KPI Generation).

Data Visualization: Power BI (Star Schema Modeling & Interactive Dashboarding).

Documentation: Microsoft Word & PowerPoint.
Data Engineering Highlights
To ensure data integrity, I performed extensive cleaning in SQL, including:

Translation & Standardization: Converted Portuguese category names to English and standardized labels.

Handling Nulls: Used imputation for missing review titles and product categories.

Schema Design: Engineered a Star Schema with a central product_category_name dimension table for optimized filtering performance.

Referential Integrity: Added Foreign Key constraints after validating orphan records in geolocation and orders tables.
Key Business Insights
Total Revenue: 13.05M.

Total Orders: 109K.

Customer Loyalty: Identified that 97% of customers are one-time buyers, suggesting a need for better retention strategies.

Logistics Analysis: Identified a "Disappointment Gap" in delivery times by comparing actual vs. estimated delivery dates.
