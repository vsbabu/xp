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
