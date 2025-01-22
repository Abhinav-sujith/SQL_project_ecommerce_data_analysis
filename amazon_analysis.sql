-- Exploratory Data Analysis (EDA) on E-Commerce Data: 
-- Inspecting Tables, Checking for Null Values, and Analyzing Key Metrics

SELECT * FROM category ; 
SELECT * FROM customer ; 
SELECT * FROM inventory ; 
SELECT * FROM order_items ; 
SELECT * FROM orders ; 
SELECT * FROM payments ; 
SELECT * FROM products ; 
SELECT * FROM sellers ; 
SELECT * FROM shipping;
----------------------------------------------------------------------------

-- CHECKING FOR NULL VALUES

SELECT 
    COUNT(*) - COUNT(order_id) AS missing_order_ids,
    COUNT(*) - COUNT(customer_id) AS missing_customer_ids,
    COUNT(*) - COUNT(order_date) AS missing_order_dates
FROM orders;
----------------------------------------------------------------------------

SELECT * FROM shipping 
WHERE return_date IS NULL; 
/*
The reason for the large number of NULL values in the return_date column,
is that there are very few customers who have returned the product. 
This results in the return_date remaining NULL for most entries.
*/
----------------------------------------------------------------------------

--Distinct Delivery Status Values in Shipping Table
SELECT DISTINCT delivery_status
FROM shipping;

-- Count of Unique Customers in the Customer Table
SELECT COUNT(DISTINCT customer_id)
FROM customer;

-- Order Items with Quantity Greater Than 5, Ordered by Quantity in Descending Order
SELECT * 
FROM order_items
WHERE quantity > 5
ORDER BY quantity DESC;

-- Summary Statistics for order amounts
SELECT 
    AVG(price_per_unit) AS avg_order_value,
    MIN(price_per_unit) AS min_order_value,
    MAX(price_per_unit) AS max_order_value
FROM order_items;

----------------------------------------------------------------------------

-- Diving into Business Problems: Analyzing Key Metrics and Insights for Improved Decision-Making

----------------------------------------------------------------------------

-- Creating and Calculating Total Sales for Each Item in the Order Items Table

ADD COLUMN total_sales FLOAT;

-- updating total_sales

UPDATE order_items 
SET total_sales = quantity * price_per_unit;
SELECT * FROM order_items
ORDER BY quantity DESC; 

----------------------------------------------------------------------------

-- Top 10 Selling Products by Total Sales Value

SELECT 
    oi.product_id,
    p.product_name,
    ROUND(SUM(oi.total_sales)::numeric, 2)  AS total_sale,
	COUNT(o.order_id) AS total_orders 
FROM 
    orders AS o
JOIN 
    order_items AS oi ON oi.order_id = o.order_id
JOIN 
    products AS p ON oi.product_id = p.product_id
GROUP BY 
    oi.product_id, 
    p.product_name
ORDER BY 
    total_sale DESC
LIMIT 10;

----------------------------------------------------------------------------
-- Revenue by Category: Analyzing Sales Performance Across Different Product Categories

SELECT 
    p.category_id, 
    c.category_name, 
    ROUND(SUM(oi.total_sales)::numeric, 2) AS total_sale,
    SUM(oi.total_sales) / (SELECT SUM(total_sales) FROM order_items) * 100 AS contribution
FROM 
    order_items AS oi
INNER JOIN 
    products AS p ON p.product_id = oi.product_id
LEFT JOIN 
    category AS c ON c.category_id = p.category_id
GROUP BY 
    p.category_id, c.category_name
ORDER BY 
    total_sale DESC;

----------------------------------------------------------------------------
-- Average Order Value (AOV) Calculation per Customer

SELECT  
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name, 
    ROUND(CAST(SUM(oi.total_sales) AS numeric) / CAST(COUNT(o.order_id) AS numeric), 2) AS avg_order_value, 
    COUNT(o.order_id) AS total_orders
FROM 
    order_items oi
INNER JOIN 
    orders o ON o.order_id = oi.order_id
INNER JOIN 
    customer c ON o.customer_id = c.customer_id
GROUP BY 
    c.customer_id, full_name
HAVING 
    COUNT(o.order_id) > 5
ORDER BY 
    avg_order_value DESC;
	
----------------------------------------------------------------------------
-- Sales Trends on a Monthly Basis

SELECT 
    year, 
    month, 
    total_sale AS current_month_sale, 
    LAG(total_sale, 1) OVER (ORDER BY year, month) AS previous_month_sale
FROM 
    (
        SELECT 
            EXTRACT(MONTH FROM o.order_date) AS month,
            EXTRACT(YEAR FROM o.order_date) AS year,
            ROUND(SUM(oi.total_sales::numeric), 2) AS total_sale
        FROM 
            orders AS o
        JOIN 
            order_items AS oi ON oi.order_id = o.order_id
        WHERE 
            o.order_date >= CURRENT_DATE - INTERVAL '1 year'
        GROUP BY 
            EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
        ORDER BY 
            year, month
    ) AS t1;

----------------------------------------------------------------------------
-- Customers with No Order History 
-- Customers with no purchases (using NOT IN)
SELECT * 
FROM customer 
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders
);


-- Customers with no purchases (using LEFT JOIN)
SELECT 
    c.*
FROM 
    customer AS c
LEFT JOIN 
    orders AS o 
ON 
    c.customer_id = o.customer_id
WHERE 
    o.customer_id IS NULL;

----------------------------------------------------------------------------
-- Least selling category by state
WITH rank_table AS (
    SELECT 
        c.state,
        ca.category_name, 
        SUM(oi.total_sales) AS total_sales,
        RANK() OVER (PARTITION BY c.state ORDER BY SUM(oi.total_sales) ASC) AS rank
    FROM 
        orders AS o
    INNER JOIN 
        customer AS c ON o.customer_id = c.customer_id
    INNER JOIN 
        order_items AS oi ON o.order_id = oi.order_id
    INNER JOIN 
        products AS p ON p.product_id = oi.product_id
    INNER JOIN 
        category AS ca ON ca.category_id = p.category_id  
    GROUP BY 
        c.state, ca.category_name
    ORDER BY 
        c.state, total_sales ASC  
)
SELECT *
FROM rank_table 
WHERE rank = 1;

----------------------------------------------------------------------------
-- Customer Lifetime Value and Order Analysis

SELECT 
    o.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    -- Average order value per customer
    SUM(oi.total_sales) / COUNT(DISTINCT o.order_id) AS avg_order_value,
    -- Total number of orders per customer
    COUNT(DISTINCT o.order_id) AS total_orders,
    -- Customer's lifespan in years
    EXTRACT(YEAR FROM MAX(o.order_date)) - EXTRACT(YEAR FROM MIN(o.order_date)) AS customer_lifespan,
    -- Calculating customer lifetime value (CLV)
    SUM(oi.total_sales) / COUNT(DISTINCT o.order_id) * 
    COUNT(DISTINCT o.order_id) * 
    (EXTRACT(YEAR FROM MAX(o.order_date)) - EXTRACT(YEAR FROM MIN(o.order_date))) AS customer_lifetime_value,
    -- Customer ranking based on total sales
    DENSE_RANK() OVER(ORDER BY SUM(oi.total_sales) DESC) AS customer_ranking
FROM 
    orders o
INNER JOIN 
    order_items oi ON o.order_id = oi.order_id
INNER JOIN 
    customer c ON o.customer_id = c.customer_id
WHERE 
    oi.order_id IS NOT NULL
GROUP BY 
    o.customer_id, full_name
ORDER BY 
    customer_lifetime_value DESC;

----------------------------------------------------------------------------
-- Inventory Reorder Status: Products with Stock Below Threshold

SELECT 
    i.product_id,
    p.product_name,
    i.stock,
    CASE 
        WHEN i.stock < 10 THEN 'Reorder Suggested'
        ELSE 'No Order Needed'
    END AS reorder_status
FROM 
    inventory AS i
JOIN 
    products AS p 
    ON p.product_id = i.product_id
ORDER BY 
    i.stock ASC;

----------------------------------------------------------------------------
-- Shipping Delay Analysis: Customers with Shipping Delays Between 3 and 20 Days

SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    s.shipping_date - o.order_date AS shipping_delay
FROM 
    orders AS o
JOIN 
    customer AS c ON c.customer_id = o.customer_id
JOIN 
    shipping AS s ON o.order_id = s.order_id
WHERE 
    s.shipping_date - o.order_date BETWEEN 3 AND 20
ORDER BY 
    shipping_delay DESC;

----------------------------------------------------------------------------
-- Payment Status Analysis: Total Payments and Payment Success Rate

SELECT 
    p.payment_status, 
    COUNT(*) AS total_payment,
    -- Calculating the payment success rate as a percentage
    CONCAT(ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM payments)::numeric * 100, 2), '%') AS payment_success_rate
FROM 
    orders AS o
INNER JOIN 
    payments AS p ON p.order_id = o.order_id
GROUP BY 
    p.payment_status
ORDER BY 
    total_payment DESC;

----------------------------------------------------------------------------
-- Top Performing Sellers: Sales, Order Count, and Success Ratio


WITH top_sellers AS (
    -- Select top 5 sellers based on total sales value
    SELECT 
        s.seller_id,
        s.seller_name,
        SUM(oi.total_sales) AS total_sale
    FROM 
        orders AS o
    JOIN 
        sellers AS s ON o.seller_id = s.seller_id
    JOIN 
        order_items AS oi ON oi.order_id = o.order_id
    GROUP BY 
        s.seller_id, s.seller_name
    ORDER BY 
        total_sale DESC
    LIMIT 5
), 
seller_report AS (
    -- Get total orders per seller, excluding in-progress and returned orders
    SELECT 
        o.seller_id,
        t.seller_name,
        o.order_status,
        COUNT(*) AS total_orders
    FROM 
        orders AS o
    JOIN 
        top_sellers AS t ON t.seller_id = o.seller_id
    WHERE 
        o.order_status NOT IN ('Inprogress', 'Returned')
    GROUP BY 
        o.seller_id, t.seller_name, o.order_status
)
-- Final report showing orders by status and successful orders ratio
SELECT 
    seller_id,
    seller_name,
    -- Completed orders count
    SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) AS completed_orders,
    -- Cancelled orders count
    SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) AS cancelled_orders,
    -- Total orders count
    SUM(total_orders) AS total_orders,
    -- Successful orders ratio (percentage of completed orders)
    ROUND(
        SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric / 
        SUM(total_orders)::numeric * 100, 2
    ) AS successful_orders_ratio
FROM 
    seller_report
GROUP BY 
    seller_id, seller_name
ORDER BY 
    successful_orders_ratio DESC;
	
----------------------------------------------------------------------------

-- Product Profit Margin and Ranking Based on Profitability

WITH product_profit AS (
    SELECT 
        p.product_id, 
        p.product_name,
        -- Calculating profit margin as a percentage of total sales
        ROUND(
            SUM(oi.total_sales - (p.cogs * oi.quantity))::numeric / 
            SUM(oi.total_sales)::numeric, 2
        ) * 100 AS profit_margin
    FROM 
        products AS p
    INNER JOIN 
        order_items AS oi ON oi.product_id = p.product_id
    GROUP BY 
        p.product_id, p.product_name
)
SELECT 
    pp.product_id, 
    pp.product_name,
    pp.profit_margin,
    
    -- Ranking products by profit margin in descending order
    DENSE_RANK() OVER (
        ORDER BY pp.profit_margin DESC
    ) AS product_rank
FROM 
    product_profit pp
ORDER BY 
    product_rank;

----------------------------------------------------------------------------
-- Segmenting Customers Based on Total Spend (Customer Segmentation)

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(oi.total_sales) AS total_spent,
    CASE
        WHEN SUM(oi.total_sales) < 100 THEN 'Low Value'
        WHEN SUM(oi.total_sales) BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'High Value'
    END AS customer_segment
FROM 
    customer c
JOIN 
    orders o ON o.customer_id = c.customer_id
JOIN 
    order_items oi ON oi.order_id = o.order_id
GROUP BY 
    c.customer_id, full_name
ORDER BY 
    total_spent ASC;
	
----------------------------------------------------------------------------
-- Customer Churn Analysis


SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    MAX(o.order_date) AS last_order_date,
    CASE 
        WHEN MAX(o.order_date) < CURRENT_DATE - INTERVAL '6 months' THEN 'Churned'
        ELSE 'Active'
    END AS churn_status
FROM 
    customer c
LEFT JOIN 
    orders o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id, full_name
ORDER BY 
    last_order_date DESC;

----------------------------------------------------------------------------
-- Identifying repeat vs new customers

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT o.order_id) > 1 THEN 'Repeat Customer'
        ELSE 'New Customer'
    END AS customer_type
FROM 
    customer c
JOIN 
    orders o ON o.customer_id = c.customer_id
GROUP BY 
    c.customer_id, full_name
ORDER BY 
    total_orders DESC;

----------------------------------------------------------------------------
-- Executive Summary: Key Performance Indicators (KPIs)

SELECT 
    'Total Sales' AS metric, ROUND(SUM(oi.total_sales)::numeric, 2) AS value
FROM 
    order_items oi
UNION ALL
SELECT 
    'Total Orders', COUNT(DISTINCT o.order_id)
FROM 
    orders o
UNION ALL
SELECT 
    'Average Order Value', ROUND(AVG(oi.total_sales)::numeric, 2)
FROM 
    order_items oi;

----------------------------------------------------------------------------

--END OF PROJECT

