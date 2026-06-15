select
    'divider' as component,
    'Top 10 repeating merchants'   as contents,
    TRUE  as bold
from filtered where ifnull($payee,'') = '' limit 1; /* TODO: Why wouldn't $payee is null work? */

select 'table' as component
    , TRUE     as sort
    , FALSE    as search
    , TRUE     as freeze_headers
    , TRUE     as striped_rows
    , TRUE     as small
    , 'INR'       as currency
    , 'Net'       as align_right
    , 'Net'       as money
    , 'Net'       as monospace
    , 'Payments'       as align_right
    , 'Payments'       as monospace
    , 'payee'     as monospace
    , 'category'     as monospace
    , JSON('{"name":"history","tooltip":"Show details","link":"' || sqlpage.link('index', JSON_OBJECT(
                    'start', $start
                    ,'end', $end
                    ,'pstart', $pstart
                    ,'pend', $pend
                    ,'datagrid', 1
                    )) ||'&payee={id}","icon":"history"}') as custom_actions
   from filtered where ifnull($payee,'') = '' limit 1;
   ;

SELECT payee, GROUP_CONCAT(DISTINCT category ORDER BY category ASC) as category, COUNT(1) as Payments, SUM(net) as Net
    , iif(sum(iif(net>0, net, 0))>0, 'teal', 'orange') as _sqlpage_color
    , payee AS _sqlpage_id
FROM filtered
WHERE investment <> 1
  AND category NOT IN ('Transfer', 'Reconcile')
  AND net < 0
  AND ifnull($payee,'') = ''
GROUP BY payee
HAVING COUNT(1) > 2
ORDER BY SUM(net) asc
LIMIT 10;
