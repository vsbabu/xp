-- temporary table is session specific; so no collitions and is autodropped after the session is closed.
-- this reduces the query code length a lot.
-- sqlpage closes the session AFTER a request is served. 
-- Quick refresh fails at create temporary table. That is because
-- connection is reused from the pool, but session is different.
-- We can safely drop if exists without impacting concurrent series
-- and proceed.
drop table if exists filtered;
create temporary table filtered AS select e.*,
--  NOTE: we can further reduce the query size by persisting start and end date as two new columns in the filtered table with each row
  iif($start is null, date(concat(strftime('%Y',iif(abs(strftime('%m',current_date))<=3,date(current_date,'-1 year'), current_date)),'-04-01')), date($start)) as date_range_start,
  iif($end is null, date(concat(strftime('%Y',iif(abs(strftime('%m',current_date))>3,date(current_date,'+1 year'), current_date)),'-03-31')), date($end)) as date_range_end
from expense e
WHERE date(e.dt) BETWEEN 
    iif($start is null, date(concat(strftime('%Y',iif(abs(strftime('%m',current_date))<=3,date(current_date,'-1 year'), current_date)),'-04-01')), date($start)) and
    iif($end is null, date(concat(strftime('%Y',iif(abs(strftime('%m',current_date))>3,date(current_date,'+1 year'), current_date)),'-03-31')), date($end))
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

/** Show in/out/net only if both in and out are present. If not, just show the only one present */
WITH x AS (select sum(payment) as payment, sum(deposit) as deposit from filtered WHERE category <> 'Transfer')
select
    'big_number'          as component,
    3                     as columns,
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
        cast(sum(payment)*100/sum(deposit) as integer) as expratio from filtered WHERE category <> 'Transfer')
select
    1 as d,
    'In ('||y.cdeposit||')' as title,
    printf('₹%,.2f',y.sdeposit) as value,
    ''       as unit,
    iif(y.sdeposit > 0, 'green', 'gray') as color,
    '' as progress_percent, '' as progress_color
from y
where y.sdeposit > 0
union
select
    2 as d,
    'Out ('||y.cpayment||')' as title,
    printf('₹%,.2f',y.spayment) as value,
    ''       as unit,
    iif(y.spayment > 0, 'red', 'gray') as color,
    '' as progress_percent, '' as progress_color
from y
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
    end as progress_color
from y
where y.spayment > 0 and y.sdeposit > 0
;

SELECT
  'chart' as component,
  'Net(K)' as title,
  'bar' as type,
  true as time;

WITH y AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet,
         sum(iif(payment>0, 1, 0)) as cpayment, sum(iif(deposit>0, 1, 0)) as cdeposit, count(1) as cnet from filtered WHERE category <> 'Transfer')
SELECT
    -- change to group by days if range is up to 2 months
    iif(julianday(date_range_end)-julianday(date_range_start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    cast(sum(net)/1000 as integer) AS value,
    'Net' as series
FROM filtered, y
where category <> 'Transfer' and (y.spayment >0 and y.sdeposit>0)
GROUP BY 1
union
SELECT
    iif(julianday(date_range_end)-julianday(date_range_start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    cast(sum(deposit)/1000 as integer) AS value,
    'Income' as series
FROM filtered, y
where category <> 'Transfer' and (y.sdeposit > 0)
GROUP BY 1
union
SELECT
    iif(julianday(date_range_end)-julianday(date_range_start)>60,
    strftime('%Y-%m', date(dt)),
    strftime('%Y-%m-%d', date(dt)))
  as x,
    abs(cast(sum(payment)/1000 as integer)) AS value,
    'Expense' as series
FROM filtered, y
where category <> 'Transfer' and (y.spayment > 0)
GROUP BY 1
ORDER BY 3 asc, 1 asc
;

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
    iif(julianday(date_range_end)-julianday(date_range_start)>60,
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
  , 'INR'   as currency
  ,'total'  as align_right
  ,'sun'    as align_right
  ,'mon'    as align_right
  ,'tue'    as align_right
  ,'wed'    as align_right
  ,'thu'    as align_right
  ,'fri'    as align_right
  ,'sat'    as align_right
  ,'total'  as monospace
  ,'sun'    as monospace
  ,'mon'    as monospace
  ,'tue'    as monospace
  ,'wed'    as monospace
  ,'thu'    as monospace
  ,'fri'    as monospace
  ,'sat'    as monospace
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
  SELECT adm.week, min(adm.dt) as starting, printf('₹%,.0f',sum(adm.val)) as total
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
  , iif(net>=0, 'teal', 'orange') as _sqlpage_color
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
)
select * from totals where ifnull($datagrid,'') <> ''
;
