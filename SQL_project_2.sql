/* Analyzing Channel portfolio
Expanded channel portfolio*/
Select
min(date(created_at)) as week_start_date,
count(distinct website_session_id) as total_session,
count(distinct case when utm_source = 'gsearch' then website_session_id else null end)as gsearch_session,
count(distinct case when utm_source ='bsearch' then website_session_id else null end)as bsearch_session
from website_sessions
where created_at >'2012-08-22' and created_at < '2012-11-29' and utm_campaign= 'nonbrand'
group by yearweek(created_at)
/* Comparing channels*/
select utm_source,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct case when device_type ='mobile' then website_sessions.website_session_id else null end) as mobile_sessions,
count(distinct case when device_type ='mobile' then website_sessions.website_session_id else null end)/count(distinct website_sessions.website_session_id) as pct_mobile
from website_sessions
where created_at >'2012-08-22' and created_at < '2012-11-29' and utm_campaign= 'nonbrand'
group by utm_source

/* Multi channel bidding*/
 select device_type,utm_source,
 count(distinct website_sessions.website_session_id) as sessions,
 count(distinct orders.order_id) as orders,
 count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as CVR
 from website_sessions left join orders on
 website_sessions.website_session_id = orders.website_session_id
 where website_sessions.created_at >'2012-08-22' and website_sessions.created_at < '2012-09-18' and utm_campaign= 'nonbrand'
 group by 1,2
 
 /*Impact of bid changes*/
 select min(date(created_at)) as week_start_date,
 count(distinct case when utm_source ='gsearch' and device_type ='desktop'then website_session_id else null end) as g_dtop_sessions,
 count(distinct case when utm_source ='bsearch' and device_type ='desktop'then website_session_id else null end) as b_dtop_sessions,
 count(distinct case when utm_source ='bsearch' and device_type ='desktop'then website_session_id else null end)/
 count(distinct case when utm_source ='gsearch' and device_type ='desktop'then website_session_id else null end) as b_pct_of_g_dtop,
 count(distinct case when utm_source ='gsearch' and device_type ='mobile'then website_session_id else null end) as g_mobile_sessions,
 count(distinct case when utm_source ='bsearch' and device_type ='mobile'then website_session_id else null end) as b_mobile_sessions,
 count(distinct case when utm_source ='bsearch' and device_type ='mobile'then website_session_id else null end)/
 count(distinct case when utm_source ='gsearch' and device_type ='mobile'then website_session_id else null end) as b_pct_ofg_mobile
 from website_sessions
 where created_at >'2012-11-04' and created_at < '2012-12-22' and utm_campaign= 'nonbrand'
 group by yearweek(created_at)
 
/* Analyzing Business Patterns and Seasonality
Understanding seasonality*/
 select year(website_sessions.created_at) as yr,
 week(website_sessions.created_at) as wk,
 min(date(website_sessions.created_at)) as week_start,
 count(distinct website_sessions.website_session_id) as sessions,
 count(distinct orders.order_id) as orders
 from website_sessions left join orders on
 website_sessions.website_session_id= orders.website_session_id
 where  website_sessions.created_at < '2013-01-01'
 group by 1,2
/* PRODUCT SALES ANALYSIS
Sales Tends:Pull monthly trends to date for number of sales,total revenue and total margin.*/
Select min(date(created_at)) as started_month_year,
count(distinct order_id) as number_of_sales, sum(price_usd) as total_revenue, sum(price_usd-cogs_usd) as total_margin
From orders
Where created_at < '2013-01-04'
Group by year(created_at),month(created_at)
/* Pull monthly order volume,overall conversion rate,revenue per session, breakdown sales by product*/
select year(website_sessions.created_at) as yr,month(website_sessions.created_at) as mo,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.order_id) as orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as cvr,
sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session,
count(distinct case when primary_product_id = 1 then order_id else null end) as product_one_orders,
count(distinct case when primary_product_id = 2 then order_id else null end) as product_two_orders
from website_sessions left join orders on
website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at > '2012-04-01' and website_sessions.created_at <'2013-04-01'
group by 1,2
/* Analyzing Product_Level Website Pathing
STEP 1:Finding the products pageviews we care about*/
create temporary table products_pageviews
select website_session_id,website_pageview_id,created_at,
case when created_at < '2013-01-06' then 'A.Pre_Product_2'
     when created_at>= '2013-01-06' then 'B.Pre_Product_2'
     else 'check the logic' end as time_period
From website_pageviews
where created_at < '2013-04-06' and created_at > '2012-10-06' and pageview_url ='/products'  ; 

/* STEP 2:Find the next pageview id that occurs after product pageview*/
create temporary table session_w_next_pageview_id
select products_pageviews.time_period,products_pageviews.website_session_id,
 min(website_pageviews.website_pageview_id)as min_text_pageview
 from products_pageviews left join website_pageviews on 
website_pageviews.website_session_id = products_pageviews.website_session_id and 
 website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
 group by 1,2
 /* STEP 3: find the pageview_url assosiated with any applicable next pageview id*/
  create temporary table session_w_next_pageview_url
  select session_w_next_pageview_id.website_session_id,session_w_next_pageview_id.time_period,
  website_pageviews.pageview_url as next_page_url
  from session_w_next_pageview_id left join website_pageviews on
  website_pageviews.website_session_id =session_w_next_pageview_id.website_session_id
  
  /* STEP 4:Summarazing*/
  Select time_period,count(distinct website_session_id) as sessions,
  count(distinct case when next_page_url is not null then website_session_id else null end) as w_next_page,
  count(distinct case when next_page_url is not null then website_session_id else null end)/count(distinct website_session_id) as pct_w_next_page,
  count(distinct case when next_page_url ='/the-original-mr-fuzzy' then website_session_id else null end) as mr_faazzy,
  count(distinct case when next_page_url ='/the-original-mr-fuzzy' then website_session_id else null end)/count(distinct website_session_id) as pct_mr_fazzy,
  count(distinct case when next_page_url ='/the-forever-love-bear' then website_session_id else null end) as to_lovebear,
  count(distinct case when next_page_url ='/the-forever-love-bear' then website_session_id else null end)/count(distinct website_session_id) as pct_w_lovebear
  from session_w_next_pageview_url
  group by 1;
  
  /* Product Conversion Funnels
  STEP 1:Select all pageviews for relevant session*/
  create temporary table session_seing_product_pages
  select website_session_id,website_pageview_id,pageview_url as product_page_seen
  from website_pageviews
  where created_at < '2013-04-10' and created_at > '2013-01-06' and pageview_url
  in('/the-original-mr-fuzzy','/the-forever-love-bear');
  
/*finding the url to build the funnels*/
select distinct website_pageviews.pageview_url
from  session_seing_product_pages left join website_pageviews
on website_pageviews.website_session_id=session_seing_product_pages.website_session_id
and website_pageviews.website_pageview_id >session_seing_product_pages .website_pageview_id


select session_seing_product_pages.website_session_id,
session_seing_product_pages.product_page_seen,
case when pageview_url ='/cart' then 1 else 0 end as cart_page,
case when pageview_url ='/shipping' then 1 else 0 end as shipping_page,
case when pageview_url ='/billing-2' then 1 else 0 end as billing2_page,
case when pageview_url ='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from  session_seing_product_pages left join website_pageviews
on website_pageviews.website_session_id=session_seing_product_pages.website_session_id
and website_pageviews.website_pageview_id >session_seing_product_pages .website_pageview_id
order by 1,2


create temporary table session_product_level_made_it_flags
select website_session_id,
case when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
     when product_page_seen = '/the-forever-love-bear' then 'lovebear'
     else 'check logic' end as product_seen,
     max(cart_page) as cart_made_it,
     max(shipping_page) as shipping_made_it,
     max(billing2_page) as billing2_made_it,
     max(thankyou_page) as thankyou_made_it
from (select session_seing_product_pages.website_session_id,
session_seing_product_pages.product_page_seen,
case when pageview_url ='/cart' then 1 else 0 end as cart_page,
case when pageview_url ='/shipping' then 1 else 0 end as shipping_page,
case when pageview_url ='/billing-2' then 1 else 0 end as billing2_page,
case when pageview_url ='/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from  session_seing_product_pages left join website_pageviews
on website_pageviews.website_session_id=session_seing_product_pages.website_session_id
and website_pageviews.website_pageview_id >session_seing_product_pages .website_pageview_id
order by 1,2) as pageview_level
group by website_session_id,
case when product_page_seen = '/the-original-mr-fuzzy' then 'mrfuzzy'
     when product_page_seen = '/the-forever-love-bear' then 'lovebear'
     else 'check logic' end;
     
select product_seen,count(distinct website_session_id) as session,
count(distinct case when  cart_made_it = 1 then website_session_id else null end )as to_cart,
count(distinct case when  shipping_made_it = 1 then website_session_id else null end )as to_shipping,
count(distinct case when  billing2_made_it = 1 then website_session_id else null end )as to_billing2,
count(distinct case when  thankyou_made_it = 1 then website_session_id else null end )as to_thankyou
from session_product_level_made_it_flags
group by 1;

  
  