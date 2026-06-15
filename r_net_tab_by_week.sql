SELECT
    'table' as component
  , TRUE    as sort
  , FALSE   as search
  , TRUE    as striped_rows
  , FALSE   as striped_columns
  , TRUE    as freeze_headers
  , 'INR'   as currency
  , 'amount_table' as class;
WITH RECURSIVE
params AS (SELECT date($start) as begin_cal, date($end) as end_cal),
  bounds AS (SELECT begin_cal, end_cal,
              date(begin_cal, 'start of month') as begin_month,
              date(end_cal,'+1 month', 'start of month', '-1 day') as end_month,
              date(begin_cal, 'weekday 0', '-7 days') begin_sun,
              date(end_cal, 'weekday 6') end_sat
  FROM params),
  categories AS (SELECT distinct x.category AS category FROM params p, filtered x
            WHERE date(x.dt) BETWEEN p.begin_cal AND p.end_cal
            AND x.category <> 'Transfer' ORDER BY 1),
  weeks AS ( -- weeks can be used if needed
    SELECT strftime('%Y-%U', begin_sun) as week, begin_sun dt
    FROM bounds
     UNION ALL
    SELECT
        strftime('%Y-%U', date(dt, '+7 day')) as week,
        date(dt, '+7 day') dt
  FROM bounds, weeks where  dt < date(bounds.end_sat, '-8 days')
  ),
  months AS (
      SELECT strftime('%Y-%m', begin_month) as month, begin_month dt
      FROM bounds
       UNION ALL
      SELECT
          strftime('%Y-%m', date(dt, '+1 month')) as month,
          date(dt, '+1 month') dt
    FROM bounds, months where  dt < date(bounds.end_cal, 'start of month')
    ),
  metricw AS (
      SELECT
          weeks.week, weeks.dt, categories.category,
          (select coalesce(sum(x.net), 0) from filtered x where strftime('%Y-%U', date(x.dt))=weeks.week and x.category=categories.category) as val
      FROM weeks CROSS JOIN categories
      WHERE (julianday($end) - julianday($start)) < 60 -- optimization to ignore this costly query
      ORDER BY weeks.week, categories.category
  ),
  metricm AS (
      SELECT
          months.month, months.dt, categories.category,
          (select coalesce(sum(x.net), 0) from filtered x where strftime('%Y-%m', date(x.dt, 'start of month'))=months.month and x.category=categories.category) as val
      FROM months CROSS JOIN categories
      WHERE (julianday($end) - julianday($start)) > 60 -- optimization to ignore this costly query
      ORDER BY months.month, categories.category
  )
  SELECT 'dynamic' AS component,
    JSON_PATCH(
      JSON_OBJECT('month', month),
      JSON_PATCH(
        JSON_GROUP_OBJECT(category, printf('₹%,.0f',val)),
        JSON_OBJECT('_sqlpage_color', if(sum(val)>=0, 'teal','orange')))
      ) AS properties from metricm
  GROUP BY month
    HAVING  (julianday($end) - julianday($start)) > 60 -- To hide row completely
  UNION
  SELECT 'dynamic' AS component,
    JSON_PATCH(
      JSON_OBJECT('month', 'Total'),
      JSON_PATCH(
        JSON_GROUP_OBJECT(category, printf('₹%,.0f',val)),
        JSON_OBJECT('_sqlpage_color', if(sum(val)>=0, 'teal','orange')))
      ) AS properties FROM (select category, sum(val) as val from metricm group by category)
    GROUP BY component HAVING (julianday($end) - julianday($start)) > 60 -- To hide row completely
  UNION
  SELECT 'dynamic' AS component,
    JSON_PATCH(
      JSON_OBJECT('week', dt),
       JSON_PATCH(
        JSON_GROUP_OBJECT(category, printf('₹%,.0f',val)),
        JSON_OBJECT('_sqlpage_color', if(sum(val)>=0, 'teal','orange')))
      ) AS properties from metricw
  GROUP BY week
    HAVING (julianday($end) - julianday($start)) < 60 -- To hide row completely
    UNION
    SELECT 'dynamic' AS component,
      JSON_PATCH(
        JSON_OBJECT('week', 'Total'),
        JSON_PATCH(
          JSON_GROUP_OBJECT(category, printf('₹%,.0f',val)),
          JSON_OBJECT('_sqlpage_color', if(sum(val)>=0, 'teal','orange')))
        ) AS properties FROM (select category, sum(val) as val from metricw group by category)
    GROUP BY component HAVING (julianday($end) - julianday($start)) < 60 -- To hide row completely
;

select
    'divider' as component,
    'By Weekday'   as contents,
    TRUE  as bold;

SELECT
    'table' as component
  , TRUE    as sort
  , FALSE   as search
  , TRUE    as striped_rows
  , TRUE    as freeze_headers
  , 'INR'   as currency
  , 'amount_table' as class
;
WITH RECURSIVE
params AS (SELECT date($start) as begin_cal, date($end) as end_cal),
  bounds AS (SELECT begin_cal, end_cal,
              date(begin_cal, 'weekday 0', '-7 days') begin_sun,
              date(end_cal, 'weekday 6') end_sat FROM params),
  all_dates AS (
    SELECT strftime('%Y-%U', begin_sun) as week, begin_sun dt
    FROM bounds
     UNION ALL
    SELECT
        strftime('%Y-%U', date(dt, '+1 day')) as week,
        date(dt, '+1 day') dt
  FROM bounds, all_dates where  dt < bounds.end_sat
  ),
  metric AS (
    /* THIS IS YOUR CTE FOR GETTING METRICS */
    SELECT
    date(x.dt) AS dt, sum(x.net) as val FROM params p, filtered x
    WHERE date(x.dt) BETWEEN p.begin_cal AND p.end_cal
      and x.category <> 'Transfer'
    GROUP BY x.dt
  ),
  all_dates_metric AS (
    SELECT ad.week, ad.dt, m.val, iif(m.val is null, null, printf('₹%,.0f', m.val)) as sval from all_dates ad LEFT JOIN metric  m
    ON ad.dt = m.dt
  )
  SELECT min(adm.dt) as week, printf('₹%,.0f',sum(adm.val)) as total
    -- this max is just to pick one value out of join; and all values will be same - one can use min too.
  , max(iif('0'=strftime('%w',adm.dt), adm.sval, null)) sun
  , max(iif('1'=strftime('%w',adm.dt), adm.sval, null)) mon
  , max(iif('2'=strftime('%w',adm.dt), adm.sval, null)) tue
  , max(iif('3'=strftime('%w',adm.dt), adm.sval, null)) wed
  , max(iif('4'=strftime('%w',adm.dt), adm.sval, null)) thu
  , max(iif('5'=strftime('%w',adm.dt), adm.sval, null)) fri
  , max(iif('6'=strftime('%w',adm.dt), adm.sval, null)) sat
  , iif(sum(adm.val)>=0, 'teal', 'orange') as _sqlpage_color
FROM bounds, all_dates_metric adm
GROUP BY adm.week
;
