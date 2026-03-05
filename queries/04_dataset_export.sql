SELECT
soh.CustomerId,
soh.OrderDate,
soh.SalesOrderNumber,
soh.Subtotal,
soh.TaxAmt,
soh.Freight,
soh.TotalDue,
sod.ProductID,
p.Name AS ProductName,
sod.OrderQty,
sod.LineTotal
FROM SalesLT.SalesOrderHeader soh
JOIN SalesLT.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN SalesLT.Product p ON sod.ProductID = p.ProductID;