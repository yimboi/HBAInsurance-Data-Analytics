# HBAInsurance-Data-Analytics
A comprehensive data analytics project focused on uncovering insights related to premium loss, sum assured, and product imbalances within an insurance portfolio using SQL, Python, and PowerBI.

# Insurance Data Analytics Project - HBA

## Project Overview

This project aims to analyze the financial performance of insurance policies for HBA, with a focus on identifying factors contributing to **premium losses**, evaluating the relationship between **sum assured** and **premiums charged**, and analyzing product-level imbalances. The analysis was performed using SQL, Python, and PowerBI, leveraging AI-driven tools like PowerBI’s Decomposition Tree for diagnostic insights.

## Key Metrics

- **Total Sum Assured**: RM 1.57 billion
- **Total Premiums Charged**: RM 41.74 million
- **Loss Ratio**: 2.78%
- **Client Lifetime Value**: RM 143,000
- **Number of Policies**: 4,017
- **Number of Clients**: 3,874

## Objectives

1. **Premium Loss Analysis**: Identify key variables contributing to premium losses using diagnostic tools.
2. **Product Imbalance Analysis**: Evaluate the disparities between **sum assured** and **premiums paid** across product types.
3. **Recommendations for Rebalancing**: Propose strategies to rebalance the product offerings and improve financial performance.

## Tools Used

- **SQL**: For data storage and querying, enabling complex joins and data slicing.
- **Python**: For data cleansing, manipulation, and exploratory data analysis (EDA).
- **PowerBI**: To create interactive dashboards and leverage AI-driven decomposition trees for diagnostic analysis.

## Diagnostic Analysis Findings

Through the use of PowerBI's Decomposition Tree, the following key factors were found to contribute to **high premium losses**:

1. **Payment Mode 12**: Contributed RM 1,008,408 in losses (annual premium payments)
2. **Insurance Product E**: Contributed RM 821,280 in losses
3. **Marital Status (Married)**: Contributed RM 560,472
4. **Gender (Male)**: Contributed RM 304,944
5. **Income Band Q1 (Lowest quartile)**: Contributed RM 166,392
6. **Location (Selangor)**: Contributed RM 83,784

Slicing and dicing further to analyse key factors for **high premium losses** for Product A:

1. **Payment Mode 12**: Contributed RM 186,768 in losses (annual premium payments)
2. **Gender (Female)**: Contributed RM 128,808
3. **Income Band Q2 (Second Lower quartile)**: Contributed RM 80,224
4. **Age Group (B) **: Contributed RM 49,476
5. **Marital Status (Single)**: Contributed RM 49,476
6. **Location (Selangor)**: Contributed RM 30,265

Slicing and dicing further to analyse key factors for **high premium losses** for Product E:

1. **Payment Mode 12**: Contributed RM 821,280 in losses (annual premium payments)
2. **Marital Status (Married)**: Contributed RM 560,472
3. **Gender (Male)**: Contributed RM 304,944
4. **Income Band Q1 (Lowest quartile)**: Contributed RM 166,392
5. **Location (Selangor)**: Contributed RM 83,784
6. **Age Group (B)**: Contributed RM 30,816

## Analytical Process

1. **Data Segmentation**: Policies were segmented by product type.
2. **Statistical Analysis**: Median sum assured and average premiums were calculated for each product group.
3. **Imbalance Detection**: Disparities between individual policies and product-level metrics were identified.
4. **AI-Driven Insights**: PowerBI's Decomposition Tree was used to uncover key contributors to premium losses.

## Conclusion

This analysis highlights the importance of adjusting premium structures, product features, and pricing strategies to align better with policyholder demographics and payment modes. Recommendations include:

- Adjust pricing strategies for Product E and Product A to reduce premium losses.
- Offer more flexible payment modes to reduce the impact of annual payment defaults.
- Tailor policies and communication for specific demographic groups to improve retention.

## How to Use This Repo

1. **Clone the repository**:
   ```bash
   git clone https://github.com/YourUsername/Insurance-Data-Analytics-HBA.git
   
## Structuring workflow for the analysis
### 1. Data Loading and Preparation
- **Extract Data**: Load the **Customer** and **Account** datasets from raw data into Python first
- **Clean Data**: Handle missing values and normalize data types (e.g., dates, numerical fields) in Python

  *Tools used*:  Python

### 2. Exploratory Data Analysis (EDA) in Python
- **Analyze Distributions**: Perform basic EDA to understand the distributions of key variables (e.g., `SUM_ASSURED`, `MODAL_PREMIUM`).
- **Detect Outliers**: Identify and flag outliers , inconsistencies in the data & handle missing values.

  *Tools used*:  Python (Pandas, numpy, matplotlib, seaborn, scipy)

### 3. Data Loading to the database
- **Create Database and Tables**: Set up the database and create the necessary tables for `Account` and `Customer` data in SQL.
- **Load Data**: Use `BULK INSERT` or similar SQL commands to populate the tables with data from CSV files.
