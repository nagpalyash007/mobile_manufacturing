


---List all the states in which we have customers who have bought cellphones from 2005 till today.
			select year(t.date)year,l.State,count(c.idcustomer)cnt_cust
			from DIM_LOCATION l join 
			FACT_TRANSACTIONS t on t.IDLocation=l.IDLocation 
			join 
			DIM_CUSTOMER c on c.IDCustomer=t.IDCustomer
			where year(t.date) between '2005' and getdate()  ----to take records from 2005 to till today --
			group by year(t.date),l.State 
			order by 1 ;





---What state in the US is buying the most 'Samsung' cell phones? 
		select distinct l.state,count(l.state)cnt
		from DIM_LOCATION l
		join FACT_TRANSACTIONS t on t.IDLocation=l.IDLocation
		join DIM_MODEL m on m.IDModel=t.IDModel
		join DIM_MANUFACTURER r on r.IDManufacturer=m.IDManufacturer
		where l.Country='us' and
		r.Manufacturer_Name='samsung'
		group by l.state
;
--here we have result arizona has 18 ,california has 8 and maryland has 13,thus arizona has highest number of samsung phone
--sold 











---Show the number of transactions for each model per zip code per state.      
		select l.zipcode,l.State,t.idmodel ,count(idmodel	)count_
		from FACT_TRANSACTIONS t join 
		DIM_LOCATION l on l.IDLocation=t.IDLocation
		group  by t.IDModel,l.ZipCode,l.State
		order by l.State asc,l.ZipCode desc;











---Show the cheapest cellphone (Output should contain the price also)
		select top 1 m.idmodel,r.manufacturer_name,min(t.totalprice) as price
		from dim_manufacturer r 
		join dim_model m  on m.idmanufacturer=r.idmanufacturer
		join fact_transactions t on t.idmodel=m.idmodel
		group by m.idmodel,r.manufacturer_name
		order by min(t.totalprice);


		---nokia with idmodel 112 is the cheapest of price 15.00






---. Find out the average price for each model in the top5 manufacturers in 
-----terms of sales quantity and order by average price.
			select top 5 m.idmodel,r.manufacturer_name,m.model_name,avg(t.totalprice)average_of_model,
			sum(t.quantity)quantity_sold
			from dim_manufacturer r 
			join dim_model m  on m.idmanufacturer=r.idmanufacturer
			join fact_transactions t on t.idmodel=m.idmodel
			group by r.manufacturer_name,m.idmodel,m.model_name
			order by avg(t.totalprice) desc,IDModel;













---List the names of the customers and the average amount spent in 2009, 
---where the average is higher than 500
		select c.customer_name,avg(t.totalprice)average
		from dim_customer c
		join fact_transactions t  on t.idcustomer=c.idcustomer
		where year(t.date)='2009'  
		group by c.customer_name
		having avg(t.totalprice)>500;

		----there 6 customers who spent or can say their avg spent is more than 500










---. List if there is any model that was in the top 5 in terms of quantity, 
----simultaneously in 2008, 2009 and 2010 
select  m.model_name,sum(t.quantity)sum_,year(t.date)year ,rank() over (partition by m.model_name  order by sum(t.quantity) desc)rank_
from dim_model m
join fact_transactions  t on t.idmodel=m.idmodel
where year(t.date) ='2008' 
group by  m.model_name,t.date 
intersect  --used to find any common part----
select  m.model_name,sum(t.quantity)sum_,year(t.date)year ,rank() over (partition by m.model_name  order by sum(t.quantity) desc)rank_
from dim_model m
join fact_transactions  t on t.idmodel=m.idmodel
where year(t.date) ='2009' 
group by  m.model_name,t.date 
intersect
select  m.model_name,sum(t.quantity)sum_,year(t.date)year ,rank() over (partition by m.model_name  order by sum(t.quantity) desc)rank_
from dim_model m
join fact_transactions  t on t.idmodel=m.idmodel
where year(t.date) ='2010' 
group by  m.model_name,t.date 
order by 3 desc ;
	
---conclusion no as such record found-----










. ---Show the manufacturer with the 2nd top sales in the year of 2009 and the 
   ----manufacturer with the 2nd top sales in the year of 2010. 
			select manufacturer_name,totalprice,year from (select r.manufacturer_name,t.totalprice,rank() over (order by t.totalprice desc)rank,year(date)year
			from fact_transactions t
			join dim_model m on m.idmodel=t.idmodel
			join dim_manufacturer r on r.idmanufacturer=m.idmanufacturer
			where year(date)='2009' ---or year(date) = '2010'
			)table_1
			where table_1.rank=2
			union 
			select manufacturer_name,totalprice,year from (select r.manufacturer_name,t.totalprice,rank() over (order by t.totalprice desc)rank,year(date)year
			from fact_transactions t
			join dim_model m on m.idmodel=t.idmodel
			join dim_manufacturer r on r.idmanufacturer=m.idmanufacturer
			where year(date)='2010' ---and year(date) = '2010'
			)table_2
			where table_2.rank=2

---- here we have apple and samsung sold in 2009 and 2010 respectively 














--- Show the manufacturers that sold cellphones in 2010 but did not in 2009. 
select r.manufacturer_name
from fact_transactions t
join dim_model m on m.idmodel=t.idmodel
join dim_manufacturer r on r.idmanufacturer=m.idmanufacturer
where  year(date)='2010' 
except --used for any uncommon part 
select r.manufacturer_name
from fact_transactions t
join dim_model m on m.idmodel=t.idmodel
join dim_manufacturer r on r.idmanufacturer=m.idmanufacturer
where  year(date)='2009';

---HTC is only mobile phone which is sold in 2010 but not in 2009
















---. Find top 100 customers and their average spend, average quantity by each 
----year. Also find the percentage of change in their spend.
	
	 with cust_ as (
						select customer_name,date_,sum(avgprice)avg_p,sum(avgquantity)avg_qty,
						lead(sum(avgprice)) over (order by date_ )next  ---using lead function to get next one in separate column ----
						from(select c.customer_name,year(f.date)date_,avg(f.totalprice)avgprice,avg(f.quantity)avgquantity
						from dim_customer c join
						fact_transactions f on f.idcustomer=c.idcustomer
						group by c.customer_name,year(f.date)
						 )x	
						 group by customer_name,date_
				)

 select   date_,customer_name,
 avg_p,avg_qty,next,
 abs(avg_p-next)difference,
 abs(avg_p-next)*100/avg_p as percent_change
 from cust_ 
 order by 1,2 asc
 ;
 --here we have customers avg they spent and percentage difference of their purchase
















	