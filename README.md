# 🛒 eCommerce Store Performance Audit — Olist Brazilian E-Commerce Dataset

> End-to-end data analytics project analysing 100,000 real eCommerce orders to uncover revenue drivers, customer behaviour patterns, delivery performance gaps, and actionable business recommendations.

---

## 📌 Business Problem

An eCommerce marketplace wants answers to three critical questions:

1. **Why is customer retention so low?** — Only 3% of customers repurchase
2. **Which product categories should receive more investment?**
3. **Where are delivery operations failing — and how does it affect customer satisfaction?**

This project answers all three using real data, PostgreSQL, Python, and Power BI.

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| `Python` (Pandas, NumPy, Matplotlib, Seaborn) | Data loading, cleaning, EDA, RFM segmentation |
| `PostgreSQL` + `pgAdmin 4` | SQL analysis — 12 business queries with CTEs, Window Functions, JOINs |
| `Power BI` | Interactive 3-page dashboard with DAX measures and slicers |
| `Excel` | Data validation and cross-checks |
| `GitHub` | Version control and portfolio hosting |

---

## 📁 Project Structure

```
olist-ecommerce-audit/
│
├── data/                          # Raw CSV files from Kaggle
│   └── .gitkeep
│
├── cleaned_data/                  # Phase 1 cleaned outputs
│   ├── olist_master.csv
│   ├── olist_delivered.csv
│   ├── olist_products_clean.csv
│   └── olist_sellers_clean.csv
│
├── notebooks/                     # Jupyter notebooks
│   ├── Phase_1_Data_Loading_Cleaning.ipynb
│   └── Phase_3_EDA_RFM_Segmentation.ipynb
│
├── sql/                           # PostgreSQL queries (Phase 2)
│   └── Phase_2_PostgreSQL_Queries.sql
│
├── sql_results/                   # Query outputs imported into Power BI
│   ├── query1_monthly_revenue.csv
│   ├── query2_category_revenue.csv
│   ├── query3_customer_repeat.csv
│   ├── query4_delivery_by_state.csv
│   ├── query5_review_vs_delay.csv
│   ├── query6_payment_analysis.csv
│   ├── query7_cancellation_rate.csv
│   ├── query8a_seller_performance_by_state.csv
│   ├── query8b_top_10_individual_sellers.csv
│   ├── query8c_product_photo_vs_review_score.csv
│   ├── query9a_orders_by_day.csv
│   ├── query9b_orders_by_hour.csv
│   ├── query10_geographic_revenue.csv
│   ├── query11_freight_analysis.csv
│   ├── query12_seasonal_spikes.csv
│   ├── rfm_segment_summary.csv
│   └── bonus_RFM_segmentation.csv
│
├── dashboard/
│   └── olist_ecommerce_dashboard.pbix
│
├── images/                        # Charts and dashboard screenshots
│
└── README.md
```

---

## 📊 Dataset

- **Source:** [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Size:** 9 CSV files · ~100,000 orders · January 2016 to August 2018
- **Tables:** orders, order_items, customers, payments, reviews, products, sellers, geolocation, category_translation
- **Currency:** Brazilian Real (R$)

---

## 🔄 Project Phases

### Phase 1 — Data Loading & Cleaning (Python)
- Loaded all 9 raw CSVs into Pandas dataframes
- Fixed datetime columns, calculated delivery delay, added time-based features
- Translated Portuguese product categories to English
- Handled nulls across all tables with documented strategies
- Built a master dataframe joining all 9 tables using order_id as the key
- Saved 4 cleaned CSV files to `cleaned_data/`

### Phase 2 — SQL Analysis (PostgreSQL + pgAdmin 4)
**Tool:** `sql/Phase_2_PostgreSQL_Queries.sql` — run directly in pgAdmin 4
**12 business queries demonstrating:** CTEs · Window Functions (LAG, PERCENT_RANK, NTILE) · JOINs · HAVING · CASE WHEN · FILTER clause

| Query | Business Question |
|-------|------------------|
| 1 | Monthly revenue and MoM growth |
| 2 | Top product categories by revenue (Pareto) |
| 3 | Customer repeat purchase rate |
| 4 | Delivery performance by state |
| 5 | Review score vs delivery delay |
| 6 | Payment method analysis |
| 7 | Order cancellation rate by category |
| 8A | Seller performance by state |
| 8B | Top individual seller revenue |
| 8C | Product photos vs review score |
| 9 | Peak shopping hours and days |
| 10 | Geographic revenue by state |
| 11 | Freight-to-price ratio (margin risk) |
| 12 | Seasonal spike detection (Black Friday) |

### Phase 3 — EDA & RFM Segmentation (Python)
- 10 professional charts using Matplotlib and Seaborn
- RFM Customer Segmentation scoring every customer on Recency, Frequency, Monetary
- 9 business segments with actionable marketing recommendations per segment

### Phase 4 — Power BI Dashboard
3-page interactive dashboard with slicers, DAX measures, and page navigation buttons:
- **Page 1 — Sales Overview:** Revenue trend, top categories, payment methods, order status
- **Page 2 — Customer Analysis:** RFM segments, repeat purchase rate, revenue by segment
- **Page 3 — Delivery & Operations:** Delivery time vs review score, state-level analysis

---

## 💡 Key Business Insights

**Insight 1 — Repeat purchase rate is critically low**
97% of customers (90,557 out of 93,358) placed only one order and never returned. The loyal segment (4+ orders) represents just 47 customers. A targeted loyalty programme could increase revenue by 10%+ without new acquisition spend.

**Insight 2 — Late delivery is the #1 driver of 1-star reviews**
Orders rated 1 star had an average delivery time of 20.9 days with a 36.7% late delivery rate. Orders rated 5 stars averaged just 10.3 days with only 2.1% delivered late — a 17x difference. Reducing delivery time below 12 days would be the single highest-impact operational improvement.

**Insight 3 — Top 3 categories drive 45%+ of total revenue**
Health & beauty, bed/bath/table, and sports & leisure consistently dominate. These categories deserve priority in seller recruitment and marketing spend.

**Insight 4 — Northern states have severe logistics problems**
States like RR, AP, and AM have 50%+ late delivery rates and review scores below 3.5. São Paulo by contrast has only 5% late rate and scores 4.22. Fixing logistics in northern states would directly improve satisfaction scores.

**Insight 5 — Credit card installments dominate payment behaviour**
75.9% of orders use credit card with an average of 3.5 installments. This Brazil-specific behaviour (parcelamento) means customers prefer to spread payment — an important insight for checkout and pricing strategy.

---

## 📸 Dashboard Screenshots

### Page 1 — Sales Overview
![Sales Overview](https://github.com/SmitBhavsar008/olist-ecommerce-store-audit/blob/main/images/dashboard_page1_sales_overview.png)

### Page 2 — Customer Analysis
![Customer Analysis](https://github.com/SmitBhavsar008/olist-ecommerce-store-audit/blob/main/images/dashboard_page2_customer_analysis.png)

### Page 3 — Delivery & Operations
![Delivery & Operations](https://github.com/SmitBhavsar008/olist-ecommerce-store-audit/blob/main/images/dashboard_page3_delivery_operations.png)

---

## 🚀 How to Run

```bash
# 1. Clone this repository
git clone https://github.com/SmitBhavsar008/olist-ecommerce-store-audit

# 2. Install Python dependencies
pip install pandas numpy matplotlib seaborn jupyter

# 3. Download Olist dataset from Kaggle and place CSVs in data/ folder
# https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

# 4. Run Phase 1 notebook — data cleaning
#    notebooks/Phase_1_Data_Loading_Cleaning.ipynb

# 5. Run Phase 2 SQL queries in pgAdmin 4
#    Open pgAdmin 4 → create database olist_db
#    Import cleaned_data/ CSVs into PostgreSQL
#    Run sql/Phase_2_PostgreSQL_Queries.sql
#    Export query results as CSVs into sql_results/ folder

# 6. Run Phase 3 notebook — EDA and RFM segmentation
#    notebooks/Phase_3_EDA_RFM_Segmentation.ipynb

# 7. Open dashboard in Power BI Desktop
#    dashboard/olist_ecommerce_dashboard.pbix
```

---

## 📝 Data Quality Notes

The raw Olist dataset contains minor nulls handled as follows:
- 1.38% of orders have no product category — filled with `unknown_category`
- 0.67% of orders have no review score — filled with dataset median
- 8 orders marked delivered but missing delivery timestamp — filled with median delivery date
- 610 products have no seller details — numeric fields set to 0

---

## 👤 Author

**Smit Bhavsar**
Aspiring Data Analyst | eCommerce (Shopify & Magento) | SQL · Python · Power BI

Data Analyst with 7+ years in eCommerce (Shopify & Magento).
Passionate about analyzing customer behavior, revenue trends, and business performance using real-world datasets.

📧 smitbhavsar008@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/smit-bhavsar-5b7995b8/)
🐙 [GitHub](https://github.com/SmitBhavsar008)

---

*Dataset provided by Olist under CC BY-NC-SA 4.0 license*
