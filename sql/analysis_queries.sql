-- ============================================================
--                  ANALYSIS QUERIES (SQL)
-- ============================================================

-- 1. How has total revenue changed across regions over time?

SELECT 
    year,
    region,
    SUM(total_value_meur) AS total_revenue
FROM hellofresh.revenue_composition_and_contract
GROUP BY year, region;


-- 2. Which regions are driving or declining revenue growth year-over-year?

WITH revenue_by_region AS (
    SELECT 
        year,
        region,
        SUM(total_value_meur) AS total_revenue
    FROM revenue_composition_and_contract
    WHERE metric LIKE '%Revenue%'
    GROUP BY year, region
),
revenue_by_growth AS (
    SELECT
        year,
        region,
        total_revenue,
        LAG(total_revenue) 
        OVER (PARTITION BY region
		ORDER BY year) 
        AS previous_year_revenue
    FROM revenue_by_region
)

SELECT
    year,
    region,
    total_revenue,
    previous_year_revenue,
    total_revenue - previous_year_revenue AS revenue_growth,
    ROUND(
	(total_revenue - previous_year_revenue) * 100.0 /
	NULLIF(previous_year_revenue, 0), 2
    ) AS growth_percentage
FROM revenue_by_growth
ORDER BY region, year;


-- 3. How has AEBITDA evolved across regions over time?

SELECT
    year,
    region,
    SUM(value) AS total_value
FROM hellofresh.revenue
WHERE metric = 'AEBITDA'
AND period = 'FY'
GROUP BY year, region;

-- 4. How efficiently is the company converting revenue into profit (AEBITDA margin)?

SELECT 
    year,
    region,
    metric,
    ROUND(SUM(value) * 100, 2) AS percentage
FROM hellofresh.revenue
WHERE metric LIKE '%AEBITDA%'
GROUP BY year, region, metric;

-- 5. How does operating profitability (AEBIT margin) vary by region?

SELECT 
    year,
    region,
    metric,
    ROUND(SUM(value) * 100, 2) AS percentage
FROM hellofresh.revenue
WHERE metric LIKE '%AEBIT%)'
GROUP BY year, region, metric;

-- 6. What is the overall profitability trend of the company?

SELECT
    metric,
    SUM(value) AS total_overall
FROM hellofresh.revenue
WHERE metric IN ('AEBITDA', 'AEBIT')
GROUP BY metric;

-- 7. How has order volume changed across regions over time?

SELECT 
	year,
	region,
	SUM(value) AS total_value  
FROM hellofresh.performance
WHERE metric = 'number of orders'
AND period = 'FY'
GROUP BY year, region;


-- 8. Is revenue decline driven by fewer orders or lower spending per order?

SELECT
    year,
    region,
    SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END) AS total_revenue,
    SUM(CASE WHEN metric LIKE '%order%' THEN value ELSE 0 END) AS total_orders,
    ROUND(
        SUM(CASE WHEN metric LIKE '%Revenue%' THEN value ELSE 0 END) /
        NULLIF(SUM(CASE WHEN metric LIKE '%order%' THEN value ELSE 0 END), 0), 
        2
    ) AS avg_order_value
FROM hellofresh.performance
WHERE period = 'FY'
GROUP BY 1, 2
ORDER BY 1 DESC, 5 DESC;


-- 9. How have key operational costs (procurement & cooking) changed year-over-year?

SELECT 
	metric,
	`2024 (meur)`,
	`2023 (meur)`
FROM hellofresh.income_statement_consolidated
WHERE metric = 'Procurement and cooking expenses';


-- 10. How has marketing spend evolved, and is it aligned with revenue performance?

SELECT 
	metric,
	`2024 (meur)`,
	`2023 (meur)`
FROM hellofresh.income_statement_consolidated
WHERE metric = 'Marketing expenses';

