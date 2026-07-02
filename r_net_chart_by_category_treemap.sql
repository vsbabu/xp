SELECT 'chart'        AS component,
       'treemap'      AS type,
       'Split'        AS title,
       'col mx-2'        AS class,
       500            AS height,
       true           AS labels;

--  The split of series adds colors to the treemap
SELECT f.category                         AS label,
       IFNULL(c.classification, 'Others') AS series,
       Cast(Sum(f.net) / 1000 AS INTEGER) AS y
FROM   filtered f
       LEFT OUTER JOIN category_classification AS c
                    ON f.category = c.category
WHERE  f.category NOT IN ( 'Transfer', 'Reconcile', 'Salary', 'Interest' )
GROUP  BY 1, 2
ORDER  BY 1 ASC;
