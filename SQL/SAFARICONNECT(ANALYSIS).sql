set search_path to safari_connect;
CREATE OR REPLACE VIEW v_clean_trips as
SELECT *,
    TO_CHAR(departure_date, 'YYYY-MM')    AS travel_month,
    TO_CHAR(departure_date, 'Month YYYY') AS month_label,
    TO_CHAR(departure_date, 'Day')        AS day_name,
    EXTRACT(MONTH FROM departure_date)    AS month_num,
    EXTRACT(DOW FROM departure_date)      AS day_of_week,
    (fare_per_seat * seats_booked)           AS calculated_fare,
    CASE
        WHEN trip_rating BETWEEN 4 AND 5 THEN 'Satisfied'
        WHEN trip_rating = 3 THEN 'Neutral'
        WHEN trip_rating BETWEEN 1 AND 2 THEN 'Unsatisfied'
        ELSE 'No Rating'
    END AS satisfaction
FROM safari_connect.production_booking
WHERE booking_status = 'Completed';

-- Test
SELECT * FROM safari_connect.v_clean_trips;









/* Q1 : ROUTE ANALYSIS
 * Which routes earn the most? 
Which are most popular? Which is most efficient per seat sold?
Specific route codes with KES figures - A clear top route and a clear underperformer.
*/

--Most profitable route(RT001 Nairobi-Mombasa), less profitable route (RT009  Nairobi-Machakos)
with route_name as(
     select distinct route_code, route_from || ' - ' || route_to as name
     from safari_connect.v_clean_trips
),
total_revenue_per_route as(
     select route_code, 
     sum(total_fare)/sum(seats_booked) as revenue_per_seat,
     count(route_code) as popular,
     sum(seats_booked) as total_seats,
     sum(total_fare) as total_revenue
     from safari_connect.v_clean_trips
     group by route_code
)
select tr.route_code,rn.name, tr.popular, tr.total_seats, tr.total_revenue, tr.revenue_per_seat,
rank() over (order by total_revenue desc) as Most_earning_route,
rank() over (order by revenue_per_seat desc) as Most_efficient
from total_revenue_per_route tr
inner join route_name rn
on rn.route_code = tr.route_code
order by most_efficient;



--Most popular route, (RT005 Nairobi-Thika route), this means there are many bookings under this route, and hence alot of seats
with route_name as(
     select distinct route_code, route_from || ' - ' || route_to as name
     from safari_connect.v_clean_trips
),
total_revenue_per_route as(
     select route_code, 
     count(route_code) as popular,
     sum(seats_booked) as total_seats,
     sum(total_fare) as total_revenue
     from v_clean_trips
     group by route_code
)
select tr.route_code,rn.name, tr.popular, tr.total_seats, tr.total_revenue,
rank() over (order by total_revenue desc) as Most_earning_route,
rank() over (order by popular desc,total_seats desc) as Most_popular
from total_revenue_per_route tr
inner join route_name rn
on rn.route_code = tr.route_code
order by most_popular asc;










/*Q2.DRIVER PERFORMANCE
 * Does driver rating affect passenger satisfaction? (No it does not , Moses Kipchoge has the highest driver_rating  and is less likely to satisfy customers) 
 *Named drivers with revenue and rating figures. 
 *A promotion recommendation with data behind it.(Kelvin Omondi, avg_rating =4.5 ranked at number 3, also second highest revenue generator)
 */

---top 3 best drivers as per revenue generated(Issac Korir, Kelvin Omondi, Brian Kamau)
with driver_performance as(
	select driver_name, 
	AVG(driver_rating)as driver_rating,
	SUM(total_fare) as revenue_generated,
	round(avg(
	case
		when satisfaction = 'No Rating' then null
		when satisfaction = 'Satisfied' then 3
		when satisfaction = 'Unsatisfied' then 1
		when satisfaction = 'Neutral' then 2
		end ),1)
	as avg_passenger_satisfaction
	from safari_connect.v_clean_trips
	group by driver_name
)
select 
	driver_name, 
	revenue_generated,
	rank() over (order by  revenue_generated desc) as Top_Revenue_earner,
	driver_rating,
	avg_passenger_satisfaction,
	rank() over (order by driver_rating desc, revenue_generated) as Top_Rated
from driver_performance 
order by top_revenue_earner asc
limit 3;




---avg_passenger_satisfaction does not guarantee more revenue generated, you can see that below
with driver_performance as(
	select driver_name, 
	AVG(driver_rating)as driver_rating,
	SUM(total_fare) as revenue_generated,
	round(avg(
	case
		when satisfaction = 'No Rating' then null
		when satisfaction = 'Satisfied' then 3
		when satisfaction = 'Unsatisfied' then 1
		when satisfaction = 'Neutral' then 2
		end ),1)
	as avg_passenger_satisfaction
	from safari_connect.v_clean_trips
	group by driver_name
)
select 
	driver_name, 
	revenue_generated,
	rank() over (order by  revenue_generated desc) as Top_Revenue_earner,
	driver_rating,
	avg_passenger_satisfaction,
	rank() over (order by avg_passenger_satisfaction desc) as rank_passenger_satisfaction,
	rank() over (order by driver_rating desc, revenue_generated) as Top_Rated
from driver_performance 
order by rank_passenger_satisfaction asc;


--2A.Top 3 best drivers as per driver_rating
with driver_performance1 as(
	select driver_name, 
	AVG(driver_rating)as driver_rating,
	SUM(total_fare) as revenue_generated
    from safari_connect.v_clean_trips
    group by driver_name
),
driver_performance2 as (
select 
	driver_name, 
	revenue_generated,
	rank() over (order by  revenue_generated desc) as Top_Revenue_earner,
	driver_rating,
	rank() over (order by driver_rating desc) as Top_Rated
from driver_performance1 
order by Top_Rated
)
select * from driver_performance2
where top_rated <=3;







--Q3.REVENUE TRENDS
--3A. How is revenue changing month by month? 
with total_revenue as (
select
     to_date(month_label,'Month YYYY') as monthly,
     sum(total_fare) as monthly_revenue
from safari_connect.v_clean_trips
group by month_label
),
revenue_trend as(
	select 
	monthly,
	monthly_revenue,
	lag( monthly_revenue,1) over (order by monthly ) as previous_month_revenue
from total_revenue
)
select
monthly,
monthly_revenue,
previous_month_revenue,
round(100 *(monthly_revenue - previous_month_revenue)/previous_month_revenue,1) as percentage_growth
from revenue_trend 
order by monthly ;


--3B.worst 3 months
with cte_name1 as (
select month_label, sum(total_fare) as monthly_revenue
from safari_connect.v_clean_trips vct 
group by month_label
order by to_date(month_label,'Month YYYY')
),
cte_name2 as (
select *, dense_rank() over ( order by monthly_revenue asc) as revenue_rank
from cte_name1
)
select * from cte_name2
order by revenue_rank asc
limit 3;
  


--3C.best 3 months
with cte_name1 as (
select month_label, sum(total_fare) as monthly_revenue
from safari_connect.v_clean_trips vct 
group by month_label
order by to_date(month_label,'Month YYYY')
),
cte_name2 as (
select *, dense_rank() over ( order by monthly_revenue desc) as revenue_rank
from cte_name1
)
select * from cte_name2
where revenue_rank <=3 ; 


--3D.Revenue by route per month (pivot)
--Show one row per month with separate columns for the top 3 routes (RT001, RT002, RT003) using CASE WHEN + SUM.
select month_label,
sum(case when route_code = 'RT001' then total_fare else 0 end) as rt001_fare,
sum(case when route_code = 'RT002' then total_fare else 0 end) as rt002_fare,
sum(case when route_code = 'RT003' then total_fare else 0 end) as rt003_fare
from safari_connect.v_clean_trips 
group by month_label
order by to_date(month_label,'Month YYYY');








--Q4.PASSENGER INSIGHTS
--4A - Top passenger cities
--Show: passenger_city, total_bookings, total_seats, total_revenue, avg_fare. Order by total_bookings descending.
-- Only include cities with 3+ bookings.
select passenger_city, count(booking_id) as total_bookings, sum(seats_booked) as total_seats, sum(total_fare) as total_revenue, avg(total_fare) as avg_fare
from safari_connect.v_clean_trips 
group by passenger_city
order by total_bookings desc;

--4B. Gender split and seat class preference
--Show bookings and revenue broken down by passenger_gender and seat_class. 
--Use a CASE WHEN pivot to show Economy and Business as separate columns
select count(booking_id) as total_bookings,passenger_gender, SUM(total_fare) as total_revenue
from safari_connect.v_clean_trips 
group by passenger_gender;

with cte_name as (
select count(booking_id) as total_bookings,passenger_gender, SUM(total_fare) as total_revenue
from safari_connect.v_clean_trips 
group by passenger_gender
)
select cte.passenger_gender ,cte.total_revenue, cte.total_bookings,
count(case when seat_class = 'Business' then booking_id end) as business_class,
count(case when seat_class = 'Economy' then booking_id end) as economy_class
from cte_name cte
left join safari_connect.v_clean_trips vct on cte.passenger_gender = vct.passenger_gender
group by cte.passenger_gender,cte.total_revenue,cte.total_bookings;


--4C - Satisfaction breakdown (CTE)
--Using a CTE, count how many trips fall into each satisfaction category (Satisfied / Neutral / Unsatisfied / No Rating). 
--Show count and percentage of total completed trips
select count(booking_id) as total_trips, satisfaction
from safari_connect.v_clean_trips vct 
group by satisfaction;

with cte_name as (
select count(booking_id) as total_trips, satisfaction, booking_status
from safari_connect.v_clean_trips vct 
group by satisfaction,booking_status
)
select total_trips,satisfaction,booking_status ,round((total_trips/sum(total_trips) over())*100,1) as percentage
from cte_name;

--4D - Passenger quartiles by spend (NTILE)
--Using a CTE for total spend per passenger, divide passengers into 4 quartiles using NTILE(4). 
--Show: passenger_name, total_spent, quartile. Label quartile 4 as 'Top Spender'
select passenger_name,sum(total_fare) as total_revenue
from safari_connect.v_clean_trips vct 
group by passenger_name ;

with cte_name1 as (
select passenger_name,sum(total_fare) as total_revenue
from safari_connect.v_clean_trips vct 
group by passenger_name
),
cte_name2 as (
select passenger_name, total_revenue, ntile(4) over ( order by total_revenue asc) as fare_quartiles
from cte_name1
)
select * from cte_name2;
--(NOTE do not put partition by in the over() clause, it will reset the count of the quartiles for each partition 
--in our case passenger_names hence the quartile will be on on every total_revenue collected)
--treat the column total_revenue as a whole and split the values into quartiles.









select * from safari_connect.bookings;









--- Q5.CANCELLATIONS AND LOST REVENUE
--5A.Cancellation rate by route
--Show: route_code, route, total_bookings, completed, cancelled, no_show, cancellation_rate_pct.
--routes with the highest cancellation_rates/invalid booking_status(Mombasa-Mld, Nairobi-Machakos, Nairobi-Thika)
select route_code, 
sum(total_fare) as total_revenue,
count(booking_id) as total_bookings,
route_from || ' - ' || route_to as route, 
sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled, 
sum(case when booking_status =  'No Show' then 1 else 0 end ) as no_show
from safari_connect.production_booking
group by route_code,route_from,route_to;

with cte_name as (
select route_code, 
sum(total_fare) as total_revenue,
count(booking_id) as total_bookings,
route_from || ' - ' || route_to as route, 
sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled, 
sum(case when booking_status =  'No Show' then 1 else 0 end ) as no_show,
SUM(case when booking_status in ('Cancelled','No Show') then 1 else 0 end) as cancellations
from safari_connect.production_booking
group by route_code,route_from,route_to
)
select route,total_bookings,route_code,cancellations,total_revenue, (cancellations::numeric/total_bookings)*100 as cancellation_rate
from cte_name
order by cancellation_rate desc;
limit 3;


--5B.Revenue lost from the cancellations
select sum(total_fare) as lost_revenue, route_code 
from safari_connect.production_booking
where booking_status in ('Cancelled','No Show')
group by route_code;








select * from safari_connect.v_clean_trips vct;











--Q6.OPERATIONAL PATTERNS
--6A. Revenue by day of week
select
    extract(dow from departure_date)          as day_number,
    TO_CHAR(departure_date, 'Day')            AS day_name,
    COUNT(booking_id)                        AS total_bookings,
    SUM(total_fare)                         AS total_revenue,
    ROUND(AVG(total_fare), 2)          AS avg_booking_value
FROM safari_connect.v_clean_trips
GROUP BY  TO_CHAR(departure_date, 'Day'), extract(dow from departure_date) 
ORDER BY extract(dow from departure_date);

--6B.Busiest departure times
--Group by departure_time. Show which time slots carry the most passengers and generate the most revenue. And
--when (time) should we add more vehicles? (Def at 9am in the morning when most seats have been booked, and also
--at 7pm in the evening when there is the highest total_revenue recorded)
select sum(total_fare) as total_revenue, sum(seats_booked) as total_passengers, departure_time
from safari_connect.v_clean_trips vct 
group by departure_time;

with cte_name as (
select sum(total_fare) as total_revenue, sum(seats_booked) as total_passengers, departure_time
from safari_connect.v_clean_trips vct 
group by departure_time
)
select total_revenue, total_passengers, departure_time
from cte_name
order by total_passengers desc ;

--6C.when (which days of the week) ,should we add more vehicles? 
--(on Tuesdays when there are the most bookings and on mondays when total_revenue is collected them most)
with cte_name as (select
    extract(dow from departure_date)          as day_number,
    TO_CHAR(departure_date, 'Day')            AS day_name,
    COUNT(booking_id)                        AS total_bookings,
    SUM(total_fare)                         AS total_revenue,
    ROUND(AVG(total_fare), 2)          AS avg_booking_value
FROM safari_connect.v_clean_trips
GROUP BY  TO_CHAR(departure_date, 'Day'), extract(dow from departure_date) 
ORDER BY extract(dow from departure_date)
)
select * from cte_name
order by total_revenue desc
limit 1;

--6C - Seat utilisation by vehicle type
--Compare how full each vehicle type typically runs.
-- Show: vehicle_type, avg_seats_booked, and a label - 'High Load' if avg > 3, 'Medium Load' if 2-3, 'Low Load' if below 2.
select vehicle_type, avg(seats_booked)as booked_seats
from safari_connect.v_clean_trips vct 
group by vehicle_type ;

with cte_name as (
select vehicle_type, round(avg(seats_booked))as booked_seats
from safari_connect.v_clean_trips vct 
group by vehicle_type
)
select vehicle_type, booked_seats, 
case 
	when booked_seats > 3 then 'High Load'
	when booked_seats between 2 and 3 then 'Medium Load'
	else 'Low Load'
end as load_category
from cte_name;








--VIEWS
--DRIVER PERFORMANCE
create or replace view v_driver_performance as
with driver_performance as(
	select driver_name, 
	AVG(driver_rating)as driver_rating,
	SUM(total_fare) as revenue_generated,
	round(avg(
	case
		when satisfaction = 'No Rating' then null
		when satisfaction = 'Satisfied' then 3
		when satisfaction = 'Unsatisfied' then 1
		when satisfaction = 'Neutral' then 2
		end ),1)
	as avg_passenger_satisfaction
	from safari_connect.v_clean_trips
	group by driver_name
)
select 
	driver_name, 
	revenue_generated,
	rank() over (order by  revenue_generated desc) as Top_Revenue_earner,
	driver_rating,
	avg_passenger_satisfaction,
	rank() over (order by avg_passenger_satisfaction desc) as rank_passenger_satisfaction,
	rank() over (order by driver_rating desc, revenue_generated) as Top_Rated
from driver_performance 
order by rank_passenger_satisfaction asc;
select * from v_driver_performance;





--ROUTE ANALYSIS
create or replace view v_route_popularity as
with route_name as(
     select distinct route_code, route_from || ' - ' || route_to as name
     from safari_connect.v_clean_trips
),
total_revenue_per_route as(
     select route_code, 
     sum(total_fare)/sum(seats_booked) as revenue_per_seat,
     count(route_code) as popular,
     sum(seats_booked) as total_seats,
     sum(total_fare) as total_revenue
     from safari_connect.v_clean_trips
     group by route_code
)
select tr.route_code,rn.name, tr.popular, tr.total_seats, tr.total_revenue, tr.revenue_per_seat,
rank() over (order by total_revenue desc) as Most_earning_route,
rank() over (order by revenue_per_seat desc) as Most_efficient
from total_revenue_per_route tr
inner join route_name rn
on rn.route_code = tr.route_code
order by most_efficient;
select * from v_route_popularity;







--CANCELLATION
create or replace view v_cancellation_rates as
with cte_name as (
select route_code, 
sum(total_fare) as total_revenue,
count(booking_id) as total_bookings,
route_from || ' - ' || route_to as route, 
sum(case when booking_status = 'Completed' then 1 else 0 end) as completed,
sum(case when booking_status = 'Cancelled' then 1 else 0 end) as cancelled, 
sum(case when booking_status =  'No Show' then 1 else 0 end ) as no_show,
SUM(case when booking_status in ('Cancelled','No Show') then 1 else 0 end) as cancellations
from safari_connect.production_booking
group by route_code,route_from,route_to
)
select route,total_bookings,route_code,cancellations,total_revenue, (cancellations::numeric/total_bookings)*100 as cancellation_rate
from cte_name
order by cancellation_rate desc;
select * from v_cancellation_rates;



set search_path to safari_connect;




--PEAK TIMES
create or replace view v_peak_times as
with cte_name as (
select sum(total_fare) as total_revenue, sum(seats_booked) as total_passengers, departure_time
from safari_connect.v_clean_trips vct 
group by departure_time
)
select total_revenue, total_passengers, departure_time
from cte_name
order by total_passengers desc;
select * from v_peak_times;






--PEAK DAYS
create or replace view v_peak_days as
with cte_name as (select
    extract(dow from departure_date)          as day_number,
    TO_CHAR(departure_date, 'Day')            AS day_name,
    COUNT(booking_id)                        AS total_bookings,
    SUM(total_fare)                         AS total_revenue,
    ROUND(AVG(total_fare), 2)          AS avg_booking_value
FROM safari_connect.v_clean_trips
GROUP BY  TO_CHAR(departure_date, 'Day'), extract(dow from departure_date) 
ORDER BY extract(dow from departure_date)
)
select * from cte_name;
select * from v_peak_days;







--PASSENGER INSIGHTS
create or replace view v_passenger_insights as
with cte_name as (
select count(booking_id) as total_bookings,passenger_name, SUM(total_fare) as total_revenue
from safari_connect.v_clean_trips 
group by passenger_name
)
select cte.passenger_name ,cte.total_revenue, cte.total_bookings,
count(case when seat_class = 'Business' then booking_id end) as business_class,
count(case when seat_class = 'Economy' then booking_id end) as economy_class
from cte_name cte
left join safari_connect.v_clean_trips vct on cte.passenger_name = vct.passenger_name
group by cte.passenger_name,cte.total_revenue,cte.total_bookings;
select * from safari_connect.v_passenger_insights;







--REVENUE TREND
create or replace view v_revenue_trend as
with total_revenue as (
select
     to_date(month_label,'Month YYYY') as monthly,
     sum(total_fare) as monthly_revenue
from safari_connect.v_clean_trips
group by month_label
),
revenue_trend as(
	select 
	monthly,
	monthly_revenue,
	lag( monthly_revenue,1) over (order by monthly ) as previous_month_revenue
from total_revenue
)
select
monthly,
monthly_revenue,
previous_month_revenue,
round(100 *(monthly_revenue - previous_month_revenue)/previous_month_revenue,1) as percentage_growth
from revenue_trend 
order by monthly ;
select * from safari_connect.v_revenue_trend;






--LOST REVENUE
create or replace view v_lost_revenue as
select sum(total_fare) as lost_revenue, route_code 
from safari_connect.production_booking
where booking_status in ('Cancelled','No Show')
group by route_code;
select * from v_lost_revenue;
