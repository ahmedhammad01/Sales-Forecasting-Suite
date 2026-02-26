-- Maven Toys: Inventory Reorder Logic
-- Purpose: Prescriptive analytics to automate stock ordering.

USE [ML-Sales-Forecasting];
GO

-----------------------------------------------------------
-- 1. CREATE THE ORDERS TABLE
-----------------------------------------------------------
-- This table acts as the "Queue" for store managers.
-----------------------------------------------------------
IF OBJECT_ID('dbo.Reorder_Requests', 'U') IS NOT NULL DROP TABLE dbo.Reorder_Requests;

CREATE TABLE dbo.Reorder_Requests (
    Request_ID INT PRIMARY KEY IDENTITY(1,1),
    Store_ID INT,
    Product_ID INT,
    Current_Stock INT,
    Suggested_Order_Qty INT,
    Request_Date DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50) DEFAULT 'Pending',
    
    CONSTRAINT FK_Reorder_Store FOREIGN KEY (Store_ID) REFERENCES dbo.Stores(Store_ID),
    CONSTRAINT FK_Reorder_Product FOREIGN KEY (Product_ID) REFERENCES dbo.Products(Product_ID)
);
GO

-----------------------------------------------------------
-- 2. CREATE THE AUTOMATIC REORDER PROCEDURE
-----------------------------------------------------------
-- Logic: If Stock is less than 2x the average weekly sales, reorder.
-----------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_GenerateReorders
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear old pending requests to avoid duplicates
    DELETE FROM dbo.Reorder_Requests WHERE Status = 'Pending';

    -- Identify products that need reordering
    INSERT INTO dbo.Reorder_Requests (Store_ID, Product_ID, Current_Stock, Suggested_Order_Qty)
    SELECT 
        i.Store_ID,
        i.Product_ID,
        i.Stock_On_Hand,
        CAST((ms.Avg_Weekly_Sales * 4) AS INT) -- Order 4 weeks worth (1 month)
    FROM dbo.Inventory i
    JOIN (
        -- Calculate Avg Weekly Sales over the last 4 weeks of data
        SELECT 
            Store_ID, 
            Product_ID, 
            SUM(CAST(Units AS FLOAT)) / 4.0 AS Avg_Weekly_Sales
        FROM dbo.Sales
        WHERE Sale_Date >= DATEADD(week, -4, (SELECT MAX(Sale_Date) FROM dbo.Sales))
        GROUP BY Store_ID, Product_ID
    ) ms ON i.Store_ID = ms.Store_ID AND i.Product_ID = ms.Product_ID
    WHERE i.Stock_On_Hand < (ms.Avg_Weekly_Sales * 2); -- Threshold: 2 weeks of safety stock

    PRINT 'Reorder requests generated for all stores and products below threshold.';
END;
GO
