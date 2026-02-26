import pandas as pd
import pyodbc
import os
from sqlalchemy import create_engine

# Configuration
DB_CONFIG = {
    'server': r'DESKTOP-CHAV2OO\SQLEXPRESS', # Updated to user instance
    'database': 'ML-Sales-Forecasting',
    'driver': '{SQL Server}'
}

# CSV Paths
DATA_DIR = r'd:\DATA ANALYST\PROJECTS\ML-Sales-Forecasting-Suite\data'
FILES = {
    'Products': 'products.csv',
    'Stores': 'stores.csv',
    'Sales': 'sales.csv',
    'Inventory': 'inventory.csv',
    'Calendar': 'calendar.csv'
}

def clean_currency(value):
    """Removes $ and spaces, converts to float."""
    if isinstance(value, str):
        return float(value.replace('$', '').strip())
    return value

def load_data():
    # Helper to push to SQL
    def push_to_staging(engine, df, table_name):
        print(f"Uploading to {table_name}...")
        df.to_sql(table_name, engine, if_exists='append', index=False)

    # 1. Load CSVs (AS IS, NO CLEANING)
    print("Reading CSVs...")
    df_products = pd.read_csv(os.path.join(DATA_DIR, FILES['Products']))
    df_stores = pd.read_csv(os.path.join(DATA_DIR, FILES['Stores']))
    df_inventory = pd.read_csv(os.path.join(DATA_DIR, FILES['Inventory']))
    df_sales = pd.read_csv(os.path.join(DATA_DIR, FILES['Sales']))
    df_calendar = pd.read_csv(os.path.join(DATA_DIR, FILES['Calendar']))

    # Connection - Confirmed working string
    import urllib
    params = urllib.parse.quote_plus(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        f"SERVER={DB_CONFIG['server']};"
        f"DATABASE={DB_CONFIG['database']};"
        "Trusted_Connection=yes;"
    )
    conn_str = f"mssql+pyodbc:///?odbc_connect={params}"
    engine = create_engine(conn_str)
    
    try:
        # Load into STAGING tables
        push_to_staging(engine, df_products, 'Stg_Products')
        push_to_staging(engine, df_stores, 'Stg_Stores')
        push_to_staging(engine, df_inventory, 'Stg_Inventory')
        push_to_staging(engine, df_sales, 'Stg_Sales')
        push_to_staging(engine, df_calendar, 'Stg_Calendar')
        print("Raw Data Ingestion Completed Successfully!")
        
    except Exception as e:
        import traceback
        with open("etl_error.log", "w") as f:
            f.write(str(e) + "\n\n")
            f.write(traceback.format_exc())
        print(f"Error during raw ingestion. Check etl_error.log for details.")

if __name__ == "__main__":
    load_data()
