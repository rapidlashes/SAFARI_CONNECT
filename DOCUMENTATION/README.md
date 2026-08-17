### PRE-REQUISITES
Raw `csv`  file is first uploaded in the postgresSQL database and cleaned.
The data is querried first to answer all the desired business questions and then imported to power BI for visualisation.

### SQL SCRIPTS
The querries are arranged into 3 scripts.
The first `.sql` script is used for staging our data. A staging table is created on it where the raw csv file is imported. It also serves as our working directory for cleaning the data.

The second `.sql` script is used for creating our production table. Having cleaned our data and removed duplicates , now we create a proper table with the right data types and constrains that will house the cleaned data from our staging table.

The last script is the analysis script where querries are formed to answer the business questions of the CEO. 
Next, views are created from the analysis querries and imported to power BI for visualisation.
