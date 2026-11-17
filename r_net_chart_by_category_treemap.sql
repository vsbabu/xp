SELECT 'chart'        AS component,
       'treemap'      AS type,
       'Split'        AS title,
       'col'        AS class,
       500            AS height,
       true           AS labels;

--  The split of series adds colors to the treemap
SELECT f.category                         AS label,
       IFNULL(c.classification, 'Others') AS series,
      '/index.sql?set_filter_cookie=0&datagrid=1&exclude=' ||
        '&t='|| $t ||
        '&start='||$start ||
        '&end='||$end ||
        '&category=["'|| f.category || '"]'  ||
        '&pstart='|| $pstart ||
        '&pend='|| $pend ||
        '&payee='|| $payee  ||
        '&account='|| ifnull($account,'') 
         AS link,
       Cast(Sum(f.net) / 1000 AS INTEGER) AS y
FROM   filtered f
       LEFT OUTER JOIN category_classification AS c
                    ON f.category = c.category
WHERE  f.category NOT IN ( 'Transfer', 'Reconcile', 'Salary', 'Interest' )
GROUP  BY 1, 2, 3
ORDER  BY 1 ASC;
