# Marketplace Analytics — Revenue, Retention & Delivery

Analysis of 100K+ orders from Olist, a Brazilian e-commerce marketplace. Built with MySQL, Python, and Power BI.

---

## The question

Olist did R$13.59M across 99,441 orders between 2016 and 2018. On-time delivery sat at 93%. Average review score was 4.09.

And revenue flattened in 2018 anyway.

Good numbers, stalled growth. I wanted to know why.

---

## What I found

**Retention is the problem, not acquisition.**

Only 3.12% of customers ever come back for a second order. I checked this three ways because the number seemed too low to be real:

- Repeat purchase rate: **3.12%**
- Cohort retention: **0.48%** active one month after first purchase, **0.04%** by month twelve
- RFM segmentation: **~60%** of customers sit in At-Risk or Lost; Champions are **1.3%**

All three agree. Olist isn't losing customers slowly — most never return at all. Every real of revenue growth has to come from someone new.

**Delivery is what breaks satisfaction.**

| Delivery outcome | Avg review |
|---|---|
| On time | 4.29 |
| Late | 2.27 |
| Never delivered | 1.76 |

A two-star drop, and it holds up statistically (Welch's t = 100.97, p < 0.001). Review scores track delivery reliability almost perfectly.

**The regions with the most headroom get the worst service.**

Revenue concentrates hard in São Paulo and the southeast. Meanwhile remote northern states wait 25–30 days for delivery against a 12.5-day national average.

---

## What I'd recommend

At a 3.12% repeat rate there's no compounding customer base. Every sale needs a new customer. The 2018 plateau is what running out of acquisition runway looks like.

Getting repeat rate to 6% — still nothing special by industry standards — would mean roughly **2,768 more repeat purchases, about R$378K**. The number itself isn't huge. What matters is that it costs nothing to acquire. The same R$378K through new customers carries full CAC.

The most direct lever is delivery. It's the one variable in this dataset that measurably moves review scores, and the regions where it's worst are the ones with room to grow. Fix delivery in under-served states first.

---

## Dashboard

**Page 1 — Executive Overview**
Revenue, orders, AOV, repeat rate, category and geographic breakdown.

<!-- INSERT SCREENSHOT 1 -->

**Page 2 — Customers & Retention**
RFM segments, cohort decay curve, at-risk and lost customer counts.

<!-- INSERT SCREENSHOT 2 -->

**Page 3 — Operations & Delivery**
Delivery status vs review score, on-time rate, delivery time by state.

<!-- INSERT SCREENSHOT 3 -->

---

## How it was built

| Stage | Tool | What happened there |
|---|---|---|
| Load & model | MySQL 8 | 9 tables, star schema, joins / CTEs / window functions |
| Segment | SQL | RFM via `NTILE(5)` on recency, frequency, monetary |
| Analyse | Python (Jupyter) | Cohort retention, Welch's t-test, Holt-Winters forecast |
| Visualise | Power BI | 3-page dashboard, DAX measures and calculated columns |

Dataset: [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), 2016–2018.

---

## Methods worth calling out

Three techniques did the heavy lifting here.

**RFM segmentation with window functions.** Scored every customer on recency, frequency, and monetary value using `NTILE(5)` over each dimension, then bucketed them into segments with a CASE expression. Champions, Loyal, New, At-Risk, Lost. It's the same approach retailers use to decide who gets the win-back email.

**Welch's t-test on delivery impact.** The obvious question after seeing 4.29 vs 2.27 is whether that gap is real or noise. Welch's is the right test here rather than Student's because the two groups have wildly different sizes and variances — most orders arrive on time. Result: t = 100.97, p ≈ 0. The gap is not noise.

**Holt-Winters exponential smoothing for the revenue forecast.** Triple exponential smoothing, which handles level, trend, and seasonality — appropriate for monthly e-commerce data with a Black Friday spike. The undamped model hit 36.8% MAPE and kept forecasting growth. Adding a damped trend brought it to 30.1%. Still not precise, but the *way* it failed was the finding: the model expected 2018 to keep climbing, and it didn't. That's the plateau, quantified by a model that refused to see it coming.

**Cohort retention curves.** Grouped customers by their first-purchase month, then tracked what fraction stayed active in each subsequent month. The decay from 0.48% to 0.04% is what a retention problem looks like when you plot it.

---

## Things that went wrong (and how I caught them)

This section exists because the mistakes taught me more than the parts that worked.

**Avg delivery time came out as 34 days.** Python said 12.06. The DAX measure was iterating over `orders`, but the one-to-many relationship with `order_items` meant an order with three items got counted three times. Wrapping the filter in `ALL()` stripped the fan-out and brought it to 12.5.

**Late-delivery reviews showed 2.57 in Power BI and 2.27 in Python.** Two separate causes. My `DATEDIFF` arguments were reversed, and Power BI was comparing full timestamps while Python compared whole days — so an order arriving six hours past the estimate was "late" in one tool and "on time" in the other. I aligned both on a *1+ full days late* definition. Same number now.

**`customer_id` is not the customer.** Olist regenerates it per order. `customer_unique_id` is the actual person. Using the wrong one gives a repeat rate of exactly zero, which is the kind of clean number that should make you suspicious.

**I loaded RFM at customer grain, not summary grain.** 95,420 rows instead of 5. Pre-aggregating in SQL would have been easier and would have made the segment chart dead — no cross-filtering, no drilling. Let the BI layer do the aggregating.

**Three visuals got cut.** A month-over-month growth chart that just restated the revenue trend. An RFM-by-revenue chart that ranked identically to RFM-by-count. A seller concentration chart, built before I checked whether there was any concentration to show. There wasn't.

---

## Where this analysis is limited

The delivery/review relationship is a strong association, not proven causation. Late deliveries cluster in remote regions, and those regions may differ in other ways that affect how people rate things. I'd want a controlled comparison before claiming delivery *causes* the review drop.

The Holt-Winters forecast is directional at best — 30.1% MAPE with a damped trend, down from 36.8% undamped. It consistently over-predicted 2018. That failure was actually the useful part: the model expected growth that never arrived.

The R$378K figure assumes one extra purchase per newly-retained customer at current AOV. It's a floor, not a forecast.

Boundary months (Sept–Dec 2016, Sept 2018) are excluded from trend analysis — too few orders to be meaningful.

Sellers are anonymised as hashed IDs, so seller-level analysis can only go so far.

---

## Repo structure

```
sql/
    01_setup_and_load.sql
    02_analysis_queries.sql
notebooks/
    03_python_analysis.ipynb
powerbi/
    marketplace_analytics.pbix
data/
    cohort_retention.csv
screenshots/
README.md
```

---

## Scope

Included: RFM segmentation, cohort analysis, hypothesis testing, time-series forecasting, interactive dashboarding.

Not included: churn prediction, sentiment analysis, market basket, recommenders. Each one either needs data this dataset doesn't have, or adds complexity without adding insight. A 3.12% repeat rate means there's barely any repeat behaviour to model in the first place.

---

Tanishq Rathod · B.Tech Electrical Engineering, NIT Patna
