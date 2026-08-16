create schema safari_connect;
set search_path to safari_connect;
create table safari_connect.booking_staging(
booking_id TEXT,
passenger_name TEXT,
passenger_phone TEXT,
passenger_gender TEXT,
passenger_city TEXT,
route_code TEXT,
route_from TEXT,
route_to TEXT,
vehicle_plate TEXT,
vehicle_type TEXT,
driver_name TEXT,
driver_rating TEXT,
departure_date TEXT,
departure_time TEXT,
seat_class TEXT,
seats_booked TEXT,
fare_per_seat TEXT,
total_fare TEXT,
payment_method TEXT,
booking_status TEXT,
trip_rating TEXT
);







select * from safari_connect.booking_staging;
select count(*) from safari_connect.booking_staging;







--cleaning departure_dates
SELECT booking_id, departure_date FROM safari_connect.booking_staging bs 
WHERE departure_date NOT SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}';

UPDATE safari_connect.booking_staging bs 
SET departure_date = TO_DATE(departure_date,'DD/MM/YYYY')::TEXT
WHERE departure_date LIKE '%/%';

update safari_connect.booking_staging bs  
set departure_date = to_date(departure_date ,'DD-MM-YY')::TEXT
where length(departure_date)=8 and departure_date like '%-%';

update safari_connect.booking_staging bs 
set departure_date = to_date(departure_date ,'MM-DD-YYYY')::text
where length(departure_date ) = 10 and 
departure_date like '%-%' and
split_part(departure_date ,'-',2)::integer >12;



--Cleaning passenger_names
select distinct passenger_name
from safari_connect.booking_staging bs 
order by bs.passenger_name;

update safari_connect.booking_staging bs 
set passenger_name = initcap(TRIM(passenger_name))
where bs.passenger_name != initcap(TRIM(passenger_name));





--Cleaning passenger_gender
update safari_connect.booking_staging bs 
set passenger_gender = case
	when upper(trim(passenger_gender)) in ('FEMALE','F') then 'Female'
	when upper(trim(passenger_gender)) in ('MALE','M') then 'Male'
	else passenger_gender
end;




--Cleaning passenger_phone
SELECT booking_id, passenger_phone
FROM safari_connect.booking_staging
WHERE passenger_phone LIKE '+254%' OR passenger_phone LIKE '%-%';   --identifying the dashes, and contacts with '+254'

update safari_connect.booking_staging bs 
set passenger_phone =  REGEXP_REPLACE(passenger_phone,'[^0-9]','','g')
WHERE passenger_phone LIKE '%-%';    --removing dashes


select booking_id, passenger_phone,  '0' || SUBSTRING(passenger_phone,5) as phn
from safari_connect.booking_staging bs 
WHERE passenger_phone LIKE '+254%';   

update safari_connect.booking_staging bs 
set passenger_phone = '0' || SUBSTRING(passenger_phone,5)
WHERE passenger_phone LIKE '+254%';


update safari_connect.booking_staging bs
set passenger_phone = case booking_id
when 'BK0006' then '0767890123'
when 'BK0028' then '0789012345'
when 'BK0050' then '0701234567'
when 'BK0072' then '0723222333'
when 'BK0094' then '0745444555'
when 'BK0116' then '0767666777'
when 'BK0138' then '0789888999'
when 'BK0160' then '0701000111'
when 'BK0203' then '0734567890'
when 'BK0182' then '0723456789'
when 'BK0204' then '0745678901'
when 'BK0226' then '0767890123'
when 'BK0248' then '0789012345'
when 'BK0270' then '0701234567'
when 'BK0051' then '0712111222'
when 'BK0052' then '0723222333'
when 'BK0115' then '0756555666'
else passenger_phone
end;

update safari_connect.booking_staging bs 
SET passenger_phone = '0' || passenger_phone
where length(passenger_phone) = 9 and passenger_phone like '7%'; --puts a zero at the begining of every contact starting with 7 and has 9 characters







select * from safari_connect.booking_staging bs ;







--Cleaning Passenger city
update safari_connect.booking_staging bs 
set passenger_city = initcap(TRIM(passenger_city))
where passenger_city != initcap(TRIM(passenger_city));

update safari_connect.booking_staging bs 
set passenger_city = 'unknown'
where passenger_city = '' or passenger_city  is null;






--Cleaning vehicle_type
update safari_connect.booking_staging bs 
set vehicle_type = initcap(trim(vehicle_type))
where bs.vehicle_type != initcap(trim(vehicle_type));





--Cleaning driver_name
update safari_connect.booking_staging bs 
set driver_name= initcap(trim(driver_name))
where bs.driver_name != initcap(TRIM(bs.driver_name ));



 

--cleaning seat_class
update safari_connect.booking_staging bs 
set seat_class= initcap(trim(seat_class))
where seat_class != initcap(TRIM(seat_class));

UPDATE safari_connect.booking_staging bs 
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY','ECO','ECONOMY CLASS') THEN 'Economy'
    WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business'
    ELSE seat_class
END;







--Cleaning payment method
UPDATE safari_connect.booking_staging bs 
SET payment_method = CASE
    WHEN UPPER(TRIM(payment_method)) IN ('MPESA','M-PESA','M PESA') THEN 'M-Pesa'
    WHEN UPPER(TRIM(payment_method)) = 'CASH'                              THEN 'Cash'
    WHEN UPPER(TRIM(payment_method)) = 'CARD'                              THEN 'Card'
    ELSE payment_method
END;








--cleaning booking status
UPDATE safari_connect.booking_staging bs 
SET booking_status = CASE
    WHEN UPPER(TRIM(booking_status)) = 'COMPLETED'  THEN 'Completed'
    WHEN UPPER(TRIM(booking_status)) = 'CANCELLED'  THEN 'Cancelled'
    WHEN UPPER(TRIM(booking_status)) = 'NO SHOW'     THEN 'No Show'
    ELSE booking_status
END;






--Cleaning trip_rating
UPDATE safari_connect.booking_staging bs 
SET trip_rating = NULL
WHERE TRIM(trip_rating) NOT IN ('1','2','3','4','5','');






--cleaning fares
UPDATE safari_connect.booking_staging bs 
SET total_fare = REGEXP_REPLACE(total_fare,'[^0-9.]','','g')
WHERE total_fare SIMILAR TO '%[^0-9.]%';

UPDATE safari_connect.booking_staging bs 
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g')
WHERE fare_per_seat SIMILAR TO '%[^0-9.]%';

select distinct bs.fare_per_seat  from safari_connect.booking_staging bs ;








--removing negatives and duplicates
-- Delete rows with negative seats
DELETE FROM safari_connect.booking_staging 
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;

-- Remove exact duplicates (keep first ctid)
DELETE FROM safari_connect.booking_staging 
WHERE ctid NOT IN 
    (SELECT MIN(ctid) FROM safari_connect.booking_staging bs  GROUP BY booking_id);





