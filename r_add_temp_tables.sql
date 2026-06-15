-- temporary table is session specific; so no collitions and is autodropped after the session is closed.
-- this reduces the query code length a lot.
-- sqlpage closes the session AFTER a request is served.
-- Quick refresh fails at create temporary table. That is because
-- connection is reused from the pool, but session is different.
-- We can safely drop if exists without impacting concurrent series
-- and proceed.
drop table if exists filtered;
create temporary table filtered AS select e.*
from expense e
WHERE date(e.dt) BETWEEN
    date($start) and date($end)
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

drop table if exists filtered_p;
create temporary table filtered_p AS select e.*
from expense e
WHERE date(e.dt) BETWEEN $pstart and $pend
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
