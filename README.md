# 🛒 E-Commerce Sales Analysis & RFM Segmentation

## 📌 Project Overview
End-to-end SQL analysis of a real UK e-commerce dataset containing 
541,909 transactions. The project covers data exploration, cleaning, 
sales analysis, and customer segmentation using the RFM framework.

## 🛠️ Tools Used
- SQL Server (SSMS)
- Dataset: [UK E-Commerce Data — Kaggle](https://www.kaggle.com/datasets/carrie1/ecommerce-data)

## 📊 Key Findings
- Cleaned 135,080+ records with missing customer data and 
  10,624 negative quantity entries
- **2,668 lost customers** represent **$2.51M in revenue at risk**
- Only **14 Champion customers** generate **$1.18M** in revenue
- **1,563 new customers** ($3.49M) need retention strategies 
  to avoid becoming lost

## 🔍 Analysis Steps
| Step | Description |
|------|-------------|
| 1 | Data Exploration — null values, anomalies |
| 2 | Data Cleaning — removed invalid records (397,884 clean rows) |
| 3 | Revenue Calculation — computed line-level revenue |
| 4 | Sales by Country — top 10 markets by revenue |
| 5 | Top Products — best performing SKUs |
| 6 | Monthly Trend — revenue growth with MoM variance |
| 7 | Top Customers — highest value accounts |
| 8 | RFM Analysis — Recency, Frequency, Monetary scoring |
| 9 | Customer Segmentation — Champions, Loyal, At Risk, Lost |

## 💡 Business Insights
- **Lost segment** is the highest priority — largest group (2,668) 
  with significant historical spend ($941 avg monetary)
- **Loyal Customers** (90 accounts, $18K avg spend) are 
  close to Champion status — strong candidates for VIP programs
- **New Customers** represent the largest revenue opportunity 
  if retention improves

## 📁 Files
- `ecommerce_analysis.sql` — All queries from exploration to segmentation
