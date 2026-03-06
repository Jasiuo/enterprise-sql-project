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

WITH DailyRev AS (
SELECT
    soh.OrderDate As OrderDate,
    SUM(soh.SubTotal) AS RevenuePerDay,
    SUM(soh.TotalDue) AS TotalSalePerDay
FROM SalesLT.SalesOrderHeader soh
GROUP BY soh.OrderDate

)
SELECT
    dr.OrderDate,
    dr.RevenuePerDay,
    AVG(dr.RevenuePerDay) OVER (
        ORDER BY dr.OrderDate
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS RollingAverage
FROM DailyRev dr
ORDER BY dr.OrderDate;

WITH FirstOrders AS (
    SELECT
    soh.CustomerId,
    soh.SubTotal,
    soh.OrderDate,
    MIN(soh.OrderDate) OVER (PARTITION BY soh.CustomerID) AS FirstOrderDate
    FROM SalesLT.SalesOrderHeader soh

),
CstmrType AS(
    SELECT
    fo.CustomerId,
    fo.SubTotal,
    CASE 
        WHEN fo.OrderDate = fo.FirstOrderDate THEN 'New'
        ELSE 'Returning'
        END AS CustomerType
    FROM FirstOrders fo
)
SELECT 
    c.CustomerType,
    SUM(c.SubTotal) AS Revenue,
    AVG(c.Subtotal) AS AvgOrderValue,
    COUNT(*) AS TotalOrders,
    CAST (
    SUM(c.SubTotal) * 100.0
    / SUM(SUM(c.SubTotal)) OVER () AS DECIMAL(5,2)) AS CustomerTypeRatio
FROM CstmrType c
GROUP BY c.CustomerType;

WITH CstmrOrdersCount AS (
    SELECT 
        soh.CustomerID,
        COUNT(*) as Orders
    FROM SalesLT.SalesOrderHeader soh
    GROUP BY soh.CustomerID
),
CstmrOrderType AS (
    SELECT
    coc.CustomerID,
    coc.Orders,
    CASE
        WHEN coc.Orders = 1 THEN 'SingleOrderCustomer'
        ELSE 'MultiOrderCustomer'
    END AS CustomerType2
    FROM CstmrOrdersCount coc
)
SELECT 
cot.CustomerType2,
COUNT(*) as ClientsCount
FROM CstmrOrderType cot
GROUP BY cot.CustomerType2;

WITH PrvOrders AS (
    SELECT 
        soh.CustomerID,
        soh.OrderDate,
        LAG(soh.OrderDate) OVER (PARTITION BY soh.CustomerID ORDER BY soh.OrderDate) AS PreviousOrderDate
    FROM SalesLT.SalesOrderHeader soh
),
DateSinceLast AS (
SELECT
    po.CustomerID,
    DATEDIFF(DAY, po.PreviousOrderDate, po.OrderDate) AS DaysBetweenOrders
FROM PrvOrders po
WHERE PreviousOrderDate IS NOT NULL
),
MedianCalc AS(
    SELECT
    CustomerId,
    DaysBetweenOrders,
    PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY DaysBetweenOrders) OVER (PARTITION BY CustomerId) AS MedianGap
    FROM DateSinceLast
),

CustomerStats AS (
SELECT
    CustomerId,
    AVG(DaysBetweenOrders) AS AvgGap,
    MAX(DaysBetweenOrders) AS MaxGap,
    MAX(MedianGap) AS MedianGap
FROM MedianCalc
GROUP BY CustomerId
)
SELECT
    CustomerId,
    AvgGap,
    MedianGap,
    CASE 
        WHEN AvgGap <= 7 THEN 'Highly Engaged (0-7 days)'
        WHEN AvgGap <= 30 THEN 'Engaged (8-30 days)'
        ELSE 'At Risk (>30 days)'
    END AS RecencySegment
    FROM CustomerStats;


