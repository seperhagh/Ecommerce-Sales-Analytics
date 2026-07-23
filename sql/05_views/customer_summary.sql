create or replace view customer_summary as 
select
    customer_id,
    count(order_id) as total_orders,
    sum(total_revenue) as total_customer_revenue,
    avg(total_revenue) as average_order_revenue,
    avg(delivery_days) as average_delivery_days ,
    avg(review_score) as average_review_score,
    min(First_order_date) as   First_order_date,
    max(last_order_date) as   Last_order_date ,
    max(Favorite_Category) as   Favorite_Category ,
    max(Favorite_Payment) as Favorite_Payment
    
from customer_orders_features
group by customer_id;
