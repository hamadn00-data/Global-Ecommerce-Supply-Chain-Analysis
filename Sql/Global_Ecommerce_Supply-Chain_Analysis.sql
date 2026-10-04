Create Table customers (
customer_id Varchar(100),
first_name Varchar(50),
last_name Varchar(50),
country Varchar(50),
currency Varchar(10),
age int,
gender Varchar(10),
registration_date Date,
is_premium Boolean,
email_verified boolean,
email Varchar(100)
);

Create Table inventory (
product_id Varchar(100),
category Varchar(100),
stock_units int, 
reorder_point int, 
warehouse_location Varchar(100),
last_restock_date Date, 
supplier_lead_days int
);

Create Table marketing_spend(
year_month Varchar(10),
channel Varchar(50),
spend_usd float,
impressions int,
clicks int,
ctr float,
actual_orders int,
actual_customers int,
actual_revenue_usd float,
roas float,
cac_usd float,
cost_per_order_usd float,
month_multiplier float
);

Create Table price_history(
product_id Varchar(50),
category Varchar(50),
year_month Varchar(10),
listed_price_usd float,
base_price_usd float,
competitor_price_usd float,
price_index float,
is_promotional Boolean,
price_elasticity float,
units_sold int, 
revenue_usd float,
margin_pct float
);

Create Table products (
product_id Varchar(20),
name Varchar(50),
category Varchar(20),
brand Varchar(50),
unit_price_usd float,
unit_cost_usd float,
weight_kg float,
is_active Boolean,
launch_date Date
);

Create Table returns (
return_id Varchar(20),
transaction_id Varchar(20),
customer_id Varchar(20),
product_id Varchar(20),
return_date Date,
reason Varchar(50),
refund_amount_usd float,
restocked Boolean
);

Create Table supplier_costs (
product_id Varchar(20),
category Varchar(20),
supplier_name Varchar(20),
supplier_rank int,
unit_cost_usd float,
ordering_cost_usd float,
annual_holding_cost_usd float,
holding_cost_pct float,
lead_time_days int,
min_order_qty int,
reliability_score float,
is_primary Boolean
);

Create Table transactions (
transaction_id Varchar(20),
customer_id Varchar(20),
product_id Varchar(20),
date Date,
quantity int,
unit_price_usd float,
discount_pct float,
revenue_usd float,
cost_usd float,
profit_usd float,
shipping_cost_usd float,
channel Varchar(20),
payment_method Varchar(20),
status Varchar(20),
country Varchar(20),
category Varchar(20)
);


Select * from customers;
Select * from inventory;
Select * from marketing_spend;
Select * from price_history;
Select * from products;
Select * from returns;
Select * from supplier_costs;
Select * from transactions;


--- 1. Monthly Revenue and Profit Trend ---
Select To_char(date, 'MM') as month,
count(*) as total_transactions, sum(quantity) as units_sold, 
Round(sum(revenue_usd)::numeric, 2) as total_revenue, Round(sum(profit_usd)::numeric, 2) as total_profit,
Round(avg(revenue_usd)::numeric, 2) as average_revenue
from transactions
where status = 'completed'
group by month
order by To_char(date, 'MM');

--- 2. Revenue and Profit by Sales Channel ---
Select channel, count(*) as total_transactions, sum(quantity) as units_sold, 
Round(sum(revenue_usd)::numeric, 2) as total_revenue, Round(sum(profit_usd)::numeric, 2) as total_profit,
Round(sum(profit_usd)::numeric / Nullif(sum(revenue_usd)::numeric, 0) * 100, 2) as profit_margin_pct
from transactions
where status = 'completed'
group by channel
order by total_revenue desc;

--- 3. Top 10 Products by Revenue ---
Select t.product_id, p.name as product_name, p.category, p.brand,
sum(t.quantity) as units_sold, 
Round(sum(t.revenue_usd)::numeric, 2) as total_revenue, 
Round(sum(t.profit_usd)::numeric, 2) as total_profit
from transactions t
join 
products p
on t.product_id = p.product_id
where t.status = 'completed'
Group by t.product_id, p.name, p.category, p.brand
order by total_revenue desc
Limit 10;

--- 4. Top 10 Products by Profit Margin ---
Select t.product_id, p.name as product_name, p.category, p.brand,
count(*) as total_transactions,
sum(t.quantity) as units_sold, 
Round(sum(t.revenue_usd)::numeric, 2) as total_revenue, 
Round(sum(t.profit_usd)::numeric, 2) as total_profit,
Round(sum(t.profit_usd)::numeric / Nullif(sum(t.revenue_usd)::numeric, 0) * 100, 2) as profit_margin_pct
from transactions t
join 
products p
on t.product_id = p.product_id
where t.status = 'completed'
Group by t.product_id, p.name, p.category, p.brand
HAVING COUNT(*) >= 20
order by profit_margin_pct desc
Limit 10;

--- 5. Category Contribution to Total Revenue ---
With t1 as (
Select category, sum(revenue_usd) as category_revenue
from transactions
where status = 'completed'
group by category),
t2 as (
Select sum(category_revenue) as total_revenue
from t1)
Select t1.category, Round(t1.category_revenue::numeric, 2),
Round(t1.category_revenue::numeric/t2.total_revenue::numeric * 100, 2) as revenue_contribution_pct
from t1
cross join
t2
order by revenue_contribution_pct desc;

--- 6. Customer Lifetime Revenue ---
Select c.customer_id, c.first_name, c.last_name, c.country, c.is_premium,
count(t.transaction_id) as total_orders, sum(t.quantity) as total_quantity,
Round(sum(t.revenue_usd)::numeric, 2) as total_revenue,
Round(sum(t.profit_usd)::numeric, 2) as total_profit,
Round(avg(t.revenue_usd)::numeric, 2) as average_revenue
from customers c
join transactions t
on c.customer_id = t.customer_id
where t.status = 'completed'
Group by c.customer_id, c.first_name, c.last_name, c.country, c.is_premium
Order by total_revenue desc;

--- 7. Top 20 Customers by Revenue ---
With t1 as (
Select c.customer_id, c.first_name, c.last_name, c.country, c.is_premium,
count(t.transaction_id) as total_orders, sum(t.quantity) as total_quantity,
Round(sum(t.revenue_usd)::numeric, 2) as total_revenue,
Round(sum(t.profit_usd)::numeric, 2) as total_profit,
Round(avg(t.revenue_usd)::numeric, 2) as average_revenue
from customers c
join transactions t
on c.customer_id = t.customer_id
where t.status = 'completed'
Group by c.customer_id, c.first_name, c.last_name, c.country, c.is_premium
Order by total_revenue desc),
t2 as (
Select *, dense_rank() over(Order by total_revenue desc) as revenue_rank
from t1
)
Select * from t2
where revenue_rank < 21;

--- 8. Premium vs Non-Premium Customer Performance ---
Select c.is_premium, count(Distinct c.customer_id) as total_customers,
count(t.transaction_id) as total_orders,
Round(sum(t.revenue_usd)::numeric, 2) as total_revenue,
Round(sum(t.profit_usd)::numeric, 2) as total_profit,
Round(avg(t.revenue_usd)::numeric, 2) as average_revenue
from customers c
join
transactions t
on c.customer_id = t.customer_id
where status = 'completed'
group by c.is_premium

--- 9. High-Revenue but Low-Profit Customers ---
With t1 as (
Select customer_id, Round(sum(revenue_usd)::numeric, 2) as total_revenue,
Round(sum(profit_usd)::numeric, 2) as total_profit,
Round(sum(profit_usd)::numeric / Nullif(sum(revenue_usd)::numeric, 0) * 100, 2) as profit_margin
from transactions
where status = 'completed'
Group by customer_id),
t2 as (
Select percentile_cont(0.80) Within group (order by total_revenue) as high_revenue_threshold,
Round(avg(total_profit)::numeric, 2) as average_profit_margin
from t1)
Select t1.customer_id, t1.total_revenue, t1.total_profit, t1.profit_margin
from t1
cross join t2
where t1.total_revenue >= t2.high_revenue_threshold
and
t1.profit_margin < t2.average_profit_margin
order by t1.total_revenue desc

--- 10. Discount Impact on Product Performance ---
Select t.product_id, p.name, p.category, Round(sum(revenue_usd)::numeric, 2) as total_revenue,
Round(sum(profit_usd)::numeric, 2) as total_profit,
Round(avg(discount_pct)::numeric, 2) as avg_discount_pct,
Round(sum(profit_usd)::numeric / Nullif(sum(revenue_usd)::numeric, 0) * 100, 2) as profit_margin
from transactions t
join products p
on t.product_id = p.product_id
where t.status = 'completed'
group by t.product_id, p.name, p.category
order by avg_discount_pct desc;

--- 11. Monthly Price and Sales Performance ---
Select product_id, year_month, listed_price_usd, competitor_price_usd, price_elasticity, is_promotional,
units_sold, revenue_usd, margin_pct
from price_history
order by product_id, year_month;

--- 12. Products Priced Above vs Below Competitors ---
Select case 
          When listed_price_usd > competitor_price_usd Then 'Above Competitor'
		  When listed_price_usd < competitor_price_usd Then 'Below Competitor'
		  Else 'Same Price'
		  End as price_position,
count(*) as product_months,
Round(avg(units_sold)::numeric, 2) as avg_units_sold,
Round(avg(revenue_usd)::numeric, 2) as avg_revenue,
Round(avg(margin_pct)::numeric, 2) as avg_margin_pct
from price_history
group by 
      case 
          When listed_price_usd > competitor_price_usd Then 'Above Competitor'
		  When listed_price_usd < competitor_price_usd Then 'Below Competitor'
		  Else 'Same Price'
		  End
Order by avg_revenue desc;

--- 13. Month-over-Month Revenue Growth ---
With t1 as (
Select To_char(date, 'Month') as month, To_char(date, 'MM') as month_no,
Round(sum(revenue_usd)::numeric, 2) as total_revenue
from transactions
where status = 'completed'
group by month, month_no
order by month_no),
t2 as (
Select month, month_no, total_revenue, 
lag(total_revenue) over(order by month_no) as previous_month_revenue
from t1)
Select month, total_revenue, previous_month_revenue,
ROUND(
        (total_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS growth_pct
from t2
order by month_no

--- 14. Marketing Channel Performance ---
Select channel, count(*) as months, 
Round(sum(spend_usd)) as total_spend, Round(sum(actual_orders)) as total_orders,
Round(sum(actual_customers)) as total_customers,
Round(sum(actual_revenue_usd)) as total_revenue,
Round(sum(actual_revenue_usd)::numeric / Nullif(sum(spend_usd)::numeric, 0), 2) as actual_roas,
Round(sum(spend_usd)::numeric / Nullif(sum(actual_customers)::numeric, 0), 2) as customer_acquisition_cost
from marketing_spend
group by channel
order by total_revenue desc;
		  
--- 15. Marketing Spend vs Revenue by Month ---
with t1 as (
Select To_char(date, 'YYYY-MM') as month,
Round(sum(revenue_usd)::numeric, 2) as total_revenue,
count(*) as total_orders
from transactions
where status = 'completed'
group by month
order by month)
Select to_date(m.year_month, 'YYYY-MM') as month, m.channel, m.spend_usd, t1.total_revenue, t1.total_orders,
Round(t1.total_revenue::numeric / Nullif(m.spend_usd::numeric, 0), 2) as revenue_per_dollar_spent
from marketing_spend m
join
t1
on m.year_month = t1.month
order by month, channel

--- 16. Return Rate by Product Category ---
With t1 as (
Select p.category, count(t.transaction_id) as total_transactions
from products p
join
transactions t
on p.product_id = t.product_id
where t.status = 'completed'
group by p.category),
t2 as (
Select p.category, count(r.transaction_id) as returned_transactions,
Round(sum(r.refund_amount_usd)::numeric, 2) as total_refunds
from products p
join
returns r
on p.product_id = r.product_id
group by p.category)
Select t1.category, t1.total_transactions,
t2.returned_transactions, t2.total_refunds,
Round(t2.returned_transactions::numeric / nullif(t1.total_transactions::numeric, 0) * 100, 2) as return_rate_pct
from t1
join t2
on t1.category = t2.category
order by return_rate_pct desc

--- 17. High-Revenue AND High-Return Products ---
With t1 as (
Select t.product_id, Round(sum(t.revenue_usd)::numeric, 2) as total_revenue,
count(Distinct t.transaction_id) as transactions,
count(Distinct r.transaction_id) as returns,
Round(count(Distinct r.transaction_id)::numeric / Nullif(count(Distinct t.transaction_id)::numeric, 0) * 100, 2)
as return_rate
from transactions t
left join
returns r
on t.transaction_id = r.transaction_id
where t.status = 'completed'
group by t.product_id),
t2 as (
Select percentile_cont(0.80) within group(order by total_revenue) as high_revenue,
percentile_cont(0.80) within group(order by return_rate) as high_return_rate
from t1)
Select t1.product_id, p.name, p.category, t1.total_revenue, t1.transactions, t1.returns, t1.return_rate
from t1
join products p
on t1.product_id = p.product_id
cross join t2
where t1.total_revenue >= t2.high_revenue
and t1.return_rate >= t2.high_return_rate
order by t1.total_revenue desc;

--- 18. Products Below Reorder Point ---
Select i.product_id, p.name, p.category, i.stock_units, i.reorder_point,
i.stock_units - i.reorder_point as stock_difference,
i.warehouse_location, i.supplier_lead_days, i.last_restock_date
from inventory i
join
products p
on i.product_id = p.product_id
where i.stock_units < i.reorder_point
order by stock_difference;

--- 19. Supplier Performance Analysis ---
Select supplier_name, 
count(Distinct product_id) as products_supplied,
Round(avg(unit_cost_usd)::numeric, 2) as avg_units_cost,
Round(avg(lead_time_days), 2) as avg_lead_days,
Round(avg(reliability_score)::numeric, 2) as avg_reliability_Score,
sum(case when is_primary Then 1 Else 0 End) as primary_supplier_products
from supplier_costs
group by supplier_name
order by avg_reliability_Score desc;

--- 20. Products with Supply-Chain Risk ---
Select i.product_id, p.name, p.category, i.stock_units, i.reorder_point,
s.supplier_name, s.lead_time_days, s.reliability_score, s.unit_cost_usd
from inventory i
join products p
on i.product_id = p.product_id
join supplier_costs s
on i.product_id = s.product_id
where i.stock_units < i.reorder_point
and s.lead_time_days >= 10
and s.reliability_score < 0.90
order by s.reliability_score asc,
         s.lead_time_days desc;









