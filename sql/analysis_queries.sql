-- 1. What is the total revenue per year?

SELECT 
    year,
    region,
    SUM(total_value_meur) AS total_revenue
FROM hellofresh.revenue_composition_and_contract
GROUP BY year, region;


-- 2. Which region generates the highest revenue each year?

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


-- 4. What is AEBITDA by year?

SELECT
    year,
    region,
    SUM(value) AS total_value
FROM hellofresh.revenue
WHERE metric = 'AEBITDA'
AND period = 'FY'
GROUP BY year, region;

-- 5. What is AEBITDA margin (% of revenue) by region and year?

SELECT 
    year,
    region,
    metric,
    ROUND(SUM(value) * 100, 2) AS percentage
FROM hellofresh.revenue
WHERE metric LIKE '%AEBITDA%'
GROUP BY year, region, metric;

-- 6. What is AEBIT margin (% of revenue) by region and year?

SELECT 
    year,
    region,
    metric,
    ROUND(SUM(value) * 100, 2) AS percentage
FROM hellofresh.revenue
WHERE metric LIKE '%AEBIT%)'
GROUP BY year, region, metric;

-- 7. What is the total AEBITDA and AEBIT for the overall period?

SELECT
    metric,
    SUM(value) AS total_overall
FROM hellofresh.revenue
WHERE metric IN ('AEBITDA', 'AEBIT')
GROUP BY metric;

-- 8. What is the contribution margin by region and year?

SELECT
    year,
    region,
    SUM(value) AS total_value
FROM hellofresh.revenue
WHERE metric = 'Contribution margin 1 (in MEUR)'
AND period = 'FY'
GROUP BY year, region;

-- 9. What is the revenue per meal kit by region and year?

SELECT 
	year,
	region,
	business_type,
    Metric,
	SUM(value) AS total_value  
FROM hellofresh.financial_performance
WHERE business_type = 'meal kits'
AND metric = 'revenue'
GROUP BY year, region, business_type;

-- 10.What is AEBITDA per meal kit by region and year?

SELECT 
	year,
	region,
	business_type,
    Metric,
	SUM(value) AS total_value  
FROM hellofresh.financial_performance
WHERE business_type = 'meal kits'
AND metric = 'AEBITDA'
GROUP BY year, region, business_type;


-- 11.What is the total number of orders by region and year?

SELECT 
	year,
	region,
	SUM(value) AS total_value  
FROM hellofresh.performance
WHERE metric = 'number of orders'
AND period = 'FY'
GROUP BY year, region;


-- 12.What is the average order value (revenue per order)?

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


-- 13.How much are cooking expenses per year?

SELECT 
	metric,
	`2024 (meur)`,
	`2023 (meur)`
FROM hellofresh.income_statement_consolidated
WHERE metric = 'Procurement and cooking expenses';


-- 14.How much is marketing cost per year?

SELECT 
	metric,
	`2024 (meur)`,
	`2023 (meur)`
FROM hellofresh.income_statement_consolidated
WHERE metric = 'Marketing expenses';


-- 15.How much working capital they have?

 SELECT 
    SUM(value) AS working_capital
FROM hellofresh.cash_and_working_capital
WHERE metric = 'Operating working capital'
AND period = 'FY';


-- 16.How much total inventories and ingredients used?

SELECT
`inventory category`,
SUM(`31-Dec-2024 (MEUR)`) AS total_2024,
SUM(`31-Dec-2023 (MEUR)`) AS total_2023
FROM hellofresh.inventories
WHERE `inventory category` IN ('total inventories', 'ingredients')
GROUP BY `Inventory Category`;

-- 17 .How much total depreciation, amortization and impairment of consolidation? 

SELECT 
    SUM(`2024 (MEUR)`) AS depreciation_2024,
    SUM(`2023 (MEUR)`) AS depreciation_2023
FROM hellofresh.cash_flow_consolidated
WHERE Metric = 'Depreciation, amortization and impairment';

