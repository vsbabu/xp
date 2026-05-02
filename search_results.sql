-- temporary table is session specific; so no collitions and is autodropped after the session is closed.
-- this reduces the query code length a lot.
-- sqlpage closes the session AFTER a request is served.
-- Quick refresh fails at create temporary table. That is because
-- connection is reused from the pool, but session is different.
-- We can safely drop if exists without impacting concurrent series
-- and proceed.
drop table if exists filtered;
create temporary table filtered AS select e.*
from expense e
WHERE date(e.dt) BETWEEN
    date($start) and date($end)
  and e.category in (
    select value as category from json_each($category) where $category <> '' and ifnull($exclude,'') = ''
    union
    select distinct(category) from expense where ifnull($category,'') = ''
    union
    select distinct(x.category) from expense x where $category <> '' and ifnull($exclude, '') <> ''
                      and x.category not in (select value as category from json_each($category))
    )
    and (($payee <> '' and exists (select 1 from payees where payee match $payee and id=e.id )) or ($payee = ''))
;

drop table if exists filtered_p;
create temporary table filtered_p AS select e.*
from expense e
WHERE date(e.dt) BETWEEN $pstart and $pend
  and e.category in (
    select value as category from json_each($category) where $category <> '' and ifnull($exclude,'') = ''
    union
    select distinct(category) from expense where ifnull($category,'') = ''
    union
    select distinct(x.category) from expense x where $category <> '' and ifnull($exclude, '') <> ''
                      and x.category not in (select value as category from json_each($category))
    )
    and (($payee <> '' and exists (select 1 from payees where payee match $payee and id=e.id )) or ($payee = ''))
;

select 'title' as component,
  $t as contents;

/*
select
    'debug' as component, $start as st, $end as en, $pstart as ps, $pend as pe;
*/

/** Show in/out/net only if both in and out are present. If not, just show the only one present */
WITH x AS (select sum(payment) as payment, sum(deposit) as deposit from filtered WHERE category <> 'Transfer')
select
    'big_number'          as component,
    4                     as columns,
    'colorfull_dashboard' as id
from x
where x.payment > 0
  and x.deposit > 0
union
select
    'big_number'          as component,
    1                     as columns,
    'colorfull_dashboard' as id
from x
where (x.payment > 0 or  x.deposit > 0)
  and not (x.payment > 0 and x.deposit > 0)
;

WITH y AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet,
         sum(iif(payment>0, 1, 0)) as cpayment, sum(iif(deposit>0, 1, 0)) as cdeposit, count(1) as cnet,
        cast(sum(payment)*100/sum(deposit) as integer) as expratio from filtered WHERE category <> 'Transfer' )
     ,yp AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet from filtered_p WHERE category <> 'Transfer' )
     ,yinvest AS ( select count(f.net) as cnet, sum(f.net) as snet from filtered f where f.investment = 1 having count(f.net) > 0 )
     ,ypinvest AS ( select count(f.net) as cnet, sum(f.net) as snet from filtered_p f where f.investment = 1 having count(f.net) > 0 )
select
    1 as d,
    'In ('||y.cdeposit||')' as title,
    printf('₹%,.2f',y.sdeposit) as value,
    ''       as unit,
    iif(y.sdeposit > 0, 'green', 'gray') as color,
    '' as progress_percent, '' as progress_color,
    round((y.sdeposit-yp.sdeposit)*100/yp.sdeposit, 2) as change_percent
from y, yp
where y.sdeposit > 0
union
select
    2 as d,
    'Out ('||y.cpayment||')' as title,
    printf('₹%,.2f',y.spayment) as value,
    ''       as unit,
    iif(y.spayment > 0, 'red', 'gray') as color,
    '' as progress_percent, '' as progress_color,
    round((y.spayment-yp.spayment)*100/yp.spayment, 2) as change_percent
from y, yp
where y.spayment > 0
union
select
    3 as d,
    'Net ('||y.cnet||')' as title,
    printf('₹%,.2f',y.snet) as value,
    ''       as unit,
    iif(y.snet > 0, 'cyan', 'pink') as color,
    y.expratio as progress_percent,
    case
      when y.expratio > 80 then 'danger'
      when y.expratio > 70 then 'warning'
      when y.expratio > 50 then 'yellow'
      else 'success'
    end as progress_color,
    round((y.snet-yp.snet)*100/yp.snet, 2) as change_percent
from y, yp
where y.spayment > 0 and yp.sdeposit > 0
union
select
    4 as d,
    'Invest ('||yinvest.cnet||')' as title,
    printf('₹%,.2f',yinvest.snet) as value,
    ''       as unit,
    'lime' as color,
    '' as progress_percent,
    '' as progress_color,
    round((yinvest.snet-ypinvest.snet)*100/ypinvest.snet, 2) as change_percent
from yinvest, ypinvest
;

SELECT
  'chart' as component,
  'Net(K)' as title,
  'bar' as type,
  true as time;

WITH y AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet,
         sum(iif(payment>0, 1, 0)) as cpayment, sum(iif(deposit>0, 1, 0)) as cdeposit, count(1) as cnet from filtered WHERE category <> 'Transfer')
    -- change to group by days if range is up to 2 months
SELECT
    iif(julianday($end)-julianday($start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    cast(sum(deposit)/1000 as integer) AS value,
    '1. Income' as series
FROM filtered, y
where category <> 'Transfer' and (y.sdeposit > 0)
GROUP BY 1
union
SELECT
    iif(julianday($end)-julianday($start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    abs(cast(sum(payment)/1000 as integer)) AS value,
    '2. Expense' as series
FROM filtered, y
where category <> 'Transfer' and (y.spayment > 0)
GROUP BY 1
union
SELECT
    iif(julianday($end)-julianday($start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    cast(sum(net)/1000 as integer) AS value,
    '3. Net' as series
FROM filtered, y
where category <> 'Transfer' and (y.spayment >0 and y.sdeposit>0)
GROUP BY 1
union
SELECT
    iif(julianday($end)-julianday($start)>60,
    strftime('%Y-%m', date(f.dt)),
    strftime('%Y-%m-%d', date(f.dt)))
  as x,
    abs(cast(sum(f.net)/1000 as integer)) AS value,
    '4. Invest' as series
FROM filtered f
where f.investment = 1
GROUP BY 1
ORDER BY 3 asc, 1 asc
;

select
    'divider' as component,
    'By Category'   as contents,
    TRUE  as bold;

select
    'chart'   as component,
    'treemap' as type,
    'Net(K) Split' as title,
    TRUE      as labels;

-- TODO: Add a link to category filter query in values. sqlchart doesn't support this yet.
SELECT
    category as label,
    cast(sum(net)/1000 as integer) AS y
FROM filtered
where category not in ('Transfer', 'Reconcile', 'Salary', 'Interest')
GROUP BY 1
ORDER BY 1 asc
;

-- FIXME: This shows no category values, for 2026-Q1 on feb 26th. Future empty ranges is NOT the problem
select 'chart' as component,
    'By Category' as title,
    'bar' as type,
    'month' as xtitle,
    'spend' as ytitle,
    true as stacked,
    true as time,
    500 as height
;
select category as series,
    -- change to group by days if range is up to 2 months
    iif(julianday($end)-julianday($start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt))) as label,
  cast(sum(net)/1 as integer) as value
FROM filtered
where category <> 'Transfer'
group by 1, 2
order by  1,2 ;

SELECT
    'table' as component
  , TRUE    as sort
  , FALSE   as search
  , TRUE    as striped_rows
  , FALSE    as striped_columns
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
/* Commented out: Heatmap is ugly to watch and not very useful as I imagined.
 * Still, leaving it here for future reference. Ideally, the cells should be much smaller
 * to make it look good.
 */
/*
select
    'chart'             as component,
    ''            as title,
    'heatmap'           as type,
    'Day'        as ytitle,
    'Week'              as xtitle,
    false               as labels,
    400                 as height,
    'azure'              as color,
    'azure'              as color,
    'azure'              as color,
    'azure'              as color,
    'azure'              as color,
    'azure'              as color,
    'azure'              as color
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
    -- THIS IS YOUR CTE FOR GETTING METRICS
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
  SELECT
    case cast (strftime('%w', adm.dt) as integer)
    when 0 then 'Sun'
    when 1 then 'Mon'
    when 2 then 'Tue'
    when 3 then 'Wed'
    when 4 then 'Thu'
    when 5 then 'Fri'
    else 'Sat' end as series,
    strftime('%w',adm.dt) as ord,
    adm.week as x,
    sum(adm.val) as y
FROM bounds, all_dates_metric adm
GROUP BY 1,2,3
order by 2 desc, 3 asc
;
*/
select 'table' as component
    , TRUE     as sort
    , TRUE     as search
    , TRUE     as freeze_headers
    , TRUE     as striped_rows
    , TRUE     as small
    , 'INR'       as currency
    , 'Date'      as monospace
    , 'Net'       as align_right
    , 'Net'       as money
    , 'Net'       as monospace
    , 'Payment'       as align_right
    , 'Payment'       as money
    , 'Payment'       as monospace
    , 'Deposit'       as align_right
    , 'Deposit'       as money
    , 'Deposit'       as monospace
    , 'account'   as monospace
    , 'payee'     as monospace
    , 'category'  as monospace
    -- printf('₹%,.0f', net) formats the Indian way. SQLPage currency formatting by default is in thousands.
    from filtered where ifnull($datagrid,'') <> '' limit 1
;

select dt as 'Date'
  , account
  , payee
  , category
  , payment
  , deposit
  , net
  -- Change accounts as per your data
  , iif(investment=1, 'lime', iif(net>=0, 'teal', 'orange')) as _sqlpage_color
from filtered where ifnull($datagrid,'') <> ''
;
with totals as (
  -- wrapping this in a CTE because this will always return a row
  -- using CTE outside with another where class will suppress that row
  -- when not needed.
  select 'Total' as 'Date'
    , '' as account
    , '' as payee
    , '' as category
    , sum(payment) as payment
    , sum(deposit) as deposit
    , sum(net) as net
    , TRUE      as _sqlpage_footer
    , iif(sum(iif(net>0, net, 0))>0, 'green', 'red') as _sqlpage_color
  from filtered where ifnull($datagrid,'') <> ''
    and category <> 'Transfer' -- transfer bloats  pay/deposit columns on sum
),
investments as (
  select 'Investments' as 'Date'
    , '' as account
    , '' as payee
    , '' as category
    , sum(payment) as payment
    , sum(deposit) as deposit
    , sum(net) as net
    , TRUE      as _sqlpage_footer
    , iif(sum(iif(net>0, net, 0))>0, 'lime', 'pink') as _sqlpage_color
  from filtered where ifnull($datagrid,'') <> ''
                  and investment = 1
)
select * from totals where ifnull($datagrid,'') <> ''
union
select * from investments where ifnull($datagrid,'') <> ''
;
