select 'table' as component
    , TRUE     as sort
    , TRUE     as search
    , TRUE     as freeze_headers
    , TRUE     as striped_rows
    , TRUE     as small
    , 'INR'       as currency
    , 'Date'      as monospace
    , 'Net'       as align_right
    , 'Net'       as money
    , 'Net'       as monospace
    , 'Payment'       as align_right
    , 'Payment'       as money
    , 'Payment'       as monospace
    , 'Deposit'       as align_right
    , 'Deposit'       as money
    , 'Deposit'       as monospace
    , 'account'   as monospace
    , 'payee'     as monospace
    , 'category'  as monospace
    -- printf('₹%,.0f', net) formats the Indian way. SQLPage currency formatting by default is in thousands.
    from filtered where ifnull($datagrid,'') <> '' limit 1
;

select dt as 'Date'
  , account
  , payee
  , category
  , payment
  , deposit
  , net
  -- Change accounts as per your data
  , iif(investment=1, 'lime', iif(net>=0, 'teal', 'orange')) as _sqlpage_color
from filtered where ifnull($datagrid,'') <> ''
;
with totals as (
  -- wrapping this in a CTE because this will always return a row
  -- using CTE outside with another where class will suppress that row
  -- when not needed.
  select 'Total' as 'Date'
    , '' as account
    , '' as payee
    , '' as category
    , sum(payment) as payment
    , sum(deposit) as deposit
    , sum(net) as net
    , TRUE      as _sqlpage_footer
    , iif(sum(iif(net>0, net, 0))>0, 'green', 'red') as _sqlpage_color
  from filtered where ifnull($datagrid,'') <> ''
    and category <> 'Transfer' -- transfer bloats  pay/deposit columns on sum
),
investments as (
  select 'Investments' as 'Date'
    , '' as account
    , '' as payee
    , '' as category
    , sum(payment) as payment
    , sum(deposit) as deposit
    , sum(net) as net
    , TRUE      as _sqlpage_footer
    , iif(sum(iif(net>0, net, 0))>0, 'lime', 'pink') as _sqlpage_color
  from filtered where ifnull($datagrid,'') <> ''
                  and investment = 1
)
select * from totals where ifnull($datagrid,'') <> ''
union
select * from investments where ifnull($datagrid,'') <> ''
