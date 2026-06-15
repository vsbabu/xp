select
    'chart'   as component,
    'treemap' as type,
    'Net(K) Split' as title,
    500 as height,
    TRUE      as labels;

-- TODO: Add a link to category filter query in values. sqlchart doesn't support this yet.
-- FIXME: Categories should've a lookup value for grouping in db instead of this CASE statement
--        The split of series adds colors to the treemap
SELECT
    category as label,
    CASE
        WHEN category IN ('Tax', 'TDS') THEN 'Government'
        WHEN category IN ('Hire', 'Fuel', 'Grocery', 'Dinner', 'Telephone', 'Medicine') THEN 'Recurring'
        WHEN category IN ('Car', 'Bike') THEN 'Vehicles'
        WHEN category IN ('School','Fun', 'Gifts', 'Clothes') THEN 'Often'
        ELSE 'Others'
    END AS series,
    cast(sum(net)/1000 as integer) AS y
FROM filtered
where category not in ('Transfer', 'Reconcile', 'Salary', 'Interest')
GROUP BY 1, 2
ORDER BY 1 asc
;
