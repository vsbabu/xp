select
    'chart'   as component,
    'treemap' as type,
    'Net(K) Split' as title,
    500 as height,
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
