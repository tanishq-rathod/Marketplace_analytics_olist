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

![Page 1 — Executive Overview](https://github.com/user-attachments/assets/adc76bfb-120f-4a22-a7db-29e2a141a1c9)



**Page 2 — Customers & Retention**
RFM segments, cohort decay curve, at-risk and lost customer counts.

![Page 2 — Customers & Retention](https://github.com/user-attachments/assets/8519ea99-f96a-4249-b6c2-0ea304c8df7e)


**Page 3 — Operations & Delivery**
Delivery status vs review score, on-time rate, delivery time by state.

![Page 3 — Operations & Delivery](https://github.com/user-attachments/assets/d8a21928-cce1-4473-9201-0e933a40fc1f)

---

## How it was built

| Stage | Tool | Work Done |
|---|---|---|
| Load, Model & Segment | MySQL 8 | 9 related tables, multi-table joins, CTEs, window functions (NTILE), RFM segmentation |
| Analyse | Python (Jupyter) | Cohort retention, Welch's t-test, Holt-Winters forecast |
| Visualise | Power BI | 3-page interactive dashboard, DAX measures and calculated columns |

Dataset: [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), [2016–2018].

---

## Analytical Methods

The analysis leaned on four main techniques.

**RFM segmentation with window functions.** Scored every customer on recency, frequency, and monetary value using `NTILE(5)` over each dimension, then bucketed them into segments with a CASE expression — Champions, Loyal, New, At-Risk, Lost.

**Welch's t-test on delivery impact.** After seeing 4.29 vs 2.27, the question is whether that gap is real or just noise. Welch's fits here because the two groups have very different sizes and variances — most orders arrive on time. Result: t = 100.97, p ≈ 0. The gap isn't noise.

**Holt-Winters exponential smoothing for the revenue forecast.** Triple exponential smoothing, which handles level, trend, and seasonality — a fit for monthly e-commerce data with a Black Friday spike. The undamped model hit 36.8% MAPE and kept forecasting growth; a damped trend brought it to 30.1%. The model kept expecting 2018 to grow, and it didn't. That failure was the actual finding — the plateau showing up as forecast error.

**Cohort retention curves.** Grouped customers by their first-purchase month, then tracked what fraction stayed active in each following month. The decay from 0.48% to 0.04% is what a retention problem looks like when you plot it..

---

## Reconciliation

I checked key numbers across both tools before trusting them, which caught two issues.

Avg delivery time first came out as 34 days in Power BI, against Python's 12.06. The DAX measure was iterating over `orders`, and the one-to-many link with `order_items` counted each order once per item — so a three-item order got counted three times. Wrapping the filter in `ALL()` removed the fan-out and brought it to 12.5.

The late-delivery review score also disagreed — 2.57 in Power BI, 2.27 in Python. Two causes: my `DATEDIFF` arguments were reversed, and Power BI compared full timestamps while Python compared whole days, so an order arriving a few hours past estimate counted as late in one and on-time in the other. Aligning both on a "1+ full days late" rule brought them back in line.

---

## Limitations

The delivery-review link is an association, not proof. Late orders are more common in remote regions, and those regions may differ in other ways that also drag down reviews. Proving delivery actually *causes* the drop would need a controlled comparison, which this data doesn't allow.

The revenue forecast isn't accurate — 30.1% MAPE, and it kept over-predicting 2018. It's not something to plan against. Its only real use was that the size of the miss lined up with the slowdown I'd already seen in the actual numbers.

The R$378K assumes one extra order per retained customer at current AOV. It's a rough floor, not a projection.

Boundary months (Sept–Dec 2016, Sept 2018) are dropped from the trend — too few orders to read anything into.

Sellers come as hashed IDs with no names or business details, so I can't dig into which sellers drive performance or why.

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
