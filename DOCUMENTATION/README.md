### PRE-REQUISITES
Raw `csv`  file is first uploaded in the postgresSQL database and cleaned.
The data is querried first to answer all the desired business questions and then imported to power BI for visualisation.

### SQL SCRIPTS
The querries are arranged into 3 scripts.
The first `.sql` script is used for staging our data. A staging table is created on it where the raw csv file is imported. It also serves as our working directory for cleaning the data.

The second `.sql` script is used for creating our production table. Having cleaned our data and removed duplicates , now we create a proper table with the right data types and constrains that will house the cleaned data from our staging table.

The last script is the analysis script for analysing our data. 

### ANALYSIS

We had 6 business questions that we analysed namely;

  1. Route analysis ( to find out which routes earn the most and their popularity)
  2. Driver Performance ( which drivers generate the most and the least income, and their ratings affecting passenger              satisfaction)
  3. Revenue Trend (This is a crucial indicator in every business set up. Analysis on how Revenue is generated over time and       the prospect of growth. It also helps the CEO make calculated decisions that will impact the future)
  4. Passenger Insights(Where do most of our passengers come from, are they satisified and also what seat class do they           prefer)
  5. Cancellations (Cancellations cost the company money, hence the need to analyse what causes such anomalies. Routes could       be the root cause of cancellations among other factos like passenger satisasction)
  6. Operational patterns ( We need to know our busiest days, peak hours for us to make calculated moves and know                 where and when to invest in our business)


### VIEWS
Now from each of those questions above , we created a separate view

Syntax:
```SQL
CREATE OR REPLACE VIEW v_clean_trips as
select column_names
from table_name;
```

To confirm if your view has been created,

Syntax:
```SQL
select * from v_clean_trips
```

 The first view we created was `v_clean_trips` which we created from our production table. We then used `v_clean_trips` to analyse all those 6 business questions above and create other 6 views from the analysis. 

Views are like temporary tables in SQL. They are not saved in our databases but we can do as much with views as Tables hence we use them to create visuals and dashboard in power BI.

### DASHBOARD
Ater creating the views , we connected our Database to power BI and imported our views.

<img width="1920" height="954" alt="Screenshot (243)" src="https://github.com/user-attachments/assets/b6e135a4-f975-4b43-9166-0bc1ae2820f0" />

We then created multiple visuals in each analysis.
Each anaysis / question had it's own page , as well  as the dashboard and the insights.

<img width="1220" height="775" alt="Screenshot (245)" src="https://github.com/user-attachments/assets/74b56aff-6af7-4420-81fd-be90b0967326" />


<img width="1218" height="801" alt="Screenshot (244)" src="https://github.com/user-attachments/assets/a62c6c6f-e5b2-4ead-8430-d16c3723099d" />


DAX measures for KPI's were derived from those views

<img width="1248" height="765" alt="Screenshot (243)" src="https://github.com/user-attachments/assets/e43736d8-c6ea-44ca-9b89-13d0b6cf49c2" />
