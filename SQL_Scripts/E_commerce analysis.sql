SELECT name
FROM sys.tables
WHERE name LIKE '%commence%';


SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'e_commence_data';

EXEC sp_rename 'dbo.e_commence_data.[Column 0]', 'InvoiceNo', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 1]', 'StockCode', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 2]', 'Description', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 3]', 'Quantity', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 4]', 'InvoiceDate', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 5]', 'UnitPrice', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 6]', 'CustomerID', 'COLUMN';
EXEC sp_rename 'dbo.e_commence_data.[Column 7]', 'Country', 'COLUMN';


SELECT TOP 10 *
FROM dbo.e_commence_data;

SELECT COUNT(DISTINCT InvoiceNo) AS total_transactions
FROM dbo.e_commence_data;

SELECT TOP 20 *
FROM dbo.e_commence_data;

SELECT TOP 10 
       InvoiceNo,
       StockCode,
       Description,
       TRY_CAST(Quantity AS INT) AS Quantity,
       TRY_CAST(InvoiceDate AS DATETIME) AS InvoiceDate,
       TRY_CAST(UnitPrice AS DECIMAL(10,2)) AS UnitPrice,
       TRY_CAST(CustomerID AS INT) AS CustomerID,
       Country
FROM dbo.e_commence_data;


SELECT SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS total_revenue
FROM dbo.e_commence_data
WHERE TRY_CAST(Quantity AS INT) IS NOT NULL
  AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL;


  --This query calculate the top 10 total quantity sold
SELECT TOP 10 
       Description,
       SUM(TRY_CAST(Quantity AS INT)) AS total_sold
FROM dbo.e_commence_data
WHERE TRY_CAST(Quantity AS INT) IS NOT NULL
GROUP BY Description
ORDER BY total_sold DESC;

-- This query calculates the top 10 products by revenue
SELECT TOP 10 
       Description,
       SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS total_revenue
FROM dbo.e_commence_data
WHERE TRY_CAST(Quantity AS INT) IS NOT NULL
  AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL
GROUP BY Description
ORDER BY total_revenue DESC;




-- This query calculates the top 10 total unity sold bycountry
SELECT TOP 10 
       Country,
       SUM(TRY_CAST(Quantity AS INT)) AS total_units_sold
FROM dbo.e_commence_data
WHERE TRY_CAST(Quantity AS INT) IS NOT NULL
GROUP BY Country
ORDER BY total_units_sold DESC;

-- This query calculates monthly trends by revenue
SELECT 
    FORMAT(TRY_CAST(InvoiceDate AS DATETIME), 'yyyy-MM') AS month,
    SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS monthly_revenue
FROM dbo.e_commence_data
WHERE TRY_CAST(Quantity AS INT) IS NOT NULL
  AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL
  AND TRY_CAST(InvoiceDate AS DATETIME) IS NOT NULL
GROUP BY FORMAT(TRY_CAST(InvoiceDate AS DATETIME), 'yyyy-MM')
ORDER BY month;


/*
This query performs RFM analysis:
- Recency: last purchase date
- Frequency: number of orders
- Monetary: total spend
*/
SELECT 
    CustomerID,
    MAX(TRY_CAST(InvoiceDate AS DATETIME)) AS last_purchase,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS monetary_value
FROM dbo.e_commence_data
GROUP BY CustomerID;

--Explanation
--Recency ? MAX(InvoiceDate) gives the most recent purchase date per customer.

--Frequency ? COUNT(DISTINCT InvoiceNo) counts how many orders each customer placed.

--Monetary ? SUM(Quantity * UnitPrice) calculates total spend per customer.

SELECT 
    CustomerID,
    MAX(TRY_CAST(InvoiceDate AS DATETIME)) AS last_purchase,   -- Recency
    COUNT(DISTINCT InvoiceNo) AS frequency,                    -- Frequency
    SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS monetary_value -- Monetary
FROM dbo.e_commence_data
WHERE TRY_CAST(CustomerID AS INT) IS NOT NULL
  AND TRY_CAST(Quantity AS INT) IS NOT NULL
  AND TRY_CAST(UnitPrice AS DECIMAL(10,2)) IS NOT NULL
  AND TRY_CAST(InvoiceDate AS DATETIME) IS NOT NULL
GROUP BY CustomerID;

--This query calculate RFM scores by ranking customers into groups (e.g., 1–5):

WITH rfm AS (
    SELECT 
        CustomerID,
        MAX(TRY_CAST(InvoiceDate AS DATETIME)) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(TRY_CAST(Quantity AS INT) * TRY_CAST(UnitPrice AS DECIMAL(10,2))) AS monetary_value
    FROM dbo.e_commence_data
    GROUP BY CustomerID
)
SELECT 
    CustomerID,
    NTILE(5) OVER (ORDER BY last_purchase DESC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency DESC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value DESC) AS monetary_score
FROM rfm;

--Business Insight
--High RFM scores ? loyal, high?value customers.

--Low recency but high monetary ? previously valuable customers who may need re?engagement.

--High frequency but low monetary ? frequent buyers of low?value items.