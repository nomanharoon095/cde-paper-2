          --Task no 1---



    SELECT
    o.order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    s.store_name,
    CONCAT(st.first_name, ' ', st.last_name) AS staff_full_name,
    p.product_name,
    cat.category_name,
    b.brand_name,
    oi.quantity,
    oi.list_price,
    oi.discount,
    oi.quantity * oi.list_price * (1 - oi.discount) AS net_line_revenue
FROM sales.orders AS o
JOIN sales.customers AS c
 ON o.customer_id = c.customer_id
JOIN sales.stores AS s
 ON o.store_id = s.store_id
JOIN sales.staffs AS st
ON o.staff_id = st.staff_id
JOIN sales.order_items AS oi
 ON o.order_id = oi.order_id
JOIN production.products AS p
    ON oi.product_id = p.product_id
JOIN production.categories AS cat
    ON p.category_id = cat.category_id
JOIN production.brands AS b
    ON p.brand_id = b.brand_id
WHERE o.order_status = 4
ORDER BY o.order_date DESC;






   --task no 2--


SELECT
    s.store_name,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount))
        / COUNT(DISTINCT o.order_id) AS average_order_value
FROM sales.stores AS s
JOIN sales.orders AS o
    ON s.store_id = o.store_id
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 4
GROUP BY
    s.store_id,
    s.store_name
ORDER BY total_net_revenue DESC;




        --task 3--
SELECT
 s.store_name,
 COUNT(DISTINCT o.order_id) AS number_of_orders,
 SUM(oi.quantity) AS total_units_sold,
 SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue,
 SUM(oi.quantity * oi.list_price * (1 - oi.discount))
 / COUNT(DISTINCT o.order_id) AS average_order_value
FROM sales.stores AS s
JOIN sales.orders AS o
    ON s.store_id = o.store_id
JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 4
GROUP BY
    s.store_id,
    s.store_name
ORDER BY total_net_revenue DESC;


--task 4
SELECT
    p.product_name,
    s.store_name,
    st.quantity AS current_quantity,
    c.category_name,
    b.brand_name
FROM production.stocks AS st
INNER JOIN production.products AS p
    ON st.product_id = p.product_id
INNER JOIN sales.stores AS s
    ON st.store_id = s.store_id
INNER JOIN production.categories AS c
    ON p.category_id = c.category_id
INNER JOIN production.brands AS b
    ON p.brand_id = b.brand_id
WHERE st.quantity < 5
ORDER BY
    st.quantity ASC,
    p.product_name;

    --task 5--



WITH product_sales AS
(
    SELECT
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM production.products AS p
    INNER JOIN production.categories AS c
        ON p.category_id = c.category_id
    INNER JOIN sales.order_items AS oi
        ON p.product_id = oi.product_id
    INNER JOIN sales.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 4
    GROUP BY
        c.category_name,
        p.product_id,
        p.product_name
),
ranked_products AS
(
    SELECT
        category_name,
        product_name,
        total_units_sold,
        total_net_revenue,
        DENSE_RANK() OVER
        (
            PARTITION BY category_name
            ORDER BY total_net_revenue DESC
        ) AS product_position
    FROM product_sales
)
SELECT
    category_name,
    product_name,
    total_units_sold,
    total_net_revenue,
    product_position
FROM ranked_products
WHERE product_position <= 3
ORDER BY
    category_name,
    product_position;

    --task 6--  


WITH monthly_sales AS
(
    SELECT
        YEAR(o.order_date) AS year,
        MONTH(o.order_date) AS month,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_net_revenue
    FROM sales.orders AS o
    INNER JOIN sales.order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 4
    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
),
monthly_trend AS
(
    SELECT
        year,
        month,
        total_net_revenue,
        LAG(total_net_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_total_net_revenue
    FROM monthly_sales
)
SELECT
    year,
    month,
    total_net_revenue,
    previous_month_total_net_revenue,
    total_net_revenue - previous_month_total_net_revenue
        AS revenue_change
FROM monthly_trend
ORDER BY
    year,
    month;


    --task 7--


SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_full_name,
    COUNT(DISTINCT o.order_id) AS total_completed_orders,
    COALESCE(SUM(oi.quantity), 0) AS total_units_purchased,
    COALESCE(
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
        0
    ) AS total_net_revenue,
    MAX(o.order_date) AS most_recent_completed_order_date
FROM sales.customers AS c
LEFT JOIN sales.orders AS o
    ON c.customer_id = o.customer_id
    AND o.order_status = 4
LEFT JOIN sales.order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;


