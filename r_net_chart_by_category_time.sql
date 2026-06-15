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
