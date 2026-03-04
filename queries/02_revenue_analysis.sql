SELECT 
    EOMONTH(soh.OrderDate) AS OrderMonth,
    SUM(soh.SubTotal) AS Revenue,
    SUM(soh.TotalDue) AS TotalSales,
    CAST(
        SUM(soh.SubTotal) * 100.0 
        / NULLIF(SUM(soh.TotalDue), 0) 
        AS DECIMAL(5,2)) AS RevenueSharePct
FROM SalesLT.SalesOrderHeader soh
GROUP BY EOMONTH(soh.OrderDate)
ORDER BY OrderMonth;


SELECT DISTINCT soh.TaxAmt, soh.Freight,
CAST(
    soh.Freight * 100.0
    / NULLIF(soh.SubTotal, 0)   AS DECIMAL(5,2))
    AS FreightSubTotalRatio,
CAST(
    soh.TaxAmt * 100.0
    / NULLIF(soh.SubTotal, 0)   AS DECIMAL(5,2))
    AS TaxSubtotalRatio
FROM SalesLT.SalesOrderHeader soh;


SELECT 
    MAX(MedianOrderValue) AS MedianOrderValue   
FROM (
    SELECT 
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY soh.SubTotal)
        OVER () AS MedianOrderValue
    FROM SalesLT.SalesOrderHeader soh
) t;


SELECT
    COUNT(*) AS TotalOrders,
    AVG(soh.SubTotal) AS AvgOrderValue
FROM SalesLT.SalesOrderHeader soh;


SELECT TOP 5 soh.CustomerID,
             SUM(soh.SubTotal) AS RevenuePerCustomer
FROM SalesLT.SalesOrderHeader soh
GROUP BY soh.CustomerID
ORDER BY RevenuePerCustomer DESC;

WITH CustomerRevenue AS (
    SELECT 
        soh.CustomerID,
        SUM(soh.SubTotal) AS Revenue

    FROM SalesLT.SalesOrderHeader soh
    GROUP BY soh.CustomerID
),
TOTAL AS (
    SELECT SUM(Revenue) AS TotalRevenue
    FROM CustomerRevenue
)
SELECT TOP 5
    c.CustomerId,
    c.FirstName,
    c.LastName,
    Revenue,
    CAST(
        Revenue * 100.0 / NULLIF((SELECT TotalRevenue FROM TOTAL), 0)
        AS DECIMAL(5,2))
        AS RevenueSharePct,
    DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RevenueRank
FROM CustomerRevenue
JOIN SalesLT.Customer c ON CustomerRevenue.CustomerID = c.CustomerID
ORDER BY Revenue DESC;

WITH CustomerRevenue AS (
    SELECT 
        soh.CustomerID,
        SUM(soh.SubTotal) AS Revenue

    FROM SalesLT.SalesOrderHeader soh
    GROUP BY soh.CustomerID
),
TOTAL AS (
    SELECT SUM(Revenue) AS TotalRevenue
    FROM CustomerRevenue
),
Cumulative AS (
    SELECT 
        CustomerID,
        Revenue,
        SUM(Revenue) OVER (ORDER BY Revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CumulativeRevenue
    FROM CustomerRevenue
),
CumulativePct AS (
    SELECT
        c.CustomerId,
        c.FirstName,
        c.LastName,
        cr.Revenue,
        cr.CumulativeRevenue,
        CAST (
            cr.CumulativeRevenue * 100.0 / NULLIF((t.TotalRevenue), 0)
            AS DECIMAL(5,2))
            AS CumulativeRevenueSharePct,
        CAST(
            cr.Revenue * 100.0 / NULLIF((t.TotalRevenue), 0)
            AS DECIMAL(5,2))
            AS RevenueSharePct,
        DENSE_RANK() OVER (ORDER BY Revenue DESC) AS RevenueRank
    FROM Cumulative cr
    JOIN SalesLT.Customer c ON cr.CustomerID = c.CustomerID
    CROSS JOIN TOTAL t
)
SELECT
    CustomerId,
    FirstName,
    LastName,
    Revenue,
    CumulativeRevenue,
    CumulativeRevenueSharePct,
    RevenueSharePct,
    RevenueRank,
    CASE
        WHEN CumulativeRevenueSharePct <= 80 THEN 'A'
        WHEN CumulativeRevenueSharePct <= 95 THEN 'B'
        ELSE 'C'
    END AS RevenueSegment
FROM CumulativePct
ORDER BY Revenue DESC;