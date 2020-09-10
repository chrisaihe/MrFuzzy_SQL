-- ASSIGNMENTS SO FAR:
-- FINDING TOP TRAFFIC SOURCES; 
-- TRAFFIC SOURCE CONVERSION; 
-- TRAFFIC SOURCE TRENDING; 
-- BID OPTIMIZATION FOR PAID TRAFFIC;
-- TRENDING W/ GRANULAR SEGMENTS
-- FINDING TOP WEBSITE PAGES
-- FINDING TOP ENTRY PAGES
-- CALCULATING BOUNCE RATES
-- ANALYZING LANDING PAGE TESTS
-- LANDING PAGE TREND ANALYSIS
-- BUILDING CONVERSION FUNNELS
-- ANALYZING CONVERSION FUNNEL TESTS

select * from website_sessions;
select * from website_pageviews;
select * from orders;

/* 1. gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders
so that we can showcase the growth there?
*/

select month(website_sessions.created_at) as months,
count(distinct website_sessions.website_session_id) as sessions, 
count(distinct orders.website_session_id) as orders,
(count(distinct orders.website_session_id) / count(distinct website_sessions.website_session_id))*100 as session_to_order_conv_rate
from website_sessions
left join 
orders
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
and website_sessions.created_at < '2012-11-27'
group by 1
;

/* 2. Next, it would be great to see a similar monthly trend for gsearch, but this time splitting out nonbrand
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell
*/

select 
month(website_sessions.created_at) as months,
count(distinct case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions,
count(distinct case when utm_campaign = 'nonbrand' then orders.website_session_id else null end) as nonbrand_orders,
count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_sessions,
count(distinct case when utm_campaign = 'brand' then orders.website_session_id else null end) as brand_orders
from website_sessions
left join 
orders
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
and website_sessions.created_at < '2012-11-27'
group by 1;


/* 3. While we're on gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/

select 
month(website_sessions.created_at) as months,
count(distinct case when device_type = 'desktop' then website_sessions.website_session_id else null end) 
as desktop_sessions,
count(distinct case when device_type = 'desktop' then orders.website_session_id else null end) 
as desktop_orders,
count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end) 
as mobile_sessions,
count(distinct case when device_type = 'mobile' then orders.website_session_id else null end) 
as mobile_orders
from website_sessions
left join 
orders
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.utm_source = 'gsearch'
and utm_campaign = 'nonbrand' 
and website_sessions.created_at < '2012-11-27'
group by 1;


/* 4. I'm worried that one of our more pessimistic board members may be conncerned about the large % of traffic from
gsearch. Can you pull monthly trends for gsearch, alongside monthly trends for each of our other channels?
*/

-- first, finding the various utm sources and referers to see the traffic we're getting

select distinct 
utm_source, utm_campaign, http_referer
from website_sessions
where created_at < '2012-11-27';

select 
-- year(website_sessions.created_at ) as yr,
month(website_sessions.created_at ) as months,
count(distinct case when utm_source = 'gsearch' then website_sessions.website_session_id else null end) as gsearch_paid_sessions,
count(distinct case when utm_source = 'bsearch' then website_sessions.website_session_id else null end) as bsearch_paid_sessions,
count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_sessions,
count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_sessions
from website_sessions
left join
orders
on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1 
order by 1 asc;

/* 5. I'd like to tell the story of our website performcance improvements over the course of the first 8 months.
COULD YOU PULL SESSION TO ORDER CONVERSION RATES, BY MONTH?
*/

select
month(website_sessions.created_at) as months,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.website_session_id) as orders,
(count(distinct orders.website_session_id) / count(distinct website_sessions.website_session_id))*100 as session_to_order_conv_rate
from website_sessions
left join
orders
on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1;

/* 6. for the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 - Jul 28), and 
use nonbrand sessions and revenue since then to calculate the incremental value)
*/

-- firstly, look for the first pageview id for when /lander-1 was used
-- secondly, create a temporary table for bringing in the landing page 
-- using when /lander was first used for each session after that 
-- thirdly, create a temporary table left joining orders to the previously 
-- created temporary table matching landing page to sessions and orders
-- fourthly, get the conversion rate for each landing page
-- fifth, find the last session for when /home was visited 
-- sixth, count the number of sessions since /lander-1 began been used 
-- use the figure in sixth to multiply the difference in conv rate to get how many extra orders lander has generated

-- firstly, look for the first pageview id for when /lander-1 was used
select min(website_pageview_id) as first_test_pv
from website_pageviews
where pageview_url = '/lander-1';

-- for this step, we'll find the first pageview id

-- secondly, create a temporary table for bringing in the landing page 
-- using when /lander was first used for each session after that 
create temporary table first_test_pvs_w_landing_page;
select
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as landing_page,
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions 
    on website_sessions.website_session_id = website_pageviews.website_session_id
    and website_sessions.created_at < '2012-07-28' -- prescribed by the assignment
    and website_pageviews.website_pageview_id >= 23504 -- first pv
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
    and website_pageviews.pageview_url in ('/home', '/lander-1')
group by 
	website_pageviews.website_session_id;

-- I personally merged the query above and below into one(above) to shorten it

-- next, we'll bring in the landing page to each session, like last time, but restricting to home or lander-1 this time

/*create temporary table nonbrand_test_sessions_w_landing_pg;
select
	first_test_pvs.website_session_id,
    website_pageviews.pageview_url as landing_page
from first_test_pvs
	left join website_pageviews
		on website_pageviews.website_pageview_id = first_test_pvs.min_pageview_id
where website_pageviews.pageview_url in ('/home', '/lander-1');
*/

-- then we make a table to bring in orders

-- thirdly, create a temporary table left joining orders to the previously 
-- created temporary table matching landing page to sessions and orders
create temporary table nonbrand_test_sessions_w_orders;
select 
	first_test_pvs_w_landing_page.website_session_id,
    first_test_pvs_w_landing_page.landing_page,
    orders.order_id as order_id
from first_test_pvs_w_landing_page
left join orders
on orders.website_session_id = first_test_pvs_w_landing_page.website_session_id;

-- to find the difference between conversion rates

-- fourthly, get the conversion rate for each landing page
select 
	landing_page,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id) / count(distinct website_session_id) as conv_rate
from nonbrand_test_sessions_w_orders
group by 1;

-- .0319 for /home vs. .0406 for /lander-1
-- .0087 additional orders per session

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
-- fifth, find the last session for when /home was visited 
select 
	max(website_sessions.website_session_id) as most_recent_gsearch_nonbrand_home_pageview
from website_sessions
	left join website_pageviews
		on website_pageviews.website_session_id = website_sessions.website_session_id
where utm_source = 'gsearch'
	and utm_campaign = 'nonbrand'
    and pageview_url = '/home'
    and website_sessions.created_at < '2012-11-27';
 
-- max website_session_id = 17145 => last session where home pageview was visited
-- sixth, count the number of sessions since /lander-1 began been used 
select 
	count(website_session_id) as sessions_since_test
from website_sessions
where created_at < '2012-11-27'
	and website_session_id > 17145 -- last /home session from whence /lander-1 begins
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand';


-- 22,972 website sessions since the test

-- * .0087 incremental conversion = (22972*.0087)202 incremental orders since 7/29
	-- roughly 4 months, so roughly 50 extra orders per month. Not bad!



/* 7. for the landing page test you analyzed previously, it would be great to show a full conversion funnel from 
each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 - Jul 28)
*/

-- STEP 1: select all pageviews for relevant sessions
-- STEP 2: identify each relevant pageview as the specific funnel step
-- STEP 3: create the session-level conversion funnel view
-- STEP 4: aggregate the data to assess funnel preformance

select website_pageviews.pageview_url, 
website_sessions.website_session_id,
case when pageview_url = '/home' then 1 else 0 end as homepage,
case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
case when pageview_url = '/products' then 1 else 0 end as products_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions inner join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-19'
and website_sessions.created_at < '2012-07-28'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand';


select 
website_session_id,
 max(homepage) as saw_homepage, max(custom_lander) as saw_custom_lander, max(products_page) as product_made_it,
max(mrfuzzy_page) as mrfuzzy_made_it, max(cart_page)as cart_made_it, max(shipping_page) as shipping_made_it, max(billing_page) as billing_made_it,
max(thankyou_page) as thankyou_made_it
from
(
select website_pageviews.pageview_url, 
website_sessions.website_session_id,
case when pageview_url = '/home' then 1 else 0 end as homepage,
case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
case when pageview_url = '/products' then 1 else 0 end as products_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions inner join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-19'
and website_sessions.created_at < '2012-07-28'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
) as page_flags
group by 1;

-- create a temporary table with the query above

create temporary table sessions_level_made_it_flagged;
select 
website_session_id,
 max(homepage) as saw_homepage, max(custom_lander) as saw_custom_lander, max(products_page) as product_made_it,
max(mrfuzzy_page) as mrfuzzy_made_it, max(cart_page)as cart_made_it, max(shipping_page) as shipping_made_it, max(billing_page) as billing_made_it,
max(thankyou_page) as thankyou_made_it
from
(
select website_pageviews.pageview_url, 
website_sessions.website_session_id,
case when pageview_url = '/home' then 1 else 0 end as homepage,
case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
case when pageview_url = '/products' then 1 else 0 end as products_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions inner join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-19'
and website_sessions.created_at < '2012-07-28'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
) as page_flags
group by 1;

-- create a column wt this query pivoting the lander and home pages
-- using 'case when' to create the column

select 
case when saw_homepage = 1 then 'saw_homepage'
	when saw_custom_lander = 1 then 'saw_custom_lander'
    else 'uh oh... check logic'
end as segment,
count(distinct website_session_id) as sessions,
count(distinct case when product_made_it = 1 then website_session_id else null end) as to_products,
count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as to_mrfuzzy,
count(distinct case when cart_made_it = 1 then website_session_id else null end) as to_cart,
count(distinct case when shipping_made_it = 1 then website_session_id else null end) as to_shipping,
count(distinct case when billing_made_it = 1 then website_session_id else null end) as to_billing,
count(distinct case when thankyou_made_it = 1 then website_session_id else null end) as to_thankyou
from sessions_level_made_it_flagged
group by 1;

-- get the click rate for each pageview url

select 
case when saw_homepage = 1 then 'saw_homepage'
	when saw_custom_lander = 1 then 'saw_custom_lander'
    else 'uh oh... check logic'
end as segment,
count(distinct case when product_made_it = 1 then website_session_id else null end) 
/ count(distinct website_session_id) as lander_click_rt,

count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) 
/ count(distinct case when product_made_it = 1 then website_session_id else null end) as products_click_rt,

count(distinct case when cart_made_it = 1 then website_session_id else null end) 
/ count(distinct case when mrfuzzy_made_it = 1 then website_session_id else null end) as mrfuzzy_click_rt,

count(distinct case when shipping_made_it = 1 then website_session_id else null end) 
/ count(distinct case when cart_made_it = 1 then website_session_id else null end) as cart_click_rt,

count(distinct case when billing_made_it = 1 then website_session_id else null end) 
/ count(distinct case when shipping_made_it = 1 then website_session_id else null end) as shipping_click_rt,

count(distinct case when thankyou_made_it = 1 then website_session_id else null end) 
/ count(distinct case when billing_made_it = 1 then website_session_id else null end) as billing_click_rt
from sessions_level_made_it_flagged
group by 1;



/* 8. I'd love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the 
test (Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions
for the past month to understand monthly impact. 
*/

select 
	billing_version_seen,
    count(distinct website_session_id) as sessions,
    sum(price_usd) / count(distinct website_session_id) as revenue_per_billing_page_seen
from (
select 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen,
    orders.order_id,
    orders.price_usd
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at > '2012-09-10' -- prescribed in assignment
	and website_pageviews.created_at < '2012-11-10' -- prescribed in assignment
    and website_pageviews.pageview_url in ('/billing', '/billing-2')
) as billing_pageviews_and_order_data
group by 1;

-- first, left join website pageviews and orders to get the sessions, pageview url, order id and price 
-- second, use a subquery to get the url, sessions and revenue(sum of price / sessions)

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- $8.51 LIFT per billing page view

select 
	count(website_session_id) as billing_sessions_past_month
from website_pageviews
where website_pageviews.pageview_url in ('/billing', '/billing-2')
	and created_at between '2012-10-27' and '2012-11-27' -- past month

-- third, count the sessions in the last month to find the value of the billing test in that period
    
-- 1,193 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: $10,160 over the past month

