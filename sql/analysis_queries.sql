-- ============================================================
--                  ANALYSIS QUERIES (SQL)
-- ============================================================

-- 1. Revenue Trend with Regional Contribution
SELECT 
    year,
    region,
    SUM(total_value_meur) AS total_revenue,
    ROUND(
        SUM(total_value_meur) * 100.0 /
        SUM(SUM(total_value_meur)) OVER (PARTITION BY year),
        2
    ) AS revenue_contribution_pct
FROM hellofresh.revenue_composition_and_contract
GROUP BY year, region
ORDER BY year, total_revenue DESC;


-- 2. Revenue Growth (YoY) + Growth %
WITH revenue_base AS (
    SELECT 
        year,
        region,
        SUM(total_value_meur) AS revenue
    FROM hellofresh.revenue_composition_and_contract
    GROUP BY year, region
)
SELECT
    year,
    region,
    revenue,
    LAG(revenue) OVER (PARTITION BY region ORDER BY year) AS prev_revenue,
    revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY year) AS revenue_change,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY year)) * 100.0 /
        NULLIF(LAG(revenue) OVER (PARTITION BY region ORDER BY year), 0),
        2
    ) AS growth_pct
FROM revenue_base
ORDER BY region, year;


-- 3. AEBITDA Trend + Ranking by Region
WITH aebitda_base AS (
    SELECT
        year,
        region,
        SUM(value) AS aebitda
    FROM hellofresh.revenue  
    WHERE metric LIKE '%AEBITDA%' 
    AND period = 'FY'
    GROUP BY year, region
)
SELECT
    year,
    region,
    aebitda,
    RANK() OVER (PARTITION BY year ORDER BY aebitda DESC) AS aebitda_rank,
    ROUND(
        aebitda * 100.0 / SUM(aebitda) OVER (PARTITION BY year),
        2
    ) AS contribution_pct
FROM aebitda_base
ORDER BY year DESC, aebitda_rank ASC;


-- 4. AEBITDA Margin 
SELECT 
    year,
    region,
    ROUND(
        SUM(CASE WHEN metric LIKE '%AEBITDA%' THEN value ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END), 0),
        2
    ) AS aebitda_margin_pct
FROM hellofresh.revenue
GROUP BY year, region
ORDER BY year DESC, region;


-- 5. AEBIT Margin
SELECT 
    year, 
    region,
    ROUND(
        SUM(CASE WHEN metric LIKE '%AEBIT%' AND metric NOT LIKE '%EBITDA%' THEN value ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END), 0), 
        2
    ) AS aebit_margin_pct
FROM hellofresh.revenue
GROUP BY year, region
ORDER BY year DESC, region;


-- 6. Overall Profitability Trend (AEBITDA vs AEBIT)
SELECT
    year,
    SUM(CASE WHEN metric LIKE '%AEBITDA%' THEN value ELSE 0 END) AS total_aebitda,
    SUM(CASE WHEN metric LIKE '%AEBIT%' AND metric NOT LIKE '%EBITDA%' THEN value ELSE 0 END) AS total_aebit,
    ROUND(
        SUM(CASE WHEN metric LIKE '%AEBITDA%' THEN value ELSE 0 END) * 100.0 /
        NULLIF(SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END), 0),
        2
    ) AS overall_margin_pct
FROM hellofresh.revenue
GROUP BY year
ORDER BY year;


-- 7. Order Volume Trend + Decline Detection
SELECT 
    year,
    region,
    SUM(value) AS total_orders,
    LAG(SUM(value)) OVER (PARTITION BY region ORDER BY year) AS prev_orders,
    SUM(value) - LAG(SUM(value)) OVER (PARTITION BY region ORDER BY year) AS order_change
FROM hellofresh.performance
WHERE metric = 'number of orders'
AND period = 'FY'
GROUP BY year, region;


-- 8. Revenue vs Orders vs AOV (Core Business Driver Analysis)
SELECT
    year,
    region,
    SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN metric LIKE '%Order%' OR metric LIKE '%order%' THEN value ELSE 0 END) AS total_orders,
    ROUND(
        SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END) * 1.0 / 
        NULLIF(SUM(CASE WHEN metric LIKE '%Order%' OR metric LIKE '%order%' THEN value ELSE 0 END), 0),
        2
    ) AS avg_order_value
FROM hellofresh.performance
WHERE period = 'FY'
GROUP BY year, region
ORDER BY year DESC, total_revenue DESC;


-- 9. Procurement & Cooking Cost Change
SELECT 
    metric,
    `2023 (meur)` AS cost_2023,
    `2024 (meur)` AS cost_2024,
    (`2024 (meur)` - `2023 (meur)`) AS cost_change,
    ROUND(
        (`2024 (meur)` - `2023 (meur)`) * 100.0 / 
        NULLIF(`2023 (meur)`, 0), 
        2
    ) AS cost_growth_pct
FROM hellofresh.income_statement_consolidated
WHERE metric LIKE '%Procurement and cooking%';


-- 10. Marketing Efficiency
SELECT
    SUM(CASE WHEN metric LIKE '%Revenue%' THEN `2024 (meur)` ELSE 0 END) AS total_revenue_2024,
    SUM(CASE WHEN metric LIKE '%Marketing%' THEN `2024 (meur)` ELSE 0 END) AS marketing_cost_2024,
    ROUND(
        SUM(CASE WHEN metric LIKE '%Marketing%' THEN `2024 (meur)` ELSE 0 END) * 100.0 / 
        NULLIF(SUM(CASE WHEN metric LIKE '%Revenue%' THEN `2024 (meur)` ELSE 0 END), 0), 
        2
    ) AS marketing_cost_pct
FROM hellofresh.income_statement_consolidated;
