# Marketplace Analytics — Revenue, Retention & Delivery

Analysis of 100K+ orders from Olist, a Brazilian e-commerce marketplace. Built with MySQL, Python, and Power BI.

---

## The question

Olist did R$13.59M across 99,441 orders between 2016 and 2018. Revenue climbed steadily through 2017 — then flattened in 2018 and never recovered.

The top-line looks like a business that found its ceiling. I wanted to know why.

---

## What I found

**Retention is the problem, not acquisition.**

Barely any customers place a second order. That seemed off, so I looked at it a few different ways:

- Repeat purchase rate: **3.12%**
- Cohort retention: **0.48%** active a month after first purchase, down to **0.04%** by month twelve
- RFM segmentation: about **60%** of customers fall into At-Risk or Lost Customers

They all point the same way. This isn't slow churn — most people just don't come back. Which means growth depends entirely on new customers.

**So why don't they come back?**

The data can't fully answer that, but one thing stands out: delivery. A late order is the most obvious bad first impression here, and it clearly drags down how people rate the purchase.

| Delivery outcome | Avg review |
|---|---|
| On time | 4.29 |
| Late | 2.27 |
| Never delivered | 1.76 |

Late orders roughly halve the review score, and the gap holds up statistically (Welch's t = 100.97, p < 0.001) — it's not noise.

Delivery also gets worse the further you go from the southeast. Revenue is concentrated in São Paulo and the surrounding states, while remote northern regions wait 25–30 days for an order against a national average of about 12. The places with the most room to grow are the ones getting the slowest service.

---

## What I'd recommend

Two directions, and both target things the analysis actually surfaced.

**Fix delivery where it's broken.**

The delivery problem isn't uniform — it's concentrated in the remote northern states, where orders take 25–30 days against a national average of about 12. And late orders cost real money: reviews drop from 4.29 to 2.27 the moment an order misses its estimate.

Olist could cut that gap by building a warehouse or partnering with a local fulfillment provider closer to these regions. The catch is that these states bring in less revenue today, so it's a bet on unlocking new demand rather than protecting existing sales. The smart way to play it is to try one region first, see whether faster delivery actually brings people back, and expand only if the numbers hold.

**Give people a reason to come back.**

The bigger issue is retention. Only 3.12% of customers order twice, and around 60% sit in At-Risk or Lost — there's barely any returning base to build on. Better delivery improves the experience, but it doesn't give anyone a reason to return.

A subscription could. Something with real perks — faster shipping, lower prices, member-only deals — turns a one-time buyer into someone with a reason to come back. It also feeds the first idea: the fast-delivery perk rides on the same fulfillment improvements, so the two reinforce each other instead of splitting the budget.

Neither is a sure thing. But both go straight at the problems the data points to, instead of chasing growth by buying one-time customers forever..

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
