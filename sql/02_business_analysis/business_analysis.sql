-- -------------------------------------
-- Database Overview
-- -------------------------------------
use ecommerce_analytics ;
select "total_customers"  as KPI , count(*) as VALUE
from customers  
union all
select  "total_products" ,count(*)  
from  products 
union all
select  "total_orders" ,count(*)  
from  orders
union all
select  "total_sellers" ,count(*)  
from  sellers 
union all
select  "total_categories" ,count(*)  
from  product_category_translation
union all
select  "total_reviews" ,count(*)  
from  order_reviews 
union all
select  "total_payments" ,count(*)  
from  order_payments 
union all
select  "total_order_items" ,count(*)  
from  order_items ;


-- -------------------------------------
-- Monthly Growth Rate
-- -------------------------------------
with purchase_timestamp as (
select 	  
			year(orders.order_purchase_timestamp) as Year, 
				monthname(orders.order_purchase_timestamp) as Months ,
                    month(orders.order_purchase_timestamp) as Month_number ,
					    sum(order_payments.payment_value) as Total_Revenue ,
						    lag(sum(order_payments.payment_value)) over(order by year(orders.order_purchase_timestamp) ,
                                 month(orders.order_purchase_timestamp)) as Previous_Month_Revenue
							
					


from orders 
join order_payments
on order_payments.order_id = orders.order_id
where orders.order_status = "delivered"
group by Year , Month_number, Months  


)
select    Year , 
			Months , 
				Total_Revenue , 
					Previous_Month_Revenue , 
						round(((Total_Revenue -Previous_Month_Revenue) / Previous_Month_Revenue) * 100 , 2 ) as Growth_Percentage
from purchase_timestamp 
order by year , Month_number 	

-- -------------------------------------
-- Revenue by State
-- -------------------------------------
use ecommerce_analytics ; 
select customers.customer_state as Customer_State , 
			count(orders.order_id) as Total_Orders ,
				sum(order_items.price) as Total_Revenue ,
					sum(order_items.price) / count(distinct orders.order_id) as Average_Order_Value


from orders 
join customers
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
where orders.order_status = "delivered"
group by Customer_State 
order by Total_Revenue desc ;

-- -------------------------------------
-- -- Top 10 Sellers by Revenue
-- -------------------------------------
select seller_id as Sellers , sum(price) as Total_Revenue 
from order_items 
group by Sellers
order by Total_Revenue desc
limit 10 ;
-- -------------------------------------
-- Monthly Order Trend
-- -------------------------------------
SELECT
    YEAR(order_purchase_timestamp) AS Year,
    MONTHNAME(order_purchase_timestamp) AS Months_Name,
    COUNT(*) AS Total_Orders
FROM orders
GROUP BY
    YEAR,
    MONTH(order_purchase_timestamp),
    Months_Name
ORDER BY
    Year,
    MONTH(order_purchase_timestamp);

-- -------------------------------------
-- Monthly Revenue Trend
-- -------------------------------------
SELECT
    YEAR(orders.order_purchase_timestamp) AS Year,
    MONTHNAME(orders.order_purchase_timestamp) AS Months_Name,
    sum(order_payments.payment_value) AS Total_Revenue
FROM order_payments
join orders
on orders.order_id = order_payments.order_id
GROUP BY
    YEAR,
    MONTH(orders.order_purchase_timestamp),
    Months_Name
ORDER BY
    Year,
    MONTH(orders.order_purchase_timestamp);

-- -------------------------------------
-- Top 10 Customers by Spending
-- -------------------------------------
SELECT
    customers.customer_unique_id AS Customer_ID,
    COUNT(DISTINCT orders.order_id) AS Total_Orders,
    SUM(order_items.price) AS Total_Revenue
FROM customers 
JOIN orders
    ON  customers.customer_id = orders.customer_id
JOIN order_items 
    ON orders.order_id = order_items.order_id
GROUP BY  customers.customer_unique_id
ORDER BY Total_Revenue DESC
LIMIT 10;

-- -------------------------------------
-- Top 10 Cities by Revenue
-- -------------------------------------
select customers.customer_city as Customer_City, sum(order_payments.payment_value) as Total_Revenue
from orders
join customers
on customers.customer_id = orders.customer_id
join order_payments
on order_payments.order_id =  orders.order_id
group by Customer_City
order by Total_Revenue desc
limit 10 ;


-- -------------------------------------
-- Order Status Distribution
-- -------------------------------------
select   "Successful Orders" as Status , round(count(case when order_status ="delivered" then 1 end) *100 / count(*) ,2)as VALUE , count(case when order_status ="delivered" then 1 end) as Total_Orders
from orders
union all
select  "In Progress"  ,round(count(case when order_status ="created" or order_status ="approved" or order_status ="invoiced" or order_status ="processing" or order_status ="shipped" then 1 end) *100 / count(*),2) , count(case when order_status ="created" or order_status ="approved" or order_status ="invoiced" or order_status ="processing" or order_status ="shipped" then 1 end)
from orders 
union all
select  "Failed Orders"  ,round(count(case when order_status ="canceled" or order_status ="unavailable" then 1 end) *100 / count(*),2) , count(case when order_status ="canceled" or order_status ="unavailable" then 1 end)
from orders ;


-- -------------------------------------
-- Average Delivery Time by State
-- -------------------------------------

select customers.customer_state as Customer_State ,avg(datediff(orders.order_delivered_customer_date,orders.order_purchase_timestamp)) as Average_Delivery_Days
from orders
join customers
on customers.customer_id = orders.customer_id
WHERE orders.order_status = 'delivered'
group by Customer_State 
order by Average_Delivery_Days desc


-- -------------------------------------
-- Average Order Value (AOV)
-- -------------------------------------

select  count(DISTINCT orders.order_id) as Total_Orders  ,sum(order_items.price) as Total_Revenue, sum(order_items.price) /COUNT(DISTINCT orders.order_id) as Average_Order_Value
from orders
join order_items
on order_items.order_id = orders.order_id


-- -------------------------------------
-- Payment Method Analysis
-- -------------------------------------
select order_payments.payment_type as Payment_Method ,
            count(order_payments.payment_type) as Total_Transactions ,
                sum(order_payments.payment_value) as Total_Revenue
from order_payments
group by Payment_Method 
order by Total_Revenue desc ;













































