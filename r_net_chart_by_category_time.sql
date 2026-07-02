-- FIXME: This shows no category values, for 2026-Q1 on feb 26th. Future empty ranges is NOT the problem
SELECT 'chart'    AS component,
    'Progression' AS title,
    'bar'         AS type,
    'month'       AS xtitle,
    'spend'       AS ytitle,
    'col mx-2'    AS class,
    true          AS stacked,
    true          AS time,
    500           AS height;

SELECT category                           AS series,
    -- change to group by days if range is up to 2 months
    IIF(JULIANDAY($end) - JULIANDAY($start) > 60, STRFTIME('%Y-%m', DATE(dt)),
    STRFTIME('%Y-%m-%d', DATE(dt)))    AS label,
    -1 * Cast(Sum(net) / 1 AS INTEGER) AS value
    -- -1 to switch expenses positive
FROM   filtered
WHERE  category NOT IN ( 'Transfer', 'Reconcile', 'Salary', 'Interest' )
GROUP  BY 1, 2
ORDER  BY 1, 2;
