SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;
--There are 3 schemas existing in database, including:
--dbo schema
--Sales LT schema
--sys schema
--Sales tables included in this database are: SalesOrderDetail, SalesOrderHeader
--Product tables included in this database are: Product, ProductCategory, ProductDescription, ProductModel, ProductModelProductDescription, vProductAndDescription, vProductModelCatalogDescription
--Customer tables included in this database are: Address, Customer, CustomerAddress,

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SalesOrderHeader';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Customer';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Product';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SalesOrderDetail';

SELECT TOP 5
    SalesOrderHeader.SalesOrderNumber, SalesOrderHeader.OrderDate, Customer.FirstName, Customer.LastName, SalesOrderHeader.TotalDue
FROM SalesLT.SalesOrderHeader
JOIN SalesLT.Customer
ON SalesOrderHeader.CustomerID = Customer.CustomerID;

