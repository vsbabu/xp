
/* Commented out: Heatmap is ugly to watch and not very useful as I imagined.
 * Still, leaving it here for future reference. Ideally, the cells should be much smaller
 * to make it look good.
 */

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
