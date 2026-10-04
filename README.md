# RetailCo — Business Analyst Project

## Overview
Exploratory analysis of RetailCo's e-commerce sales data (customers, products, orders)
across UAE, Saudi Arabia, Qatar, Oman, Kuwait, Bahrain, and India. The raw data included
real-world data quality issues — duplicate records, inconsistent date formats, and missing
values — which were cleaned prior to analysis. The goal was to surface key business
insights from order, product, and customer data.

## Tools
SQL Server (T-SQL)

## Key Metrics
- **Total Revenue:** $390,729.30
- **Total Orders:** 3,000
- **Gross Margin:** 49.50% (based on product cost only — excludes overhead, marketing, and shipping)

## Key Findings

1. **Order volume is fairly evenly spread across regions** — Muscat leads with 369 orders,
   Mumbai trails with 316. No single region dominates, suggesting demand is balanced
   across markets rather than concentrated in one.

2. **A third of all orders don't result in a completed sale.** Only 66.3% of orders were
   Completed; 17.3% were Cancelled and 16.4% were Returned. A combined ~34% loss rate is
   worth investigating — particularly whether cancellations and returns cluster around
   specific products or categories.

3. **Beauty is the strongest category on both revenue and margin** — $68,285 in revenue
   at a 51.88% margin, the best of all five categories. **Electronics is the weakest on
   both fronts** — lowest revenue ($39,721) and lowest margin (44.47%) — suggesting it may
   be underperforming rather than just lower-margin-but-high-volume.

4. **Top 5 products by revenue span multiple categories**, not just one: Hair Dryer
   ($24,348), Running Shoes ($23,840), Sunscreen SPF50 ($23,782), Printer Paper ($22,872),
   and Air Fryer ($19,164). This signals demand is diversified across Beauty, Fashion,
   Office Supplies, and Home & Kitchen rather than driven by a single bestselling category.

5. **Bahrain is the top market on both customer count and revenue** (500 customers,
   $65,797 revenue), with Qatar lowest on both (285 customers, $36,977). Revenue per
   customer is fairly consistent across markets (roughly $125–$134 each), suggesting the
   gap between markets is mainly about customer acquisition, not spending behavior per
   customer.

## Files
- `retailco_ba_project.sql` — full data cleaning + EDA script

## Next Steps
Advanced analysis: revenue trends over time, customer segmentation by spend, and
investigating the drivers behind Electronics' underperformance and the ~34%
cancel/return rate.
