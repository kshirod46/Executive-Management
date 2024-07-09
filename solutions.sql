# BEFORE WE start, SETTING gdb023 as '"set as Default  Schema"

-- task 1
-- Provide the list of markets in which customer "Atliq Exclusive" operates 
-- its business in the APAC region.
select distinct
(market),sub_zone
from dim_customer
where customer='Atliq Exclusive' and region='APAC';

-- task 2
-- What is the percentage of unique product increase in 2021 vs. 2020?
-- The final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
with 
	cte1 as
			(select count(distinct(product_code)) as unique_product_2020
				from fact_sales_monthly
				where fiscal_year=2020 
			),
	cte2 as
			(select count(distinct(product_code)) as unique_product_2021
				from fact_sales_monthly
				where fiscal_year=2021
			)
	
select * ,(((unique_product_2021-unique_product_2020)/unique_product_2020)*100) as percentage_chang1
from cte1
cross join cte2 ;

-- ------------------------------------------ OR -----------------------------------------------

select count(distinct case when fiscal_year=2020 then product_code end ) as unique_product_2020 ,
	   count(distinct case when fiscal_year=2021 then product_code end ) as unique_product_2021 ,
       
      ( ((count(distinct case when fiscal_year=2021 then product_code end)
             -count(distinct case when fiscal_year=2020 then product_code end)) /
             
		count(distinct case when fiscal_year=2020 then product_code end))* 100 ) as percentage_chang2
from fact_sales_monthly ;

-- task 3
/*Provide a report with all the unique product counts for each segment and
 sort them in descending order of product counts. The final output contains 2 fields:
-- segment
-- product_count*/
select segment,count(distinct(product)) as product_count
from dim_product
group by 1
order by 2 desc ;

-- task 4
 /* Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
    The final output contains these fields: 
	segment
    product_count_2020
	product_count_2021
    difference 
*/
select a.segment,
	   count(distinct case when b.fiscal_year=2020 then b.product_code end ) as unique_product_2020 ,
	   count(distinct case when b.fiscal_year=2021 then b.product_code end ) as unique_product_2021 ,
       
      (count(distinct case when b.fiscal_year=2021 then b.product_code end)
             -count(distinct case when b.fiscal_year=2020 then b.product_code end)) as difference
       
from dim_product as a
join fact_sales_monthly as b
on a.product_code = b.product_code


group by a.segment
order by 4 desc ;

-- task 5
/* Get the products that have the highest and lowest manufacturing costs.
   The final output should contain these fields,
   - product_code
   - product
   - manufacturing_cost*/ 

select  a.product_code,
		a.product,
		b.manufacturing_cost
         
from dim_product as a
join fact_manufacturing_cost as b
on a.product_code=b.product_code
where b.manufacturing_cost  in (
								  select max(manufacturing_cost)
								  from fact_manufacturing_cost
								  union all
								  select min(manufacturing_cost)
								  from fact_manufacturing_cost
							   ) ;
                                                             
							
-- task 6
/* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
- customer_code
- customer
- average_discount_percentage
*/
select a.customer_code,a.customer,round((avg(b.pre_invoice_discount_pct) *100),2)as average_discount_percentage
from dim_customer as a
join fact_pre_invoice_deductions as b
on a.customer_code=b.customer_code
where (b.fiscal_year=2021 and a.market='India')
group by 1,2
order by 3 desc
limit 5 ;

-- task 7
/*Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” 
for each month. 
This analysis helps to get an idea of low and high-performing months and 
take strategic decisions.
The final report contains these columns:
- Month
- Year
- Gross sales Amount
*/
select year(a.date) as sold_year,
	   month(a.date) as month,
	   monthname(a.date) as month_name,
       round(sum(a.sold_quantity * b.gross_price )/1000000 , 2) as gross_sales_in_million,
       a.fiscal_year
from fact_sales_monthly as a
join fact_gross_price as b
using (product_code,fiscal_year)

join dim_customer as c
using (customer_code)

where c.customer='Atliq Exclusive'
group by sold_year,month,month_name,fiscal_year
order by 1,2 ;

-- task 8
/* In which quarter of 2020, got the maximum total_sold_quantity?
   The final output contains these fields  
	-- sorted by the total_sold_quantity,
    -- Quarter
	-- total_sold_quantity 
*/

select quarter(date) as quarter,
	   round(sum(sold_quantity)/1000000, 3) as total_sold_quantity_in_Million
from fact_sales_monthly
where year(date)= 2020
group by quarter
order by 2 desc
limit 1 ;

-- task 9
/*  Which channel helped to bring more gross sales in the fiscal year 2021
    and the percentage of contribution? 
    The final output contains these fields,
    -- channel
	-- gross_sales_mln
    -- percentage
*/
with cte1 as (
			with cte2 as (
							select *,
								((s.sold_quantity * p.gross_price )) as total_sales
								
							from fact_sales_monthly as s
							join fact_gross_price as p
							using (product_code,fiscal_year)
						
							join dim_customer as c
							using (customer_code)
							where s.fiscal_year=2021
									) 	 
			select channel,
				   round( (sum(total_sales)/1000000), 2)  as gross_sales_mln
			from cte2       
			group by channel   )

select *,
	  round( (gross_sales_mln*100)/(select sum(gross_sales_mln) from cte1) ,2) as percentage
from cte1
order by percentage desc
# limit 1 
;

-- task 10
/* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order
*/
with cte as  (
				select p.division,
					   s.product_code,
					   p.product,
					   sum(s.sold_quantity) as total_sold_quantity,
                       dense_rank() over 
								   ( partition by p.division 
                                     order by sum(s.sold_quantity) desc 
								   ) as rank_order
				from fact_sales_monthly as s
				join dim_product as p
				on s.product_code=p.product_code
				where s.fiscal_year = 2021
				group by 1,2,3
			)
select *
from cte   
where rank_order<=3 ;        




