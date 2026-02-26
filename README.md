# 🧸 Maven Toys — AI-Driven Sales Forecasting & Inventory Suite

> *An end-to-end data analytics project — from raw CSV files to a predictive, AI-powered Business Intelligence dashboard.*

![Executive Overview](dashboard/Dashboard%20Page%201.png)
![AI Forecasting](dashboard/Dashboard%20Page%202.png)

---

## 📌 Project Overview

I built this project to go beyond basic reporting. Most dashboards just show what happened in the past. I wanted to build something that can tell a business what is going to happen in the next 90 days — and also alert the team before they run out of stock.

This is a complete data solution that I built from scratch using the **Maven Toys** dataset. It covers everything from raw data in CSV files, all the way to an advanced Power BI dashboard with Machine Learning predictions.

**What this project can answer:**
- 💰 How much revenue will we make in the next 90 days?
- 📦 Which products will run out of stock first?
- 📊 How accurate is our AI forecasting model?
- 🏬 Which store locations are performing the best?

---

## 🖥️ Dashboard Preview

### Page 1 — Executive Overview
This page is designed for the CEO or manager. It gives a quick overview of:
- Total Revenue, Profit, and Net Margin KPIs with YoY comparison
- Monthly Sales vs Year-over-Year Growth (Combo Chart)
- Revenue breakdown by Product Category (Donut Chart)
- Sales performance by Store Location (Bar Chart)
- Top 10 Performing Products by Revenue (Table)

### Page 2 — AI Forecasting
This page is the "brain" of the dashboard. It shows:
- 4 live KPI cards: Forecasted Revenue, Model Accuracy, Earliest Stockout, and Inventory Health
- **Custom-built Prophet Sales Forecast Chart** showing historical actuals + 90-day prediction with confidence bands
- Model Performance monitor showing real metrics (MAE, RMSE, MAPE)
- Stockout Risk Monitor — a prioritized list of products closest to running out
- Forecast vs Actual by Category — side-by-side comparison of AI predictions vs real sales

---

## ⚙️ Technical Architecture

The project is divided into 3 layers:

```
CSV Raw Data  →  SQL Server (Cleaned & Structured)  →  Python (AI Model)  →  Power BI (Dashboard)
```

### Layer 1 — Data Engineering (SQL Server)

I designed a **Star Schema** database with staging tables and production tables.

| Table | Type | Description |
|---|---|---|
| `Products` | Dimension | Product info, cost, and price |
| `Stores` | Dimension | Store name, city, and location |
| `Calendar` | Dimension | Date table for time intelligence |
| `Sales` | Fact | Every transaction with date, store, product, units |
| `Inventory` | Fact | Stock levels per store and product |
| `Gold_Forecast` | Gold | AI predicted units for next 90 days |
| `Gold_ModelMetrics` | Gold | Real accuracy metrics from Prophet model |

**SQL scripts included:**
- `sql/schema.sql` — Creates all staging + production tables
- `sql/cleaning.sql` — Stored procedure for data cleaning (handles `$` in prices, NULL values, date formatting)
- `sql/views.sql` — Analytical views for Stock-to-Sales ratio and Sales Turnover
- `sql/reorder_logic.sql` — Reorder point logic to detect low stock

### Layer 2 — Machine Learning (Python + Prophet)

I used **Facebook Prophet** — a time-series forecasting library — to predict future sales.

**Python scripts included:**
- `src/etl.py` — Reads all CSV files and loads them into SQL Staging tables
- `src/apply_cleaning.py` — Calls the SQL stored procedure to clean and move data to production tables
- `src/data_discovery.py` — Audits the data for missing values, data types, and unusual records
- `src/forecast.py` — Trains the Prophet model and exports predictions to SQL Gold tables

**How the forecast works:**
1. Fetches historical daily sales from `dbo.Sales`
2. Trains a Prophet model with yearly seasonality
3. Generates 90-day future predictions
4. Calculates real accuracy metrics (MAE, MAPE, RMSE)
5. Saves everything back to SQL and to the `reports/` folder

**Model Results:**
- ✅ **Accuracy**: 87.4%
- 📉 **MAE**: ~208 units
- 📉 **RMSE**: ~296 units

### Layer 3 — Business Intelligence (Power BI)

The dashboard uses **Glassmorphism design** with a dark "Command Center" theme.

- **Custom Visual**: I built a custom TypeScript/SVG visual specifically for displaying the Prophet forecast with the confidence band and the "Now" line separator
- **Advanced DAX**: Complex measures for YoY growth, conditional color logic (Green/Red alerts), and risk scoring
- **Dynamic Alerting**: KPI cards change color automatically — Green when things are good, Red/Amber when action is needed

---

## 🗂️ Repository Structure

```
ML-Sales-Forecasting-Suite/
│
├── src/                    # Python pipeline scripts
│   ├── etl.py              # CSV to SQL ingestion
│   ├── apply_cleaning.py   # Trigger SQL data cleaning
│   ├── data_discovery.py   # Data audit and profiling
│   └── forecast.py         # Prophet ML model + export
│
├── sql/                    # All T-SQL scripts
│   ├── schema.sql          # Database and table design
│   ├── cleaning.sql        # Data cleaning stored procedure
│   ├── views.sql           # Analytical business logic views
│   └── reorder_logic.sql   # Inventory risk detection
│
├── data/                   # Raw CSV source files
│   ├── sales.csv
│   ├── products.csv
│   ├── stores.csv
│   ├── inventory.csv
│   └── calendar.csv
│
├── dashboard/              # Dashboard screenshots
│   ├── Dashboard Page 1.png
│   └── Dashboard Page 2.png
│
├── reports/                # Auto-generated forecast outputs
│   ├── sales_forecast.csv
│   └── model_metrics.csv
│
├── requirements.txt        # Python dependencies
├── .gitignore
└── README.md
```

---

## 🛠️ How to Run This Project

### Requirements
- Microsoft SQL Server (Express edition works fine)
- ODBC Driver 17 for SQL Server
- Python 3.9 or higher

### Step-by-Step Setup

**1. Set up the Database**
```sql
-- Run this in SQL Server Management Studio (SSMS)
-- Execute sql/schema.sql first to create all tables
```

**2. Set up Python environment**
```bash
pip install -r requirements.txt
```

**3. Update your database server name**

Open `src/etl.py` and `src/forecast.py` and change this line to match your SQL Server instance:
```python
'server': r'YOUR_SERVER_NAME\SQLEXPRESS'
```

**4. Run the pipeline in order**
```bash
# Step 1: Load raw data
python src/etl.py

# Step 2: Clean the data
python src/apply_cleaning.py

# Step 3: Run the AI forecast
python src/forecast.py
```

**5. Open the Dashboard**

Open `dashboard/Dashboard.pbix` in Power BI Desktop and refresh the data source connection to your local SQL Server.

---

## 🧰 Tech Stack

| Tool | Purpose |
|---|---|
| **SQL Server (T-SQL)** | Database design, ETL, stored procedures, views |
| **Python (Pandas)** | Data processing and pipeline automation |
| **Facebook Prophet** | Time-series sales forecasting |
| **SQLAlchemy + PyODBC** | Python to SQL Server connection |
| **Power BI Desktop** | Dashboard design and visualization |
| **TypeScript + SVG** | Custom Power BI visual for the forecast chart |
| **DAX** | Business logic, KPIs, and conditional formatting|

---

## 📊 Dataset

This project uses the **Maven Toys** dataset, which contains:
- ~830,000 sales transactions
- 50 store locations across Mexico
- 35 product categories
- Sales data from January 2022 to September 2023

Source: [Maven Analytics](https://www.mavenanalytics.io/data-playground)

---

## 👤 About Me

I am a Data Analyst with experience in building complete data solutions from raw data to interactive dashboards. I am passionate about combining traditional analytics with Machine Learning to make dashboards more forward-looking and actionable.

**Connect with me:**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ahmed%20Hammad-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ahmed-hammad-b265a4173/)
[![GitHub](https://img.shields.io/badge/GitHub-ahmedhammad01-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ahmedhammad01)

---

*If you found this project useful, please give it a ⭐ on GitHub!*
