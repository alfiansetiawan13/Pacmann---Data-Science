-- Mentoring Week 2 - SQL Query

-- Basic Information about transactional data
-- 1. (10 point) Determine which countries have the most number of invoices (top 10). 
-- Order them by the number of invoices in descending order and if there are 
-- the same number of invoices, sort them by country name in ascending order. 
-- Show Country Name and total number of invoices.
SELECT "BillingCountry" AS "Country", COUNT("Total") AS "Total Invoices"
FROM "Invoice"
GROUP BY "Country"
ORDER BY "Total Invoices" DESC, "Country" ASC
LIMIT 10;

-- 2. The top 10 genres by total sales in the database. 
-- The total sales are obtained by multiplying the quantity of items sold 
-- by their respective prices. Shows Genre Name and Total Sales

-- Create Virtual Tabel
CREATE VIEW "Total Sales by Track and Genre"
AS
SELECT 
	"InvoiceLine"."TrackId",
	"Track"."GenreId",
	("InvoiceLine"."UnitPrice")*("InvoiceLine"."Quantity") AS "Total Sales"
FROM "InvoiceLine"
LEFT JOIN "Track"
	ON "InvoiceLine"."TrackId" = "Track"."TrackId";

-- Final Table
SELECT
	"Genre"."Name",
	SUM("Total Sales by Track and Genre"."Total Sales") AS "Total Sales"
FROM "Total Sales by Track and Genre"
LEFT JOIN "Genre"
	ON "Total Sales by Track and Genre"."GenreId" = "Genre"."GenreId"
GROUP BY "Name"
ORDER BY "Total Sales" DESC
LIMIT 10;

-- 3.Who are the top 10 customers by their total spending? 
-- Shows Customer Name (consist of first name and last name), 
-- Email, and Total Spending
-- Create Virtual Tabel for Customer Name
CREATE VIEW "CustomerName"
AS
SELECT
	"CustomerId",
	"FirstName" || ' ' || "LastName" AS "Customer Name",
	"Email"
FROM "Customer";

-- Final Tabel AS Expected
SELECT 
	"CustomerName"."Customer Name",
	"CustomerName"."Email",
	SUM("Invoice"."Total") AS "Total Spending"
FROM "Invoice"
LEFT JOIN "CustomerName"
	ON "CustomerName"."CustomerId" = "Invoice"."CustomerId"
GROUP BY "Customer Name", "CustomerName"."Email"
ORDER BY "Total Spending" DESC
LIMIT 10;

-- 4. In the results list of countries in number 1, 
-- which city has the most number of invoices? 
-- Show Country Name, City Name and total number of invoices.
-- CREATE Virtual Table
CREATE VIEW "Total_Invoices_by_Country_and_City"
AS
SELECT
	"BillingCountry" AS "Country",
	"BillingCity" AS "City",
	COUNT("Total") AS "Total Invoices"
FROM "Invoice"
GROUP BY "Country", "City"
ORDER BY "Total Invoices" DESC, "Country" ASC;

-- Find the city with the highest number of invoices
SELECT *
FROM "Total_Invoices_by_Country_and_City"
WHERE "Total Invoices" = (SELECT MAX("Total Invoices")
							FROM "Total_Invoices_by_Country_and_City");

-- 5. The product team is looking to add some tracks from new artists to the store 
-- and market them in the United Kingdom. Due to budget constraints for marketing, 
-- the product team needs to select 4 out of 6 songs to include in the store. 
-- The product team assumes that they should choose songs with genres that are popular 
-- in the United Kingdom. 
-- Top 4 Genre in United Kingdom
SELECT
	"Genre"."Name" AS "GenreName", 
	ROUND(SUM("InvoiceLine"."UnitPrice" * "InvoiceLine"."Quantity")) AS "TotalSales"
FROM "Track"
LEFT JOIN "Genre"
	ON "Track"."GenreId" = "Genre"."GenreId"
RIGHT JOIN "InvoiceLine"
	ON "Track"."TrackId" = "InvoiceLine"."TrackId"
RIGHT JOIN "Invoice"
	ON "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
WHERE "Invoice"."BillingCountry" ILIKE 'United Kingdom'
GROUP BY "Genre"."Name"
ORDER BY "TotalSales" DESC
LIMIT 4;

-- 6. The Product Team wants to market albums that are popular in the USA to be marketed in 
-- other countries. Help the product team by searching for the 10 most popular albums in the USA 
-- based on album units sold
-- Top 10 most popular albums in the USA based on album units sold
SELECT
	"Album"."Title" AS "Album Title", 
	SUM("InvoiceLine"."Quantity") AS "Units Sold"
FROM "Track"
LEFT JOIN "Album"
	ON "Track"."AlbumId" = "Album"."AlbumId"
RIGHT JOIN "InvoiceLine"
	ON "Track"."TrackId" = "InvoiceLine"."TrackId"
RIGHT JOIN "Invoice"
	ON "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
WHERE "Invoice"."BillingCountry" ILIKE 'usa'
GROUP BY "Album Title"
ORDER BY SUM("InvoiceLine"."Quantity") DESC
LIMIT 10;

-- 7. Provide a table that aggregates purchase data by country. 
-- In cases where a country has only one customer, group these countries as 'Other.' 
-- The results should be sorted by total sales in descending order.
-- Create CTE for Total Number of Customers by Country
WITH customer_by_country AS (
    SELECT
        "BillingCountry" AS "Country",
        COUNT(DISTINCT "CustomerId") AS "Total Customer",
        SUM("Total") AS "Total Sales",
        SUM("Total") / COUNT(DISTINCT "CustomerId") AS "Avg Customer Sales",
        SUM("Total") / COUNT("InvoiceId") AS "Avg Order Value"
    FROM "Invoice"
    GROUP BY "BillingCountry"
),
-- Create CTE for Grouping "Other." Country
customer_with_country_other AS (
    SELECT
        CASE
            WHEN "Total Customer" = 1 THEN 'Other'
            ELSE "Country"
        END AS "Country",
        SUM("Total Customer") AS "Total Customer",
        SUM("Total Sales") AS "Total Sales",
        ROUND(AVG("Avg Customer Sales"), 3) AS "Avg Customer Sales",
        ROUND(AVG("Avg Order Value"), 3) AS "Avg Order Value"
    FROM customer_by_country
    GROUP BY 
        CASE 
            WHEN "Total Customer" = 1 THEN 'Other'
            ELSE "Country"
        END
)
-- Calling the table
SELECT "Country", "Total Customer", "Total Sales", "Avg Customer Sales", "Avg Order Value"
FROM customer_with_country_other
ORDER BY "Total Sales" DESC;

-- 8. Some genres have low sales, the product team wants to analyze 
-- which genres need to be boosted by carrying out additional promotion or other strategies. 
-- Because each country has different behavior, the product team started by analyzing sales in USA
-- (The total sales are obtained by multiplying the quantity of items sold by their respective prices)
-- Create CTE for Quantity Sales and Total Sales in USA
WITH InvoiceData AS (
    SELECT
        "Genre"."Name" AS "GenreName",
        SUM("InvoiceLine"."Quantity") AS "Quantity Sales",
        SUM("InvoiceLine"."UnitPrice" * "InvoiceLine"."Quantity") AS "Total Sales"
    FROM "Track"
    LEFT JOIN "Genre" ON "Track"."GenreId" = "Genre"."GenreId"
    RIGHT JOIN "InvoiceLine" ON "Track"."TrackId" = "InvoiceLine"."TrackId"
    RIGHT JOIN "Invoice" ON "InvoiceLine"."InvoiceId" = "Invoice"."InvoiceId"
    WHERE "Invoice"."BillingCountry" ILIKE 'usa'
    GROUP BY "Genre"."Name"
),
-- Create CTE for Median Quantity Sales
MedianQuantitySales AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY "Quantity Sales") AS "Median Quantity Sales"
    FROM InvoiceData
)
-- Call The CTE for Low Quantity Sales Genres
SELECT
    i."GenreName",
    i."Quantity Sales",
    i."Total Sales",
    a."Median Quantity Sales"
FROM InvoiceData i
CROSS JOIN MedianQuantitySales a
WHERE i."Quantity Sales" < a."Median Quantity Sales"
ORDER BY i."Quantity Sales";


-- 9. We want to advertise songs to the customer based on how much each customers spent per genre. 
-- Help Marketing Team to find Top genre for each customers with the most spent
--CREATE CTE for Customer Genre Spending 
WITH CustomerGenreSpending AS (
    SELECT
        "Customer"."CustomerId",
        "Customer"."LastName",
        "Customer"."FirstName",
        "Genre"."Name" AS "Genre",
        SUM("InvoiceLine"."UnitPrice" * "InvoiceLine"."Quantity") AS "TotalSpent"
    FROM "Customer"
    JOIN "Invoice" ON "Customer"."CustomerId" = "Invoice"."CustomerId"
    JOIN "InvoiceLine" ON "Invoice"."InvoiceId" = "InvoiceLine"."InvoiceId"
    JOIN "Track" ON "InvoiceLine"."TrackId" = "Track"."TrackId"
    JOIN "Genre" ON "Track"."GenreId" = "Genre"."GenreId"
    GROUP BY "Customer"."CustomerId", "Customer"."LastName", "Customer"."FirstName", "Genre"."Name"
),
-- CREATE CTE for Rank their spending
RankedSpending AS (
    SELECT
        "CustomerId",
        "LastName",
        "FirstName",
        "Genre",
        "TotalSpent",
        DENSE_RANK() OVER (PARTITION BY "CustomerId" ORDER BY "TotalSpent" DESC) AS "Rank"
    FROM CustomerGenreSpending
)
-- Call CTE and filter with only rank = 1
SELECT
    "CustomerId",
    "LastName",
    "FirstName",
    "Genre",
    "TotalSpent",
    "Rank"
FROM RankedSpending
WHERE "Rank" = 1
ORDER BY "CustomerId";

-- 10.The Marketing team wants to increase advertising in countries with customers 
-- who have spent the most money. Help the Marketing team find the top 10 countries 
-- with the highest-spending customers.
-- Create table with top 10 of the most country total spending by customer
SELECT
	"BillingCountry" AS "Country",
	SUM("Total") AS "Total Spending"
FROM "Invoice"
GROUP BY "Country"
ORDER BY "Total Spending" DESC
LIMIT 10;