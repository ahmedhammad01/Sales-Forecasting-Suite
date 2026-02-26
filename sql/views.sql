-- Maven Toys: Analytical Views
-- Purpose: Business Intelligence layer for inventory and sales performance.

USE [ML-Sales-Forecasting];
GO

-----------------------------------------------------------
-- 1. INVENTORY PERFORMANCE VIEW (Stock-to-Sales Ratio)
-----------------------------------------------------------
-- This helps identify potential stockouts or overstock.
-----------------------------------------------------------

CREATE OR ALTER VIEW dbo.vw_InventoryPerformance
AS
WITH MonthlySales AS (
    SELECT 
        Product_ID,
        Store_ID,
        SUM(Units) AS Total_Units_Sold
    FROM dbo.Sales
    WHERE Sale_Date >= DATEADD(month, -1, (SELECT MAX(Sale_Date) FROM dbo.Sales))
    GROUP BY Product_ID, Store_ID
)
SELECT 
    i.Product_ID,
    i.Store_ID,
    p.Product_Name,
    p.Product_Category,
    s.Store_Name,
    i.Stock_On_Hand,
    ISNULL(ms.Total_Units_Sold, 0) AS Last_Month_Sales,
    -- Stock-to-Sales Ratio
    CASE 
        WHEN ISNULL(ms.Total_Units_Sold, 0) = 0 THEN 99.0 
        ELSE CAST(i.Stock_On_Hand AS FLOAT) / ms.Total_Units_Sold 
    END AS Stock_To_Sales_Ratio
FROM dbo.Inventory i
JOIN dbo.Products p ON i.Product_ID = p.Product_ID
JOIN dbo.Stores s ON i.Store_ID = s.Store_ID
LEFT JOIN MonthlySales ms ON i.Product_ID = ms.Product_ID AND i.Store_ID = ms.Store_ID;
GO

-----------------------------------------------------------
-- 2. SALES TURNOVER VIEW
-----------------------------------------------------------
-- Analysis of how quickly stock is moving.
-----------------------------------------------------------

CREATE OR ALTER VIEW dbo.vw_SalesTurnover
AS
SELECT 
    p.Product_Name,
    p.Product_Category,
    SUM(sa.Units) AS Total_Units,
    SUM(sa.Units * p.Product_Price) AS Total_Revenue,
    SUM(sa.Units * (p.Product_Price - p.Product_Cost)) AS Total_Profit
FROM dbo.Sales sa
JOIN dbo.Products p ON sa.Product_ID = p.Product_ID
GROUP BY p.Product_Name, p.Product_Category;
GO
