
set search_path to safari_connect;

/*CREATING PRODUCTION TABLES*/
CREATE TABLE IF NOT EXISTS safari_connect.production_booking (
    booking_id        VARCHAR(10) PRIMARY KEY,
    passenger_name    VARCHAR(100),  passenger_phone  VARCHAR(15),
    passenger_gender  VARCHAR(10),   passenger_city   VARCHAR(60),
    route_code        VARCHAR(10),   route_from       VARCHAR(60),
    route_to          VARCHAR(60),   vehicle_plate    VARCHAR(15),
    vehicle_type      VARCHAR(20),   driver_name      VARCHAR(100),
    driver_rating     NUMERIC(3,1),  departure_date   DATE,
    departure_time    VARCHAR(10),   seat_class       VARCHAR(20),
    seats_booked      INTEGER,       fare_per_seat    NUMERIC(10,2),
    total_fare        NUMERIC(12,2), payment_method   VARCHAR(20),
    booking_status    VARCHAR(20),   trip_rating      INTEGER
);

INSERT INTO safari_connect.production_booking ( 
    booking_id, 
    passenger_name,
    passenger_phone,
    passenger_gender,
    passenger_city, 
    route_code, 
    route_from,
    route_to, 
    vehicle_plate,
    vehicle_type, 
    driver_name,      
    driver_rating, 
    departure_date,  
    departure_time, 
    seat_class,      
    seats_booked,
    fare_per_seat,   
    total_fare, 
    payment_method,  
    booking_status, 
    trip_rating)
SELECT
    booking_id,
    TRIM(passenger_name),
    NULLIF(TRIM(passenger_phone),''),
    passenger_gender,
    COALESCE(NULLIF(TRIM(passenger_city),''),'Unknown'),
    route_code,
    route_from,
    route_to, 
    vehicle_plate,
    INITCAP(TRIM(vehicle_type)),
    initcap(TRIM(driver_name)),
    NULLIF(REGEXP_REPLACE(driver_rating,'[^0-9.]','','g'),'')::NUMERIC,
    departure_date::DATE, 
    departure_time,
    seat_class,
    NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER,
    NULLIF(REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g'),'')::NUMERIC,
    NULLIF(REGEXP_REPLACE(total_fare,'[^0-9.]','','g'),'')::NUMERIC,
    payment_method, 
    booking_status,
    NULLIF(trip_rating,'')::INTEGER
FROM safari_connect.booking_staging
WHERE departure_date SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}'
AND NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER > 0;

-- Verify
select * from safari_connect.production_booking;
SELECT COUNT(*) FROM safari_connect.production_booking;  -- expect ~280+
SELECT DISTINCT booking_status FROM production_booking; -- exactly: Completed, Cancelled, No Show
SELECT DISTINCT seat_class FROM production_booking;     -- exactly: Economy, Business

