SELECT 
	TO_CHAR(gp.hittime, 'YYYY-MM') as month
,   gs.isbounce
,	ipd.price_range  
,	coalesce(count(DISTINCT(gp.sessionid||' '||gp.item_pk)),0) as pageviews
FROM 
	(SELECT
		*
	,	CASE WHEN itemid is not NULL and itemid <> '' AND itemid <> 'dealer' and itemid <> 'null' and itemid <> '1stdibs' then itemid
			 WHEN platform = 'web' then trim(trailing '/' from SUBSTRING(webpagepath from position('/id-' in webpagepath)+4 FOR 20))
			 WHEN platform = 'app' then trim(trailing '/' from SUBSTRING(appscreenname from position('/id-' in appscreenname)+4 FOR 20))
		END AS item_pk
	from googleanalytics.ga_pageviews
	WHERE contentgroup1 = 'Products' AND contentgroup2 ~ 'PDP-Available-(Price|No Price|Net Price)'
	AND (EXTRACT(DAY FROM hittime)::integer = 01) and TO_CHAR(hittime, 'YYYY') = '2018') gp
	LEFT JOIN 
		(SELECT
			ipd1.inventory_natural_key
		,	ipd1.created_date
		,	CASE WHEN ipd2.item_price_usd is NULL THEN 'PUR'
				WHEN 	  ipd2.item_price_usd<2000 THEN '0 - 1,999'
				WHEN 	  ipd2.item_price_usd<4000 THEN '2,000 - 3,999'
				WHEN 	  ipd2.item_price_usd<6000 THEN '4,000 - 5,999'
				WHEN 	  ipd2.item_price_usd<8000 THEN '6,000 - 7,999'
				WHEN 	  ipd2.item_price_usd<10000 THEN '8,000 - 9,999'
				ELSE '10,000+' END as price_range
		FROM
			(SELECT 
				inventory_natural_key
			,	max(created_date) as created_date
			FROM history.item_price_dimension 
			WHERE pricestatus = 'active' and pricetype='retail'
			GROUP BY inventory_natural_key) ipd1		
		INNER JOIN history.item_price_dimension ipd2 on ipd2.inventory_natural_key = ipd1.inventory_natural_key and ipd2.created_date = ipd1.created_date and ipd2.pricestatus = 'active' AND ipd2.pricetype = 'retail') ipd on ipd.inventory_natural_key = gp.item_pk
INNER JOIN googleanalytics.ga_sessions gs on gp.sessionid = gs.sessionid
GROUP BY month, gs.isbounce, ipd.price_range
order BY month, gs.isbounce, ipd.price_range
--WHERE price_range is NULL
--limit 100
;


