-- Maven Toys: Star Schema with Staging (T-SQL)
-- Target Database: [ML-Sales-Forecasting]

USE [ML-Sales-Forecasting];
GO

-----------------------------------------------------------
-- 1. STAGING TABLES (To accept raw CSV strings)
-----------------------------------------------------------

IF OBJECT_ID('dbo.Stg_Products', 'U') IS NOT NULL DROP TABLE dbo.Stg_Products;
CREATE TABLE dbo.Stg_Products (
    Product_ID NVARCHAR(50),
    Product_Name NVARCHAR(255),
    Product_Category NVARCHAR(100),
    Product_Cost NVARCHAR(50),  -- accepting '$9.99'
    Product_Price NVARCHAR(50)  -- accepting '$15.99'
);

IF OBJECT_ID('dbo.Stg_Stores', 'U') IS NOT NULL DROP TABLE dbo.Stg_Stores;
CREATE TABLE dbo.Stg_Stores (
    Store_ID NVARCHAR(50),
    Store_Name NVARCHAR(255),
    Store_City NVARCHAR(100),
    Store_Location NVARCHAR(100),
    Store_Open_Date NVARCHAR(50) -- accepting '1992-09-18'
);

IF OBJECT_ID('dbo.Stg_Inventory', 'U') IS NOT NULL DROP TABLE dbo.Stg_Inventory;
CREATE TABLE dbo.Stg_Inventory (
    Store_ID NVARCHAR(50),
    Product_ID NVARCHAR(50),
    Stock_On_Hand NVARCHAR(50)
);

IF OBJECT_ID('dbo.Stg_Sales', 'U') IS NOT NULL DROP TABLE dbo.Stg_Sales;
CREATE TABLE dbo.Stg_Sales (
    Sale_ID NVARCHAR(50),
    [Date] NVARCHAR(50), -- Matching CSV header
    Store_ID NVARCHAR(50),
    Product_ID NVARCHAR(50),
    Units NVARCHAR(50)
);

IF OBJECT_ID('dbo.Stg_Calendar', 'U') IS NOT NULL DROP TABLE dbo.Stg_Calendar;
CREATE TABLE dbo.Stg_Calendar (
    [Date] NVARCHAR(50)
);

-----------------------------------------------------------
-- 2. FINAL CLEANED TABLES (Star Schema)
-----------------------------------------------------------

-- Dim_Products
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL DROP TABLE dbo.Products;
CREATE TABLE dbo.Products (
    Product_ID INT PRIMARY KEY,
    Product_Name NVARCHAR(255) NOT NULL,
    Product_Category NVARCHAR(100),
    Product_Cost DECIMAL(18, 2),
    Product_Price DECIMAL(18, 2)
);

-- Dim_Stores
IF OBJECT_ID('dbo.Stores', 'U') IS NOT NULL DROP TABLE dbo.Stores;
CREATE TABLE dbo.Stores (
    Store_ID INT PRIMARY KEY,
    Store_Name NVARCHAR(255) NOT NULL,
    Store_City NVARCHAR(100),
    Store_Location NVARCHAR(100),
    Store_Open_Date DATE
);

-- Fact_Inventory
IF OBJECT_ID('dbo.Inventory', 'U') IS NOT NULL DROP TABLE dbo.Inventory;
CREATE TABLE dbo.Inventory (
    Inventory_ID INT PRIMARY KEY IDENTITY(1,1),
    Store_ID INT,
    Product_ID INT,
    Stock_On_Hand INT,
    Last_Updated DATETIME DEFAULT GETDATE(),
    
    CONSTRAINT FK_Inventory_Store FOREIGN KEY (Store_ID) REFERENCES dbo.Stores(Store_ID),
    CONSTRAINT FK_Inventory_Product FOREIGN KEY (Product_ID) REFERENCES dbo.Products(Product_ID)
);

-- Fact_Sales
IF OBJECT_ID('dbo.Sales', 'U') IS NOT NULL DROP TABLE dbo.Sales;
CREATE TABLE dbo.Sales (
    Sale_ID INT PRIMARY KEY,
    Sale_Date DATE,
    Store_ID INT,
    Product_ID INT,
    Units INT,
    
    CONSTRAINT FK_Sales_Store FOREIGN KEY (Store_ID) REFERENCES dbo.Stores(Store_ID),
    CONSTRAINT FK_Sales_Product FOREIGN KEY (Product_ID) REFERENCES dbo.Products(Product_ID)
);

-- Dim_Calendar
IF OBJECT_ID('dbo.Calendar', 'U') IS NOT NULL DROP TABLE dbo.Calendar;
CREATE TABLE dbo.Calendar (
    [Date] DATE PRIMARY KEY,
    [Year] INT,
    [Month] INT,
    [Month_Name] NVARCHAR(20),
    [Quarter] INT,
    [Day_of_Week] INT,
    [Day_Name] NVARCHAR(20)
);

-- Optimization Indexes
CREATE INDEX IX_Sales_Date ON dbo.Sales(Sale_Date);
GO
