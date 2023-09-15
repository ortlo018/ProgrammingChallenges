create table campaign_info (
 id int not null primary key auto_increment,
 name varchar(50),
 status varchar(50),
 last_updated_date datetime
);

LOAD DATA INFILE "campaign_info.csv"
INTO TABLE campaign_info
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table website_revenue (
 date datetime,
 campaign_id varchar(50),
 state varchar(2),
 revenue float
);

LOAD DATA INFILE "website_revenue.csv"
INTO TABLE website_revenue
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table marketing_data (
 date datetime,
 campaign_id varchar(50),
 geo varchar(50),
 cost float,
 impressions float,
 clicks float,
 conversions float
);

LOAD DATA INFILE "marketing_performance.csv"
INTO TABLE marketing_data
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 1. Write a query to get the sum of impressions by day.
SELECT date_format(date, '%m/%d/%Y') AS Date, SUM(impressions) AS Total_Impressions
FROM marketing_data
GROUP BY date
ORDER BY Total_Impressions DESC;

-- 2. Write a query to get the top three revenue-generating states in order of best 
--    to worst. How much revenue did the third best state generate?
WITH state_rev AS (
SELECT state, SUM(revenue) AS Total_Revenue
FROM website_revenue
GROUP BY state
), ranked_rev AS (
SELECT state, Total_Revenue, 
RANK() OVER(ORDER BY Total_Revenue DESC) AS Rev_Rank
FROM state_rev
) SELECT state AS State, Total_Revenue, Rev_Rank
FROM ranked_rev
WHERE Rev_Rank <= 3;

-- 3. Write a query that shows total cost, impressions, clicks, and revenue of each 
--    campaign. Make sure to include the campaign name in the output.
WITH marketing_tbl AS (
SELECT campaign_id, SUM(cost) AS cost, SUM(impressions) AS impressions, 
	SUM(clicks) AS clicks
FROM marketing_data
GROUP BY campaign_id
), revenue_tbl AS (
SELECT campaign_id, state, SUM(revenue) AS revenue
FROM website_revenue
GROUP BY campaign_id
) SELECT name, ROUND(SUM(cost), 2) AS Total_Cost, SUM(impressions) AS Total_Impressions, 
	SUM(clicks) AS Total_Clicks, SUM(revenue) AS Total_Revenue
FROM marketing_tbl mt INNER JOIN campaign_info ci ON mt.campaign_id = ci.id
	INNER JOIN revenue_tbl r ON r.campaign_id = mt.campaign_id
GROUP BY name
ORDER BY name;


-- 4. Write a query to get the number of conversions of Campaign5 by state. Which 
--    state generated the most conversions for this campaign?
WITH conv AS 
(SELECT SUBSTRING_INDEX(geo, '-', -1) AS State, SUM(conversions) AS Total_Conversions
FROM marketing_data	md INNER JOIN campaign_info ci ON md.campaign_id = ci.id
WHERE name = "Campaign5"
GROUP BY State
) SELECT state, Total_Conversions, 
	RANK() OVER(ORDER BY Total_Conversions DESC) AS Conversions_Rank
FROM conv;

-- 5. In your opinion, which campaign was the most efficient, and why?
WITH marketing_tbl AS (
SELECT campaign_id, SUM(cost) AS cost, SUM(impressions) AS impressions, 
	SUM(clicks) AS clicks, COUNT(*) AS Num_Mark_Campaigns
FROM marketing_data
GROUP BY campaign_id
), revenue_tbl AS (
SELECT campaign_id, state, SUM(revenue) AS revenue, COUNT(*) AS Num_Web_Campaigns
FROM website_revenue
GROUP BY campaign_id
), informative AS
(SELECT name, ROUND(SUM(cost), 2) AS Total_Cost, SUM(impressions) AS Total_Impressions, 
	SUM(clicks) AS Total_Clicks, SUM(revenue) AS Total_Revenue
FROM marketing_tbl mt INNER JOIN campaign_info ci ON mt.campaign_id = ci.id
	INNER JOIN revenue_tbl r ON r.campaign_id = mt.campaign_id
GROUP BY name
ORDER BY name
) SELECT name, ROUND(((Total_Revenue - Total_Cost) / Total_Revenue) * 100, 2) AS Profit_Margin,
	ROUND(((Total_Revenue - Total_Cost) / Total_Cost) * 100, 2) AS ROI
FROM informative
ORDER BY Profit_Margin DESC;

-- In my opinion, Campaign 5 is the most efficient because it had the highest profit
-- margin and the highest Return on Investment

-- Bonus: Write a query that showcases the best day of the week (e.g., Sunday, 
-- Monday, Tuesday, etc.) to run ads.
WITH mark_tbl AS 
(SELECT DAYNAME(date) AS Day_of_Week, ROUND(SUM(cost), 2) AS Total_Cost, 
	SUM(impressions) AS Total_Impressions, SUM(clicks) AS Total_Clicks,
    SUM(conversions) AS Total_Conversions
FROM marketing_data
GROUP BY Day_of_Week
), web_tbl AS
(SELECT DAYNAME(date) AS Day_of_Week, SUM(revenue) AS Total_Revenue
FROM website_revenue
GROUP BY Day_of_Week
)SELECT w.Day_of_Week, Total_Revenue, Total_Cost, 
	ROUND(((Total_Revenue - Total_Cost) / Total_Revenue) * 100, 2) AS Profit_Margin,
    ROUND(((Total_Revenue - Total_Cost) / Total_Cost) * 100, 2) AS ROI
FROM web_tbl w INNER JOIN mark_tbl m ON w.Day_of_Week = m.Day_of_Week
ORDER BY Profit_Margin DESC;

-- In my opinion, Wednesday is the best day of the week for running ads because it
-- has the highest Profit_Margin and ROI.
