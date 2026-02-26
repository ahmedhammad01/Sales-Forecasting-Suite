-- Maven Toys: Data Cleaning Procedures (T-SQL)
-- Target Database: [ML-Sales-Forecasting]

USE [ML-Sales-Forecasting];
GO

-----------------------------------------------------------
-- 1. CLEANING STORED PROCEDURE
-----------------------------------------------------------

IF OBJECT_ID('dbo.sp_CleanMavenData', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_CleanMavenData;
GO

CREATE PROCEDURE dbo.sp_CleanMavenData
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;

        -- A. Clean and Insert Dim_Products
        INSERT INTO dbo.Products (Product_ID, Product_Name, Product_Category, Product_Cost, Product_Price)
        SELECT DISTINCT
            CAST(Product_ID AS INT),
            Product_Name,
            Product_Category,
            CAST(REPLACE(REPLACE(Product_Cost, '$', ''), ' ', '') AS DECIMAL(18,2)),
            CAST(REPLACE(REPLACE(Product_Price, '$', ''), ' ', '') AS DECIMAL(18,2))
        FROM dbo.Stg_Products
        WHERE Product_ID NOT IN (SELECT Product_ID FROM dbo.Products);

        -- B. Clean and Insert Dim_Stores
        INSERT INTO dbo.Stores (Store_ID, Store_Name, Store_City, Store_Location, Store_Open_Date)
        SELECT DISTINCT
            CAST(Store_ID AS INT),
            Store_Name,
            Store_City,
            Store_Location,
            CAST(Store_Open_Date AS DATE)
        FROM dbo.Stg_Stores
        WHERE Store_ID NOT IN (SELECT Store_ID FROM dbo.Stores);

        -- C. Clean and Insert Fact_Inventory
        INSERT INTO dbo.Inventory (Store_ID, Product_ID, Stock_On_Hand)
        SELECT 
            CAST(Store_ID AS INT),
            CAST(Product_ID AS INT),
            CAST(Stock_On_Hand AS INT)
        FROM dbo.Stg_Inventory stg
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.Inventory i 
            WHERE i.Store_ID = CAST(stg.Store_ID AS INT) 
            AND i.Product_ID = CAST(stg.Product_ID AS INT)
        );

        -- D. Clean and Insert Fact_Sales
        INSERT INTO dbo.Sales (Sale_ID, Sale_Date, Store_ID, Product_ID, Units)
        SELECT 
            CAST(Sale_ID AS INT),
            CAST([Date] AS DATE), -- Maps from Stg_Sales.[Date]
            CAST(Store_ID AS INT),
            CAST(Product_ID AS INT),
            CAST(Units AS INT)
        FROM dbo.Stg_Sales
        WHERE Sale_ID NOT IN (SELECT Sale_ID FROM dbo.Sales);

        -- E. Clean and Insert Dim_Calendar
        INSERT INTO dbo.Calendar ([Date], [Year], [Month], [Month_Name], [Quarter], [Day_of_Week], [Day_Name])
        SELECT 
            DISTINCT CAST([Date] AS DATE),
            YEAR(CAST([Date] AS DATE)),
            MONTH(CAST([Date] AS DATE)),
            DATENAME(MONTH, CAST([Date] AS DATE)),
            DATEPART(QUARTER, CAST([Date] AS DATE)),
            DATEPART(WEEKDAY, CAST([Date] AS DATE)),
            DATENAME(WEEKDAY, CAST([Date] AS DATE))
        FROM dbo.Stg_Calendar
        WHERE CAST([Date] AS DATE) NOT IN (SELECT [Date] FROM dbo.Calendar);

        COMMIT TRANSACTION;
        PRINT 'Data cleaning and migration completed successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        PRINT 'Error occurred during cleaning: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
