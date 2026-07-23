-- -------------------------------------
-- Top 10 Product Categories by Revenue
-- -------------------------------------
select product_category_translation.product_category_name_english as category ,sum(order_items.price) as Total_Revenue
from order_items 


join products
on products.product_id = order_items.product_id


join product_category_translation
on product_category_translation.product_category_name = products.product_category_name


join orders
on orders.order_id = order_items.order_id


group by category
order by Total_Revenue desc
limit 10; 
-- -------------------------------------
-- Average Review Score by Product Category
-- -------------------------------------
select product_category_translation.product_category_name_english as categorys , avg(order_reviews.review_score) as Review_Score
from orders


join order_items
on order_items.order_id = orders.order_id
join products
on products.product_id = order_items.product_id
join product_category_translation
on product_category_translation.product_category_name = products.product_category_name
join order_reviews 
on   order_reviews.order_id = orders.order_id
group by categorys 
order by Review_Score desc ; 





-- -------------------------------------
-- Product Performance Dashboard
-- -------------------------------------

with Product_Performance as (
select products.product_id as Product_ID,
			product_category_translation.product_category_name_english as Category,
				orders.order_id as order_id,
					order_items.price as Revenue,
						order_reviews.review_score as Review_Score
							
                        
					
from orders 
join order_items
on order_items.order_id = orders.order_id
join products
on products.product_id = order_items.product_id
join product_category_translation
on product_category_translation.product_category_name = products.product_category_name
join order_reviews 
on order_reviews.order_id = orders.order_id
where orders.order_status = "delivered"

)
select Product_ID ,
			Category ,
				count(distinct order_id) Total_order,
					sum(Revenue) as Total_Revenue,
						avg(Revenue) as Average_Selling_Price ,
							avg(Review_Score) as Average_Review_Score,
								dense_rank() over (order by sum(Revenue) desc) as Revenue_Rank
                        
 from Product_Performance
 
 group by Product_ID , Category 
 ORDER BY Total_Revenue desc
 limit 20 ;


 -- -------------------------------------
-- Pareto Analysis
-- -------------------------------------
with product_sales as (
    select products.product_id,
				products.product_category_name as product_category,
					count(distinct order_items.order_id) total_orders,
						sum(order_items.price) total_revenue
    from order_items
    join products on order_items.product_id = products.product_id
    group by products.product_id, products.product_category_name
),
pareto_calc as (
    select product_id,
				product_category,
					total_orders,
						total_revenue,
							dense_rank() over (order by total_revenue desc) revenue_rank,
									(total_revenue / sum(total_revenue) over ()) * 100 revenue_share,
										(sum(total_revenue) over (order by total_revenue desc) / sum(total_revenue) over ()) * 100 cumulative_revenue_share
    from product_sales
)
select 
    product_id,
    product_category,
    total_orders,
    round(total_revenue, 2) total_revenue,
    revenue_rank,
    round(revenue_share, 2) revenue_share,
    round(cumulative_revenue_share, 2) cumulative_revenue_share,
    case 
        when cumulative_revenue_share <= 80 then "core products"
        when cumulative_revenue_share <= 95 then "regular products"
        else "low impact products"
    end pareto_group
from pareto_calc
order by total_revenue desc;