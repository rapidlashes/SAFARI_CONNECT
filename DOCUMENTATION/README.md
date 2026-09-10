### PRE-REQUISITES
Raw `csv`  file is first uploaded in the postgresSQL database and cleaned.
The data is querried first to answer all the desired business questions and then imported to power BI for visualisation.

### SQL SCRIPTS
The querries are arranged into 3 scripts.
The first `.sql` script is used for staging our data. A staging table is created on it where the raw csv file is imported. It also serves as our working directory for cleaning the data.

The second `.sql` script is used for creating our production table. Having cleaned our data and removed duplicates , now we create a proper table with the right data types and constrains that will house the cleaned data from our staging table.

The last script is the analysis script where querries are formed to answer the business questions of the CEO. 

### VIEWS
The next part having analysed our data before visualisation is views. Now we create views from the analysis we have done.
We had 6 business questions that we analysed namely;

  1. Route analysis( to find out which routes earn the most and their popularity)
  2. Driver Performance( which drivers generate the most and the least income, and their ratings affecting passenger              satisfaction)
  3. Revenue Trend(This is a crucial indicator in every business set up. Analysis on how Revenue is generated over time and       the prospect of growth. It also helps the CEO make calculated decisions that will impact the future)
  4. Passenger Insights(Where do most of our passengers come from, are they satisified and also what seat class do they           prefer)
  5. Cancellations(Cancellations cost the company money, hence the need to analyse what causes such anomalies. Routes could       be the root cause of cancellations among other factos like passenger satisasction)
  6. Lastly , Operational patterns( We need to know our busiest days, peak hours for us to make calculated moves and know         where and when to invest in our business)

Views are like temporary tables in SQL. They are not saved in our databases but we can do as much with views as Tables hence we use them to create visuals and dashboard in power BI.

Syntax:
```SQL
CREATE OR REPLACE VIEW v_clean_trips as
select column_names
from table_name;

  
