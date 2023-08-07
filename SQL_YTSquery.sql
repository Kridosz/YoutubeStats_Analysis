---Inspecting Data
select * from CleanedYTS

--Checking unique values
select distinct category from CleanedYTS -- Multiple Categories to plot
select distinct Country from CleanedYTS -- Multiple locations around the world (World Map plotting)
select distinct channel_type from CleanedYTS -- Specify term for Youtube Channel classification
select distinct created_year from CleanedYTS -- Year Stating form 1970 to 2022
select distinct created_month from CleanedYTS -- 12 months specified
select distinct Youtuber from CleanedYTS -- 552 of distinct youtubers

select distinct created_month from CleanedYTS 
where created_year = 2022



-- Analysis of Data (Grouping)

Select category, sum(highest_yearly_earnings) as Revenue -- Entertainment having the highest Revenue
from CleanedYTS
group by category
order by 2 desc

Select Country, sum(highest_yearly_earnings) as Revenue -- United States earning the highest Revenue
from CleanedYTS
group by country
order by 2 desc

Select created_year, sum(highest_yearly_earnings) as Revenue --  2006 earning the highest Revenue and lowest is 2022 (Only June Month data present)
from CleanedYTS
group by created_year
order by 2 desc

Select TOP 10 Youtuber, sum(highest_yearly_earnings) as Revenue --  Top 10 youtubers earnings
from CleanedYTS
group by Youtuber
order by 2 desc

Select Top 10 Youtuber, subscribers --  Top 10 subscribers (Tseries top)
from CleanedYTS
order by 2 desc

Select TOP 10 category, sum(video_views) as Video_View -- Music with highest views followed by top 9
from CleanedYTS
group by category
order by 2 desc

Select created_year, SUM(CAST(C_Population AS DECIMAL(38, 0))) AS Country_Population -- 2014 had the highest population count all over the world
from CleanedYTS
group by created_year
order by 2 desc

Select country, SUM(CAST(C_Population AS DECIMAL(38, 0))) AS Country_Population -- India having the highest population
from CleanedYTS
group by country
order by 2 desc

select category, SUM(CAST(C_Population AS DECIMAL(38, 0))) as Total_Subscriber -- Entertainment having highest subscribers
from CleanedYTS
group by category
order by 2 desc

-- what was the best month for sales in a specific year? how much was earned that month?

select created_month, sum(highest_yearly_earnings) as Revenue, count(uploads) as Total_Uploads, sum(video_views) as Video_viewed 
from CleanedYTS
where created_year = 2006 And country = 'United States'
group by created_month
order by 2 desc

-- in 2006 sep month earned the most revenue in United States with the 3 videos uploads and viewed by many.

select created_month, sum(highest_yearly_earnings) as Revenue, count(uploads) as Total_Uploads, sum(video_views) as Video_viewed 
from CleanedYTS
where created_year = 2006 And country = 'India'
group by created_month
order by 2 desc

-- in 2006 march month earned the most revenue in India with the 2 videos uploads and viewed by many.

--September in United States was the highest, which category was trending at that point of time??
select created_month, category, sum(highest_yearly_earnings) as Revenue, count(uploads) as Total_Uploads, sum(video_views) as Video_viewed
from CleanedYTS
where created_year = 2006 And created_month = 'Sep' and country = 'United States'
group by created_month, category
order by 3 desc

--Education and Music category in september brought the most revenue in United States.


--March in India was the highest, which category was trending at that point of time??
select created_month, category, sum(highest_yearly_earnings) as Revenue, count(uploads) as Total_Uploads, sum(video_views) as Video_viewed
from CleanedYTS
where created_year = 2006 And created_month = 'Mar' and country = 'India'
group by created_month, category
order by 3 desc

-- Music category was trending and earned the most revenue
 
--which is our best Category is? (this could be best answered by RFM Analysis)

Drop table if exists #rfm
;with rfm as
(
	select category, sum(highest_yearly_earnings) as MonetaryValue, AVG(highest_yearly_earnings) as AvgMonetaryValue, count(uploads) as Frequency, 
	max(highest_yearly_earnings) as highest_rev, (select max(highest_yearly_earnings) from CleanedYTS) as Global_High_Rev,
	(SELECT MAX(highest_yearly_earnings) FROM CleanedYTS) - MAX(highest_yearly_earnings) AS Recency
	from CleanedYTS
	group by category
),
rfm_calc as 
(
select r.*, --Bucketing (4 Buckets)
	NTILE(4) over (order by Recency desc) rfm_recency,
	NTILE(4) over (order by Frequency) rfm_frequency,
	NTILE(4) over (order by MonetaryValue) rfm_monetary
from rfm r
)
	select c.*, rfm_recency+rfm_frequency+rfm_monetary as rfm_cell, 
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cell_string-- Concating
into #rfm
from rfm_calc c

select category, rfm_recency, rfm_frequency, rfm_monetary,--segmentation
	case
		when rfm_cell_string in (111,112,113,121,122,124,131,123,132,211,212,213,114,141) then 'Lost Channels' -- Channels not trending anymore
		when rfm_cell_string in (133,134,142,143,144,214,241, 243,334,343,344) then 'Declining Channels' -- Famous channels, but losing its interest
		when rfm_cell_string in (311,411,412,331) then 'Up-and-Coming Channels' -- Channels which were newly created on Youtube
		when rfm_cell_string in (221,222,223,224,231,232,233,244,242,234,322,422) then 'Potential Channels' -- Channels which could be famous if they are steady and have amazing content
		when rfm_cell_string in (323,333,321,423,421,332,432) then 'Trending Stars' -- Channels producing popular and viral content that resonates with a wide audience.
		when rfm_cell_string in (433,434,443,444) then 'Long-Lasting Legends' -- Channels with true core content maintaining revelance and audience over the years.
	end rfm_segment
from #rfm 


--which Category do youtuber works on most?? 
--select * from CleanedYTS where channel_type = 'Entertainment'

select distinct channel_type,  stuff(

	(select ',' + Youtuber
	from CleanedYTS p
	where channel_type in 
		(
			select channel_type 
			from(
				select channel_type, count(*) row_nums
				from CleanedYTS
				where uploads > 5000 -- how many count of same channel type which have uploads over 5000
				group by channel_type
			) m
			where row_nums > 4
		)
		and p.channel_type = s.channel_type
		for xml path ('')), 1,1, '') as Youtubers--xml path 
		
from CleanedYTS s
order by 2 desc


WITH YTData AS (
    SELECT
        channel_type,
        STUFF(
            (SELECT ',' + Youtuber
             FROM CleanedYTS p
             WHERE channel_type IN
                   (SELECT channel_type
                    FROM
                       (SELECT channel_type, COUNT(*) AS row_nums
                        FROM CleanedYTS
                        WHERE uploads > 5000
                        GROUP BY channel_type) m
                    WHERE row_nums > 4)
               AND p.channel_type = s.channel_type
             FOR XML PATH ('')), 1, 1, '') AS Youtubers,
        COUNT(DISTINCT Youtuber) AS YoutuberCount
    FROM
        CleanedYTS s
    GROUP BY
        channel_type
)
SELECT *
FROM YTData
WHERE Youtubers IS NOT NULL
ORDER BY YoutuberCount DESC;














