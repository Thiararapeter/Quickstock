-- Daily Sales Report
CREATE OR REPLACE FUNCTION get_daily_sales_report(report_date DATE)
RETURNS TABLE (
    total_sales DECIMAL(10,2),
    total_items_sold INTEGER,
    payment_method TEXT,
    payment_method_total DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(s.total_price), 0.0) as total_sales,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as total_items_sold,
        s.payment_method,
        COALESCE(SUM(s.total_price), 0.0) as payment_method_total
    FROM sales s
    WHERE DATE(s.sale_date) = report_date
    GROUP BY s.payment_method;
END;
$$ LANGUAGE plpgsql;

-- Date Range Sales Report
CREATE OR REPLACE FUNCTION get_sales_report_by_date_range(start_date DATE, end_date DATE)
RETURNS TABLE (
    sale_date DATE,
    total_sales DECIMAL(10,2),
    total_items_sold INTEGER,
    payment_method TEXT,
    payment_method_total DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(s.sale_date) as sale_date,
        COALESCE(SUM(s.total_price), 0.0) as total_sales,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as total_items_sold,
        s.payment_method,
        COALESCE(SUM(s.total_price), 0.0) as payment_method_total
    FROM sales s
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY DATE(s.sale_date), s.payment_method
    ORDER BY DATE(s.sale_date);
END;
$$ LANGUAGE plpgsql;

-- Product Sales Report
CREATE OR REPLACE FUNCTION get_product_sales_report(start_date DATE, end_date DATE)
RETURNS TABLE (
    item_id TEXT,
    item_name TEXT,
    category TEXT,
    total_quantity_sold INTEGER,
    total_sales DECIMAL(10,2),
    average_price DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.item_id,
        s.item_name,
        s.category,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as total_quantity_sold,
        COALESCE(SUM(s.total_price), 0.0) as total_sales,
        COALESCE(AVG(s.selling_price), 0.0) as average_price
    FROM sales s
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY s.item_id, s.item_name, s.category
    ORDER BY total_sales DESC;
END;
$$ LANGUAGE plpgsql;

-- Top Selling Products Report
CREATE OR REPLACE FUNCTION get_top_selling_products(start_date DATE, end_date DATE, limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    item_id TEXT,
    item_name TEXT,
    category TEXT,
    quantity_sold INTEGER,
    total_revenue DECIMAL(10,2),
    average_price DECIMAL(10,2),
    profit_margin DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.item_id,
        s.item_name,
        s.category,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as quantity_sold,
        COALESCE(SUM(s.total_price), 0.0) as total_revenue,
        COALESCE(AVG(s.selling_price), 0.0) as average_price,
        COALESCE(AVG(s.selling_price - i.purchase_price), 0.0) as profit_margin
    FROM sales s
    LEFT JOIN inventory i ON s.item_id = i.id
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY s.item_id, s.item_name, s.category
    ORDER BY quantity_sold DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Category Sales Performance Report
CREATE OR REPLACE FUNCTION get_category_sales_performance(start_date DATE, end_date DATE)
RETURNS TABLE (
    category TEXT,
    total_items_sold INTEGER,
    total_revenue DECIMAL(10,2),
    average_item_price DECIMAL(10,2),
    unique_products INTEGER,
    category_profit DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.category,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as total_items_sold,
        COALESCE(SUM(s.total_price), 0.0) as total_revenue,
        COALESCE(AVG(s.selling_price), 0.0) as average_item_price,
        COUNT(DISTINCT s.item_id)::INTEGER as unique_products,
        COALESCE(SUM(s.total_price - (s.quantity_sold * i.purchase_price)), 0.0) as category_profit
    FROM sales s
    LEFT JOIN inventory i ON s.item_id = i.id
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY s.category
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- Parts Sales Analysis Report
CREATE OR REPLACE FUNCTION get_parts_sales_analysis(start_date DATE, end_date DATE)
RETURNS TABLE (
    part_id TEXT,
    part_name TEXT,
    quantity_sold INTEGER,
    total_revenue DECIMAL(10,2),
    average_price DECIMAL(10,2),
    current_stock INTEGER,
    reorder_suggestion BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.item_id as part_id,
        s.item_name as part_name,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as quantity_sold,
        COALESCE(SUM(s.total_price), 0.0) as total_revenue,
        COALESCE(AVG(s.selling_price), 0.0) as average_price,
        COALESCE(i.quantity, 0)::INTEGER as current_stock,
        CASE 
            WHEN i.quantity <= 5 THEN TRUE 
            ELSE FALSE 
        END as reorder_suggestion
    FROM sales s
    LEFT JOIN inventory i ON s.item_id = i.id
    WHERE 
        DATE(s.sale_date) BETWEEN start_date AND end_date
        AND s.category = 'Parts'
    GROUP BY s.item_id, s.item_name, i.quantity
    ORDER BY quantity_sold DESC;
END;
$$ LANGUAGE plpgsql;

-- Sales Trend Analysis Report
CREATE OR REPLACE FUNCTION get_sales_trend_analysis(start_date DATE, end_date DATE)
RETURNS TABLE (
    sale_date DATE,
    daily_revenue DECIMAL(10,2),
    items_sold INTEGER,
    transaction_count INTEGER,
    average_transaction_value DECIMAL(10,2),
    unique_customers INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(s.sale_date),
        COALESCE(SUM(s.total_price), 0.0) as daily_revenue,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as items_sold,
        COUNT(DISTINCT s.receipt_id)::INTEGER as transaction_count,
        COALESCE(AVG(r.total_amount), 0.0) as average_transaction_value,
        COUNT(DISTINCT r.customer_phone)::INTEGER as unique_customers
    FROM sales s
    LEFT JOIN receipts r ON s.receipt_id = r.id
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY DATE(s.sale_date)
    ORDER BY DATE(s.sale_date);
END;
$$ LANGUAGE plpgsql;

-- Product Performance Metrics
CREATE OR REPLACE FUNCTION get_product_performance_metrics(start_date DATE, end_date DATE)
RETURNS TABLE (
    item_id TEXT,
    item_name TEXT,
    category TEXT,
    total_revenue DECIMAL(10,2),
    quantity_sold INTEGER,
    profit_margin DECIMAL(10,2),
    revenue_share DECIMAL(5,2),
    stock_turnover DECIMAL(5,2),
    days_to_stockout INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH total_sales AS (
        SELECT COALESCE(SUM(total_price), 0.0) as total_revenue
        FROM sales
        WHERE DATE(sale_date) BETWEEN start_date AND end_date
    )
    SELECT 
        s.item_id,
        s.item_name,
        s.category,
        COALESCE(SUM(s.total_price), 0.0) as total_revenue,
        COALESCE(SUM(s.quantity_sold)::INTEGER, 0) as quantity_sold,
        COALESCE(AVG(s.selling_price - i.purchase_price), 0.0) as profit_margin,
        COALESCE((SUM(s.total_price) / t.total_revenue * 100), 0.0) as revenue_share,
        CASE 
            WHEN i.quantity > 0 THEN
                COALESCE((SUM(s.quantity_sold)::DECIMAL / NULLIF(i.quantity, 0)), 0.0)
            ELSE 0.0
        END as stock_turnover,
        CASE 
            WHEN SUM(s.quantity_sold) > 0 THEN
                (i.quantity * DATE_PART('day', end_date - start_date) / SUM(s.quantity_sold))::INTEGER
            ELSE NULL
        END as days_to_stockout
    FROM sales s
    CROSS JOIN total_sales t
    LEFT JOIN inventory i ON s.item_id = i.id
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY s.item_id, s.item_name, s.category, i.quantity, t.total_revenue
    ORDER BY total_revenue DESC;
END;
$$ LANGUAGE plpgsql; 