Customer Churn & Retention Analysis — UK Online Retailer
Identified £836K in at-risk customer revenue and designed a targeted retention strategy projected to return £123K net (positive across all tested assumptions), using SQL, Python, and predictive modelling on 1M+ real transactions.
This project takes a retailer's raw transaction history and answers one business question end-to-end: which customers are about to stop buying, what is that worth, and what should we do about it?
---
Key findings
Revenue is highly concentrated. 26% of customers ("Champions") drive 70% of revenue — a classic Pareto pattern that shapes where retention effort should go.
A clear, valuable at-risk segment exists. 418 high-value customers (avg. spend ~£2,000 each) show a high probability of churning, representing £836K in historical revenue that is actively slipping away.
A retention campaign is strongly justified. A targeted, low-cost email campaign is projected to recover ~£123K net over the following year, and stays positive even under conservative assumptions (£40K net at a 10% win-back rate).
Tenure and spend predict churn — not order frequency. How long a customer has been active and how much they spend are the dominant churn signals; raw purchase frequency matters least.
---
Recommendation
> Target the 418 high-value, high-risk customers with a personalised retention offer (not a blanket discount). Because tenure and spend are the strongest churn signals, prioritise long-standing, high-spend customers showing reduced recent activity. Projected net return: \*\*£123K\*\* (range £40K–£165K depending on win-back rate), against an estimated campaign cost of \~£2,100.
---
Approach
The project follows a deliberate analytics workflow, using the right tool at each stage.
1. Data engineering (SQL / MySQL)
Loaded 1,067,371 raw transactions into MySQL, then cleaned them with documented, defensible filters: removed cancellations (invoices prefixed `C`), dropped rows with no customer ID, excluded non-product line items (postage, fees, manual adjustments), and filtered non-positive quantities and prices. Aggregated the cleaned data into a customer-level summary table.
2. Segmentation (SQL)
Built RFM segmentation (Recency, Frequency, Monetary) using quintile scoring, mapping customers into named, commercially meaningful segments — Champions, Loyal, At Risk, Can't Lose Them, Hibernating, Lost, and others.
3. Churn definition (SQL)
Defined churn from behaviour (no dataset label exists). Customers inactive for 90+ days before the snapshot date were labelled churned — a threshold informed by the data's purchase distribution and the retailer's roughly quarterly repurchase pattern. This produced a near-balanced target (50.7% churned / 49.3% active).
4. Predictive modelling (Python / scikit-learn)
Trained two models — logistic regression (interpretable baseline) and a random forest — to predict churn from behavioural features.
A key methodological decision: recency was deliberately excluded from the features to avoid data leakage, since churn was defined by recency. The model predicts churn from independent signals (tenure, monetary value, average order value, product diversity, frequency) instead.
5. Business impact (Python)
Scored every customer's churn probability, isolated the high-value at-risk group, and built a transparent business case with stated assumptions and a sensitivity analysis across win-back rates.
---
Results
Model performance
Model	ROC-AUC	Accuracy	Churn Recall
Logistic Regression	0.775	0.72	0.76
Random Forest	0.775	0.70	0.73
Both models achieved 0.775 ROC-AUC on held-out test data. Logistic regression matched the random forest while being simpler and more interpretable — so it would be the preferred choice in production. The ~0.78 ceiling reflects an honest, leak-free model: including recency would inflate the score artificially.
Churn drivers (feature importance)
Feature	Importance
Tenure (days active)	0.28
Monetary (total spend)	0.24
Average order value	0.20
Distinct products	0.17
Order frequency	0.11
Business case sensitivity
Win-back rate	Net return
10%	£39,705
20%	£81,500
30% (base case)	£123,295
40%	£165,089
The recommendation remains strongly positive across every tested scenario.
---
Tech stack
MySQL — data loading, cleaning, aggregation, RFM segmentation, churn labelling
Python — pandas, scikit-learn (logistic regression, random forest), SQLAlchemy
Jupyter Notebook — modelling and analysis
[Tableau Public / Power BI] — interactive dashboard (link below)
---
Repository structure
```
└── README.md
├── churn_model.ipynb      # modelling, evaluation, business case
├── churn_analysis.sql     # cleaning \& customer summary # RFM scoring \& named segments # churn definition
├── Churn Overview Dashboard/(screenshot + link)

```
---
Dashboard


https://public.tableau.com/views/CustomerChurnRetentionAnalysis_17894141141380/ChurnOverview?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link
---
Dataset
Online Retail II — UCI Machine Learning Repository. ~1.07M real transactions from a UK online gift retailer, Dec 2009 – Dec 2011. Licensed CC BY 4.0.
---
Notes & limitations
Churn is defined behaviourally (90-day inactivity), not from a ground-truth label — a reasonable but adjustable choice.
The campaign cost models contact cost only; a fuller business case would also net out the margin given away in any discount offer.
Win-back and value-recovery rates are stated industry-typical assumptions; the framework holds for any values, and the sensitivity analysis shows the conclusion is ro
