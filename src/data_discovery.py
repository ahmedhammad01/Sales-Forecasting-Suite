import pandas as pd
from sqlalchemy import create_engine
import urllib

# Configuration
DB_CONFIG = {
    'server': r'DESKTOP-CHAV2OO\SQLEXPRESS',
    'database': 'ML-Sales-Forecasting'
}

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={DB_CONFIG['server']};"
    f"DATABASE={DB_CONFIG['database']};"
    "Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

def run_check(title, query):
    print(f"\n--- {title} ---")
    try:
        res = pd.read_sql(query, engine)
        if res.empty:
            print("No issues found.")
        else:
            print(res.head(10))
    except Exception as e:
        print(f"Check failed: {e}")

# Discovery Queries
print("Starting Data Discovery...")

run_check("Broken Dates in Sales", 
          "SELECT TOP 5 Sale_Date FROM Stg_Sales WHERE TRY_CONVERT(DATE, Sale_Date) IS NULL")

run_check("Currency Symbols in Products", 
          "SELECT DISTINCT TOP 5 Product_Price FROM Stg_Products WHERE Product_Price LIKE '%$%'")

run_check("Duplicates in Products", 
          "SELECT Product_ID, COUNT(*) as Count FROM Stg_Products GROUP BY Product_ID HAVING COUNT(*) > 1")

run_check("Non-Numeric Units in Sales", 
          "SELECT TOP 5 Units FROM Stg_Sales WHERE TRY_CAST(Units AS INT) IS NULL")

run_check("Data Sample - Stg_Products", "SELECT TOP 5 * FROM Stg_Products")
run_check("Data Sample - Stg_Sales", "SELECT TOP 5 * FROM Stg_Sales")
