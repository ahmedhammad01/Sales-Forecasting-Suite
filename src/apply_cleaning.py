from sqlalchemy import create_engine, text
import urllib

# Configuration
DB_CONFIG = {
    'server': r'DESKTOP-CHAV2OO\SQLEXPRESS',
    'database': 'ML-Sales-Forecasting'
}

# Connection Setup
params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    f"SERVER={DB_CONFIG['server']};"
    f"DATABASE={DB_CONFIG['database']};"
    "Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

def apply_cleaning():
    with engine.connect() as conn:
        print("Creating/Updating Cleaning Stored Procedure...")
        with open('sql/cleaning.sql', 'r') as f:
            sql_content = f.read()
    try:
        with engine.connect() as conn:
            print("Creating/Updating Cleaning Stored Procedure...")
            with open('sql/cleaning.sql', 'r') as f:
                sql_content = f.read()
                
            # SQL Server scripts with GO need to be split
            for statement in sql_content.split('GO'):
                if statement.strip():
                    conn.execute(text(statement))
            conn.commit()
            
            print("Executing Cleaning Procedure...")
            conn.execute(text("EXEC dbo.sp_CleanMavenData"))
            conn.commit()
            print("Data Cleaning Completed Successfully!")
    except Exception as e:
        import traceback
        with open("cleaning_error.log", "w") as f:
            f.write(str(e) + "\n\n")
            f.write(traceback.format_exc())
        print("Data Cleaning Failed. Check cleaning_error.log for details.")

if __name__ == "__main__":
    apply_cleaning()
