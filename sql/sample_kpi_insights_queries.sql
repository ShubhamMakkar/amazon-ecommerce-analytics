-- ============================================
-- Amazon E-commerce Capstone Project (SQL Insights)
-- Author: Shubham Makkar
-- ============================================

-- 1) Average Orders per Customer

select round((Total_Orders / Total_Customers),2) as Avg_Order_Per_Csutomer from
(select count(oid) as Total_Orders, count(distinct cid) as Total_Customers
from orders) as dt;

-- 2) Total Revenue

select sum(p.price) as Total_Revenue 
from orders as o join products as p
on p.pid = o.pid;

-- 3) Age group analysis 

select min(age) as Min_Age from customers; # 18
select max(age) as Max_Age from customers; # 60

select Age_Group, count(oid) as Orders from
(select c.age, o.oid, case 
when age>=18 and age<=25 then '18-25'
when age>=26 and age<=35 then '26-35'
when age>=36 and age<=45 then '36-45'
when age>=46 and age<=55 then '46-55'
else '56-60'
end as Age_Group
from customers as c join orders as o
on c.cid = o.cid
order by age) as dt
group by Age_Group
order by Orders desc;

-- 4) Monthly Contribution to New Customer Acquisition

select Year, Month_Name, New_Customers from
(select year(Join_Date) as Year,month (Join_Date) as Month ,
monthname(Join_Date) as Month_name,
count(cid) as New_Customers from 

(select  cid, min(order_date) as Join_Date
from orders group by cid ) as dt
group by Year, Month, Month_Name
order by year, Month) as dt2;

-- 5) City-wise Order Volume & Average Order Value

select City, Order_Volume, round((Total_Orders_Value / Order_Volume),2) as Avg_Order_Value from
(select c.city , count(o.oid) as Order_Volume, sum(p.price) as Total_Orders_Value
from customers as c join orders as o on c.cid = o.cid
join products as p on p.pid = o.pid
group by c.city) as dt
order by Avg_Order_Value desc; 

-- 6) Top 10 Products by Order Volume and Revenue Contribution.

with cte1 as 
(select p.pname as Product, count(o.oid) as Order_Volume, sum(p.price) as Revenue
from orders as o join products as p on p.pid = o.pid
group by Product),

cte2 as 
(select *, sum(Revenue) over () as Total_Revenue from cte1 ),

cte3 as 
(select Product, Order_Volume, Revenue,
concat(round((Revenue / Total_Revenue)*100,2),'%') as Revenue_Contribution
from cte2
)
select * from cte3 order by Revenue desc limit 10;

-- 7) Top 10 Products by Orders and Their Top Cities

with cte1 as 
(select p.pname as Product, c.City, count(oid) as Orders_Count
from customers as c join orders as o on c.cid = o.cid
join products as p on p.pid = o.pid
group by p.pname, c.city),

cte2 as 
(select *, rank() over (partition by Product order by Orders_Count desc) as Rnk
from cte1),

cte3 as 
(select Product, group_concat(City separator ',') as Top_Cities  from cte2 where Rnk=1
group by Product),

cte4 as 
(select p.pname as Product, count(oid) as Total_Orders
from products as p join orders as o on p.pid = o.pid
group by p.pname)

select cte3.Product as Product_Name, cte4.Total_Orders, cte3.Top_Cities
from cte3 join cte4 on cte3.Product = cte4.Product
order by cte4.Total_Orders desc limit 10;

-- 8) Payment Mode Share

select Payment_Mode, Transaction_Count,
concat(round((Transaction_Count / Total_Transactions)*100,2),'%') as Transaction_Share  from
(select *, sum(Transaction_Count) over () as Total_Transactions from
(select Payment_Mode , count(oid) as Transaction_Count 
from transaction
group by Payment_Mode) as dt) as dt2
order by Transaction_Count desc;

-- 9) Refund Rate by Payment Mode

with cte1 as
(select *, sum(Refund_Transactions) over () as Total_Refund_Transactions from
(select t.Payment_Mode, count(r.return_type) as Refund_Transactions
from transaction as t join refund as r on r.order_id = t.oid
where r.return_type='Refund'
group by  t.payment_mode) as dt)

select Payment_Mode,
concat(round((Refund_Transactions / Total_Refund_Transactions)*100,2),'%') as Refund_Rate 
from cte1
order by Refund_Transactions desc; 

-- 10) Product Rating Distribution (Customer Sentiment Spread).

with cte1 as
(select *, sum(Orders_Count) over () as Total_Orders from
(select concat(prod_rating,' star') as Product_Rating , count(prod_rating) as Orders_Count
from feedback
group by Product_Rating
order by Product_Rating desc) as dt)

select Product_Rating, Orders_Count,
concat(round((Orders_Count / Total_Orders)*100,2),'%') as Share
from cte1;
