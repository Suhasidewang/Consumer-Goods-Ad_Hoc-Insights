---1//

SELECT market
FROM dim_customer
WHERE customer = "atliq exclusive" AND region = "APAC"

---2//

with unique_products_2020 as 
        ( select count(distinct product_code) as uniqueproducts_2020
        from fact_sales_monthly where fiscal_year= 2020),
     unique_products_2021 as 
		(select count(distinct product_code) as uniqueproducts_2021
        from fact_sales_monthly where fiscal_year= 2021)
select * , (uniqueproducts_2021-uniqueproducts_2020)/uniqueproducts_2020 *100 as pct_chnge
          from unique_products_2020,unique_products_2021;
          
---3//

select segment, countdistinct((product_code)) as total_products
from dim_product
group by segment
order by total_products desc;

---4//

with products_2020 as 
     ( select p.segment, count(distinct(s.product_code)) as product_count_2020
       from fact_Sales_monthly s join dim_product p
       on s.product_code=p.product_code
       where fiscal_year=2020
       group by segment),
	 products_2021 as 
     ( select p.segment, count(distinct(s.product_code)) as product_count_2021
       from fact_Sales_monthly s join dim_product p
       on s.product_code=p.product_code
       where fiscal_year=2021
       group by segment)
select products_2020.segment,product_count_2020,product_count_2021 ,
       (product_count_2021-product_count_2020) as difference
from products_2021 join products_2020
on products_2021.segment=products_2020.segment
order by difference desc;

---5//

select p.product,p.product_code, m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
on p.product_code=m.product_code
where m.manufacturing_cost=( select min(manufacturing_cost) from fact_manufacturing_cost)
or m.manufacturing_cost=( select max(manufacturing_cost) from fact_manufacturing_cost);

---6//

select c.customer_code, c.customer, round(avg(d.pre_invoice_discount_pct)*100,1) as avg_discount_pct
from dim_customer c
join fact_pre_invoice_deductions d
on c.customer_code=d.customer_code
where d.fiscal_year=2021 and c.market= "India"
group by 1,2
order by avg_discount_pct desc limit 5;

---7//

select month(s.date) as month, s.fiscal_year, round(sum(g.gross_price*s.sold_quantity),2) as gross_sales_amount
from dim_customer c join fact_sales_monthly s
on c.customer_code=s.customer_code
join fact_gross_price g
on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
where c.customer="atliq exclusive"
group by 1,2;

---8//


with quarter_sales as 
     ( select sum(sold_quantity) as total_quantity_sold,
			case when month(date) in(9,10,11) then 'Q1'
		         when month(date) in (12,1,2) then 'Q2'
			     when month(date) in (3,4,5) then 'Q3'
			     when month(date) in (6,7,8) then 'Q4'
			END AS quarter
        from fact_sales_monthly
        where fiscal_year= 2020
        group by quarter)

select quarter, total_quantity_sold
from quarter_Sales
group by quarter
order by total_quantity_sold desc;

---9//

with gross_sales_mln as
                      (select c.channel ,
						   round((sum(s.sold_quantity*g.gross_price))/1000000,2) as gross_sales_million
					from dim_customer c join fact_sales_monthly s
                    on c.customer_code=s.customer_code
                    join fact_gross_price g on s.product_code=g.product_code and s.fiscal_year=g.fiscal_year
                    where s.fiscal_year= 2021
                    group by c.channel
                    order by gross_sales_million desc)
                    
select channel, gross_sales_million, (gross_sales_million/sum(gross_sales_million) over ()*100) as percentage 
from gross_sales_mln;

---10//

with products as 
     ( select p.division, p.product_code,p.product, sum(s.sold_quantity) as total_Sold_quantity,
              rank() over(partition by p.division order by sum(s.sold_quantity) desc) as rank_order
              from dim_product p
              join fact_sales_monthly s
              on p.product_code=s.product_code
              where s.fiscal_year=2021
              group by 1,2,3
              order by total_sold_quantity desc)
select * from products
where rank_order<=3;











