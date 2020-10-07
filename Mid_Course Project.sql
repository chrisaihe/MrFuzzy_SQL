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

SELECT 
    MONTH(website_sessions.created_at) AS months,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id
            ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN orders.website_session_id
            ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id
            ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.website_session_id
            ELSE NULL END) AS brand_orders
FROM
    website_sessions
        LEFT JOIN
    orders 
    ON website_sessions.website_session_id = orders.website_session_id
WHERE
	website_sessions.utm_source = 'gsearch'
	AND website_sessions.created_at < '2012-11-27'
GROUP BY 1;


/* 3. While we're on gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type?
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/

SELECT 
    MONTH(website_sessions.created_at) AS months,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id
            ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN orders.website_session_id
            ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id
            ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN orders.website_session_id
            ELSE NULL END) AS mobile_orders
FROM
    website_sessions
        LEFT JOIN
    orders 
    ON website_sessions.website_session_id = orders.website_session_id
WHERE   website_sessions.utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND website_sessions.created_at < '2012-11-27'
GROUP BY 1;


/* 4. I'm worried that one of our more pessimistic board members may be conncerned about the large % of traffic from
gsearch. Can you pull monthly trends for gsearch, alongside monthly trends for each of our other channels?
*/

-- first, finding the various utm sources and referers to see the traffic we're getting

SELECT DISTINCT
    utm_source, 
    utm_campaign, 
    http_referer
FROM    website_sessions
WHERE   created_at < '2012-11-27';

SELECT 
    -- YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS months,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id
            ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id
            ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id
            ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id
            ELSE NULL END) AS direct_type_in_sessions
FROM
    website_sessions
        LEFT JOIN
    orders 
    ON orders.website_session_id = website_sessions.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
GROUP BY 1
ORDER BY 1 ASC;

/* 5. I'd like to tell the story of our website performcance improvements over the course of the first 8 months.
COULD YOU PULL SESSION TO ORDER CONVERSION RATES, BY MONTH?
*/

SELECT 
    MONTH(website_sessions.created_at) AS months,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.website_session_id) AS orders,
    (COUNT(DISTINCT orders.website_session_id) 
    / COUNT(DISTINCT website_sessions.website_session_id)) * 100 AS session_to_order_conv_rate
FROM
    website_sessions
        LEFT JOIN
    orders 
    ON orders.website_session_id = website_sessions.website_session_id
WHERE
    website_sessions.created_at < '2012-11-27'
GROUP BY 1;

/* 6. for the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 - Jul 28), and 
use nonbrand sessions and revenue since then to calculate the incremental value)
*/

-- first, look for the first pageview id for when /lander-1 was used
-- second, create a temporary table for bringing in the landing page 
-- using when /lander was first used for each session after that 
-- third, create a temporary table left joining orders to the previously 
-- created temporary table matching landing page to sessions and orders
-- fourth, get the conversion rate for each landing page
-- fifth, find the last session for when /home was visited 
-- sixth, count the number of sessions since /lander-1 began been used 
-- use the figure in sixth to multiply the difference in conv rate to get how many extra orders lander has generated

-- firstly, look for the first pageview id for when /lander-1 was used
SELECT 
    MIN(website_pageview_id) AS first_test_pv
FROM
    website_pageviews
WHERE
    pageview_url = '/lander-1';

-- for this step, we'll find the first pageview id

-- secondly, create a temporary table for bringing in the landing page 
-- using when /lander was first used for each session after that 

create temporary table first_test_pvs_w_landing_page;
SELECT 
    website_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM
    website_pageviews
        INNER JOIN
    website_sessions ON website_sessions.website_session_id = website_pageviews.website_session_id
        AND website_sessions.created_at < '2012-07-28'
        AND website_pageviews.website_pageview_id >= 23504
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
       -- AND website_pageviews.pageview_url IN ('/home' , '/lander-1')
GROUP BY website_pageviews.website_session_id;

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
SELECT 
    first_test_pvs_w_landing_page.website_session_id,
    first_test_pvs_w_landing_page.landing_page,
    orders.order_id AS order_id
FROM
    first_test_pvs_w_landing_page
        LEFT JOIN
    orders ON orders.website_session_id = first_test_pvs_w_landing_page.website_session_id;

-- to find the difference between conversion rates

-- fourthly, get the conversion rate for each landing page
SELECT 
    landing_page,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS conv_rate
FROM
    nonbrand_test_sessions_w_orders
GROUP BY 1;

-- .0319 for /home vs. .0406 for /lander-1
-- .0087 additional orders per session

-- finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
-- fifth, find the last session for when /home was visited 

SELECT 
    MAX(website_sessions.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM
    website_sessions
        LEFT JOIN
    website_pageviews ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE
    utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND pageview_url = '/home'
        AND website_sessions.created_at < '2012-11-27';
 
-- max website_session_id = 17145 => last session where home pageview was visited
-- sixth, count the number of sessions since /lander-1 began been used 

SELECT 
    COUNT(website_session_id) AS sessions_since_test
FROM
    website_sessions
WHERE
    created_at < '2012-11-27'
        AND website_session_id > 17145
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand';


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

SELECT 
        website_pageviews.pageview_url,
            website_sessions.website_session_id,
            CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
            CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
            CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
            CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
            CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
            CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
            CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
            CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
    FROM
        website_sessions
    INNER JOIN 
		website_pageviews 
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE
        website_sessions.created_at > '2012-06-19'
            AND website_sessions.created_at < '2012-07-28'
            AND utm_source = 'gsearch'
            AND utm_campaign = 'nonbrand';


SELECT 
    website_session_id,
    MAX(homepage) AS saw_homepage,
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM
    (SELECT 
        website_pageviews.pageview_url,
            website_sessions.website_session_id,
            CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
            CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
            CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
            CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
            CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
            CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
            CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
            CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
    FROM
        website_sessions
    INNER JOIN 
		website_pageviews 
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE
        website_sessions.created_at > '2012-06-19'
            AND website_sessions.created_at < '2012-07-28'
            AND utm_source = 'gsearch'
            AND utm_campaign = 'nonbrand') AS page_flags
GROUP BY 1;

-- create a temporary table with the query above

create temporary table sessions_level_made_it_flagged;
SELECT 
    website_session_id,
    MAX(homepage) AS saw_homepage,
    MAX(custom_lander) AS saw_custom_lander,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM
    (SELECT 
        website_pageviews.pageview_url,
            website_sessions.website_session_id,
            CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
            CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
            CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
            CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
            CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
            CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
            CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
            CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
    FROM
        website_sessions
    INNER JOIN 
		website_pageviews 
    ON website_sessions.website_session_id = website_pageviews.website_session_id
    WHERE
        website_sessions.created_at > '2012-06-19'
            AND website_sessions.created_at < '2012-07-28'
            AND utm_source = 'gsearch'
            AND utm_campaign = 'nonbrand') AS page_flags
GROUP BY 1;

-- create a column wt this query pivoting the lander and home pages
-- using 'case when' to create the column

SELECT 
    CASE
        WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic'
    END AS segment,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM
    sessions_level_made_it_flagged
GROUP BY 1;

-- get the click rate for each pageview url

SELECT 
    CASE
        WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic'
    END AS segment,
    COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT website_session_id) AS lander_click_rt,
    
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) 
    / COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM
    sessions_level_made_it_flagged
GROUP BY 1;



/* 8. I'd love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the 
test (Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions
for the past month to understand monthly impact. 
*/

SELECT 
    billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd) / COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM
    (SELECT 
        website_pageviews.website_session_id,
            website_pageviews.pageview_url AS billing_version_seen,
            orders.order_id,
            orders.price_usd
    FROM
        website_pageviews
    LEFT JOIN orders ON orders.website_session_id = website_pageviews.website_session_id
    WHERE
        website_pageviews.created_at > '2012-09-10'
            AND website_pageviews.created_at < '2012-11-10'
            AND website_pageviews.pageview_url IN ('/billing' , '/billing-2')) AS billing_pageviews_and_order_data
GROUP BY 1;

-- first, left join website pageviews and orders to get the sessions, pageview url, order id and price 
-- second, use a subquery to get the url, sessions and revenue(sum of price / sessions)

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- $8.51 LIFT per billing page view

SELECT 
    COUNT(website_session_id) AS billing_sessions_past_month
FROM
    website_pageviews
WHERE
    website_pageviews.pageview_url IN ('/billing' , '/billing-2')
        AND created_at BETWEEN '2012-10-27' AND '2012-11-27'

