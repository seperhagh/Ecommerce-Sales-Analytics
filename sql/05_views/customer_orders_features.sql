
create or replace view customer_orders_features as
with Order_Base as (
    select  
        customers.customer_unique_id as customer_id, 
        orders.order_id as order_id, 
        orders.order_purchase_timestamp, 
        orders.order_delivered_customer_date,
        DATEDIFF(orders.order_delivered_customer_date, orders.order_purchase_timestamp) as Delivery_Days ,
        MIN(order_purchase_timestamp)
			over(partition by customers.customer_unique_id) as   First_order_date ,
		MAX(order_purchase_timestamp)
			over(partition by customers.customer_unique_id) as last_order_date 
            
    from orders 
    join customers on customers.customer_id = orders.customer_id
    where orders.order_status = 'delivered'
    
),
Order_Aggregates as(
    select 
        order_id,
        SUM(price) as Total_Revenue,
        COUNT(order_items.order_id) as Item_Count ,
        avg(order_items.price) as Avg_Item_Price 
    from order_items  
    group by order_id
),
Review_Aggregates as (
    select
        order_id,
        avg(review_score) as review_score
    from order_reviews
    group by order_id
),
Category_Ranked as (
    select 
        customer_id, 
        category,
        row_number() over(partition by customer_id order by purchase_count desc , category) as Ranks
    from (
        select 
            customers.customer_unique_id as customer_id,
            product_category_translation.product_category_name_english as category,
            COUNT(order_items.order_item_id) as purchase_count
        from orders 
        join customers 
			on customers.customer_id = orders.customer_id
        join order_items 
			on order_items.order_id = orders.order_id
        join products  
			on products.product_id = order_items.product_id  
        join product_category_translation 
			on product_category_translation.product_category_name = products.product_category_name  
        where orders.order_status = 'delivered'
        group by customers.customer_unique_id, product_category_translation.product_category_name_english) base_categories
),
Payment_Ranked as (
    select 
        customer_id, 
        payment_type,
        row_number() over (partition by customer_id order by payment_count desc, payment_type) as Ranks
    from (
        select 
            customers.customer_unique_id as customer_id, 
            order_payments.payment_type, 
            COUNT(distinct orders.order_id) as payment_count
        from orders 
        join customers  
        on customers.customer_id = orders.customer_id
        join order_payments  
        on order_payments.order_id = orders.order_id
        where orders.order_status = 'delivered'
        group by customers.customer_unique_id, order_payments.payment_type
    ) base_payments
)
select 
    Order_Base.customer_id ,
    Order_Base.order_id ,
    Order_Base.order_purchase_timestamp ,
    Order_Base.order_delivered_customer_date ,
    Order_Base.First_order_date ,
    Order_Base.last_order_date ,
    Order_Base.Delivery_Days ,
    Order_Aggregates.Total_Revenue , 
    Order_Aggregates.Item_Count ,
    Order_Aggregates.Avg_Item_Price ,
    Review_Aggregates.review_score ,
    Category_Ranked.category as Favorite_Category ,
    Payment_Ranked.payment_type as Favorite_Payment
from Order_Base 
left join Order_Aggregates  
	on Order_Base.order_id = Order_Aggregates.order_id
left join Review_Aggregates  
	on Order_Base.order_id = Review_Aggregates.order_id
left join Category_Ranked 
	on Category_Ranked.customer_id = Order_Base.customer_id and Category_Ranked.Ranks = 1
LEFT join Payment_Ranked  
	on Payment_Ranked.customer_id = Order_Base.customer_id and Payment_Ranked.Ranks = 1;
