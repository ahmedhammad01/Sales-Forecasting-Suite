import pandas as pd
from sqlalchemy import create_engine
from prophet import Prophet
import urllib
import matplotlib.pyplot as plt

# 1. Database Connection
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

def run_forecast():
    print("Fetching cleaned sales data from SQL Server...")
    # Pull total daily sales for the whole company
    query = """
    SELECT Sale_Date as ds, SUM(Units) as y
    FROM dbo.Sales
    GROUP BY Sale_Date
    ORDER BY Sale_Date
    """
    df = pd.read_sql(query, engine)
    
    if df.empty:
        print("No data found in dbo.Sales. Did you run the cleaning procedure?")
        return

    print(f"Data loaded: {len(df)} days of sales history.")

    # 2. Build Prophet Model
    print("Training Prophet model...")
    model = Prophet(yearly_seasonality=True, daily_seasonality=False)
    model.fit(df)

    # 3. Forecast Future (next 90 days)
    print("Generating 90-day forecast...")
    future = model.make_future_dataframe(periods=90)
    forecast = model.predict(future)

    # 4. Save results to CSV and SQL
    print("Saving forecast results...")
    
    # Prepare data for export
    export_df = forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].copy()
    export_df.rename(columns={
        'ds': 'Forecast_Date', 
        'yhat': 'Predicted_Units', 
        'yhat_lower': 'Min_Expected', 
        'yhat_upper': 'Max_Expected'
    }, inplace=True)
    
    # 5. Calculate Metrics (Real Accuracy)
    print("Evaluating model performance...")
    # Compare historical predictions with actuals to find error
    actuals = df.copy()
    actuals['ds'] = pd.to_datetime(actuals['ds'])
    
    history = forecast[forecast['ds'].isin(actuals['ds'])][['ds', 'yhat']]
    history['ds'] = pd.to_datetime(history['ds'])
    
    comparison = pd.merge(history, actuals, on='ds')
    
    comparison['abs_error'] = (comparison['y'] - comparison['yhat']).abs()
    comparison['perc_error'] = comparison['abs_error'] / comparison['y']
    
    mae = comparison['abs_error'].mean()
    mape = comparison['perc_error'].mean()
    rmse = (comparison['abs_error']**2).mean()**0.5
    accuracy = 1 - mape

    metrics_df = pd.DataFrame([{
        'MAE': mae,
        'MAPE': mape,
        'RMSE': rmse,
        'Accuracy': accuracy,
        'Last_Run': pd.Timestamp.now()
    }])

    # 6. Export to CSV and SQL
    # Save Forecast to CSV
    export_df.to_csv('reports/sales_forecast.csv', index=False)
    # Save Metrics to CSV
    metrics_df.to_csv('reports/model_metrics.csv', index=False)
    
    # Save to SQL "Gold" Tables
    print("Exporting results to SQL Server...")
    export_df.to_sql('Gold_Forecast', engine, if_exists='replace', index=False)
    metrics_df.to_sql('Gold_ModelMetrics', engine, if_exists='replace', index=False)
    
    # 7. Plotting
    fig1 = model.plot(forecast)
    plt.title(f"Company-wide Sales Forecast (Accuracy: {accuracy:.1%})")
    plt.savefig('reports/forecast_plot.png')
    
    print(f"Success! Accuracy: {accuracy:.1%}")
    print("Results saved to [Gold_Forecast], [Gold_ModelMetrics], and 'reports/' folder.")

if __name__ == "__main__":
    run_forecast()
