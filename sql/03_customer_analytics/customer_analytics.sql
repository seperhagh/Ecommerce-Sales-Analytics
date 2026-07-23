-- -------------------------------------
-- Customer Segmentation
-- -------------------------------------
use ecommerce_analytics;
select customers.customer_unique_id as Customer_ID ,
		 count(distinct orders.order_id) as Total_Orders ,
			sum(order_items.price) as Total_Revenue ,
				min(orders.order_purchase_timestamp)  as First_Purchase ,
					max(orders.order_purchase_timestamp)  as Last_Purchase ,
                    sum(order_items.price) / count(distinct orders.order_id)  as Avg_Order_Value , 
                    case
                    when  count(distinct orders.order_id) > 10 then "VIP"
                    when  count(distinct orders.order_id) BETWEEN 5 AND 10 then "Loyal"
                    when  count(distinct orders.order_id) BETWEEN 2 AND 4 then "Regular"
                    when  count(distinct orders.order_id) = 1  then "New"
                    end as Customer_Segment
from orders
join customers
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
group by Customer_ID 
order by Total_Orders desc; 

-- -------------------------------------
-- Customer Purchase Frequency Analysis
-- -------------------------------------
use ecommerce_analytics ;
with CustomerOrders as (
    select 
        customer_id, 
        	COUNT(order_id) as total_orders
    from orders
    where order_status = 'delivered'
    group by customer_id
)
select 
   
    case 
        when total_orders = 1 then '1 Order'
        when total_orders between 2 and 5 then '2-5 Orders'
        when total_orders between 6 and 10 then '6-10 Orders'
        else '10+ Orders'
    end as Purchase_Frequency,
    
    count(customer_id) as Total_Customers
from CustomerOrders


group by 
    case 
        when total_orders = 1 then '1 Order'
        when total_orders between 2 and 5 then '2-5 Orders'
        when total_orders between 6 and 10 then '6-10 Orders'
        else '10+ Orders'
    end
order by min(total_orders);
-- -------------------------------------
-- Customer Revenue Segmentation
-- -------------------------------------
with SegmentedCustomers as (
    select customer_id,
				total_customer_revenue,
      
        case 
            when total_customer_revenue < 100 then 'Low Value'
            when total_customer_revenue >= 100 and total_customer_revenue < 500 then 'Medium Value'
            when total_customer_revenue >= 500 and total_customer_revenue < 2000 then 'High Value'
            
            else'VIP' 
        end as Revenue_Segment,

        CASE 
            when total_customer_revenue < 100 then 1
            when total_customer_revenue >= 100 and total_customer_revenue < 500 then 2
            when total_customer_revenue >= 500 and total_customer_revenue < 2000 then 3
            else 4 
        end as segment_order
    from customer_summary
)

select Revenue_Segment ,
			COUNT(customer_id) as Total_Customers ,
				sum(total_customer_revenue) as Total_Revenue
from   SegmentedCustomers
group by  Revenue_Segment ,  segment_order
order by  segment_order ;



-- -------------------------------------
-- RFM Analysis
-- -------------------------------------
with Customer_RFM   as (
    select customer_id ,
				total_orders  as Frequency,
					First_order_date , 
						Last_order_date ,
							datediff((select  max(last_order_date) from customer_summary) , Last_order_date ) as Recency_Days ,
								total_customer_revenue as Monetary  
						
					
    from customer_summary
   
    ),
   Segment as (
   select customer_id ,
			case 
				when Recency_Days <=60 and Frequency >=8 and Monetary >=2000 then 'Champions'
				when Recency_Days <=90 and Frequency >=4 and  Monetary >1000 then 'Loyal'
				when Recency_Days <=90 and Frequency >=2 then 'Potential Loyal'
				when Recency_Days >90 and (Frequency >=2 or Monetary >=500) then 'At Risk'
				else'Lost' 
				end as Customer_Segment , 
                case 
				when Recency_Days <=60 and Frequency >=8 and Monetary >=2000 then 1
				when Recency_Days <=90 and Frequency >=4 and  Monetary >1000 then 2
				when Recency_Days <=90 and Frequency >=2 then 3
				when Recency_Days >90 and (Frequency >=2 or Monetary >=200) then 4
				else 5 
				end as Customer_Segment_order
	from Customer_RFM
   )
    select  Customer_RFM.customer_id ,
				Customer_RFM.Frequency,
					Customer_RFM.First_order_date , 
						Customer_RFM.Last_order_date ,
							Customer_RFM.Recency_Days ,
								Customer_RFM.Monetary  ,
									Segment.Customer_Segment
    from Customer_RFM  
    left join Segment
    on Segment.customer_id = Customer_RFM.customer_id
    order by Customer_Segment_order 

-- -------------------------------------
-- Customer Cohort Analysis
-- -------------------------------------
with customer_cohort as (
    select customers.customer_unique_id as  customer_id,
				date_format(min(orders.order_purchase_timestamp), "%Y-%m") as cohort_month,
					min(orders.order_purchase_timestamp) as first_order_date
    from orders
    join customers on customers.customer_id = orders.customer_id
    where orders.order_status = "delivered"
    group by customers.customer_unique_id
),

order_activity as (
    select customers.customer_unique_id as customer_id,
				date_format(orders.order_purchase_timestamp, "%Y-%m") as order_month,
					orders.order_purchase_timestamp as order_date
    from orders
    join customers on customers.customer_id = orders.customer_id 
    where orders.order_status = "delivered"

),

cohort_overview as (
    select customer_cohort.customer_id ,
				customer_cohort.cohort_month ,
						order_month ,
							(year(order_activity.order_date) - year(customer_cohort.first_order_date)) * 12 + (month(order_activity.order_date) - month(customer_cohort.first_order_date)) as cohort_index
    from customer_cohort
    join order_activity on customer_cohort.customer_id = order_activity.customer_id
),

cohort_counts as (
    select cohort_month ,
				order_month ,
					cohort_index ,
						count(distinct customer_id) as customers_retained
    from cohort_overview
    group by cohort_month, cohort_index , order_month
)

select cohort_month,
			order_month , 
				cohort_index,
					customers_retained,
						max(case when cohort_index = 0 then customers_retained end) over (partition by cohort_month) as cohort_size,
							round((customers_retained * 100.0) / max(case when cohort_index = 0 then customers_retained end) over (partition by cohort_month), 2) as  retention_rate
from cohort_counts
order by cohort_month, cohort_index;
-- -------------------------------------
-- Customer Churn Analysis
-- -------------------------------------
with customer_segmentation as (
	select customer_id,
				total_customer_revenue,
					total_orders,
                    	datediff((select max(last_order_date) from customer_summary),last_order_date) as  recency_days 
		
    from customer_summary
)
SELECT
    case
		when recency_days <= 30 then "Active" 
		when recency_days between 31 and 90 then "At Risk" 
		when recency_days > 90  then "Churned" 
		end as Churn_Status ,
    COUNT(customer_id) AS Total_Customers,
    	ROUND(AVG(total_customer_revenue), 2) AS Average_Revenue,
    		ROUND(AVG(total_orders), 1) AS Average_Orders
FROM customer_segmentation
GROUP BY Churn_Status
ORDER BY 
	CASE Churn_Status
        WHEN 'Active' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Churned' THEN 3
    END;

-- -------------------------------------
-- Customer Purchase Interval
-- -------------------------------------
with  customer_orders as (
    select customers.customer_unique_id as customer_id,
        		orders.order_purchase_timestamp,
        			lag(orders.order_purchase_timestamp) over (partition by customers.customer_unique_id order by orders.order_purchase_timestamp) as previous_purchase_date
    from orders 
    JOIN customers  on orders.customer_id = customers.customer_id
),

order_intervals as (
    select 
        customer_id,
        	order_purchase_timestamp,
        		previous_purchase_date,
        			DATEDIFF(order_purchase_timestamp, previous_purchase_date) as days_between_orders
    from customer_orders
)

select 
    customer_id,
    round(avg(days_between_orders), 2) as Average_Days_Between_Orders,
    count(*) as Total_Orders
from order_intervals
group by customer_id
having count(days_between_orders) > 0;

-- -------------------------------------
-- Customer Revenue Distribution
-- -------------------------------------

use ecommerce_analytics ;
with  Revenue_Distribution as (
   select 
			customer_id	,
				total_customer_revenue 
					
   from customer_summary

	) ,
	Revenue_Range as(
	select customer_id ,
			case
				when total_customer_revenue  <= 100 then "0–100"
				when total_customer_revenue  <= 500 then "100–500"
				when total_customer_revenue  <= 1000 then "500–1000"
				when total_customer_revenue  <= 5000 then "1000–5000"
				else "5000+"
			end as Revenue_Range ,
			case
				when total_customer_revenue  <= 100 then 1
				when total_customer_revenue  <= 500 then 2
				when total_customer_revenue  <= 1000 then 3
				when total_customer_revenue  <= 5000 then 4
				else 5
			end as Revenue_Order
        
	from Revenue_Distribution
     
	)



	select Revenue_Range ,
				count(Revenue_Distribution.customer_id)	as total_customer,
					sum(total_customer_revenue) as total_revenue,
						avg(total_customer_revenue) as Avg_Revenue
					
	from Revenue_Distribution
	left join Revenue_Range
	on Revenue_Range.customer_id = Revenue_Distribution.customer_id
	GROUP BY Revenue_Range, Revenue_Order
    order by Revenue_Range.Revenue_Order

-- -------------------------------------
-- Customer Dashboard Dataset
-- -------------------------------------

use ecommerce_analytics ;
with views as (
select customer_id ,
			total_orders,
				total_customer_revenue,
					average_order_revenue,
						average_delivery_days ,
							average_review_score,
								First_order_date,
									Last_order_date ,
										Favorite_Category ,
											Favorite_Payment 
from customer_summary 
),
dates as(
select customer_id ,
			datediff((select MAX(last_order_date) from customer_summary),First_order_date) as  Customer_Age_Days ,
					datediff((select max(last_order_date) from customer_summary),last_order_date) as  recency_days 
		
from views

)
select 	views.customer_id ,
			views.total_orders ,
				views.total_customer_revenue ,
					views.average_order_revenue ,
						views.average_delivery_days ,
							views.average_review_score ,
								views.First_order_date ,
									views.Last_order_date ,
										views.Favorite_Category ,
											views.Favorite_Payment ,
												dates.Customer_Age_Days ,
													dates.recency_days ,
														ROUND(views.total_customer_revenue / Customer_Age_Days,2) as Average_Revenue_Per_Day,
															case	
																when recency_days <= 30 then "Active" 
																when recency_days between 31 and 90 then "At Risk" 
																when recency_days > 90  then "Churned" 
															end as Churn_Status ,
															case 
																when total_customer_revenue < 100 then 'Low Value'
																when total_customer_revenue >= 100 and total_customer_revenue < 500 then 'Medium Value'
																when total_customer_revenue >= 500 and total_customer_revenue < 2000 then 'High Value'
																else'VIP' 
															end as Revenue_Segment

 from views
 left join dates
 on dates.customer_id = views.customer_id
 