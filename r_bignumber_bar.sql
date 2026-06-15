/** Show in/out/net only if both in and out are present. If not, just show the only one present */
WITH x AS (select sum(payment) as payment, sum(deposit) as deposit from filtered WHERE category <> 'Transfer')
select
    'big_number'          as component,
    4                     as columns,
    'colorfull_dashboard' as id
from x
where x.payment > 0
  and x.deposit > 0
union
select
    'big_number'          as component,
    1                     as columns,
    'colorfull_dashboard' as id
from x
where (x.payment > 0 or  x.deposit > 0)
  and not (x.payment > 0 and x.deposit > 0)
;

WITH y AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet,
         sum(iif(payment>0, 1, 0)) as cpayment, sum(iif(deposit>0, 1, 0)) as cdeposit, count(1) as cnet,
        cast(sum(payment)*100/sum(deposit) as integer) as expratio from filtered WHERE category <> 'Transfer' )
     ,yp AS (select sum(payment) as spayment, sum(deposit) as sdeposit, sum(net) as snet from filtered_p WHERE category <> 'Transfer' )
     ,yinvest AS ( select count(f.net) as cnet, sum(f.net) as snet from filtered f where f.investment = 1 having count(f.net) > 0 )
     ,ypinvest AS ( select count(f.net) as cnet, sum(f.net) as snet from filtered_p f where f.investment = 1 having count(f.net) > 0 )
select
    1 as d,
    'In ('||y.cdeposit||')' as title,
    printf('₹%,.2f',y.sdeposit) as value,
    ''       as unit,
    iif(y.sdeposit > 0, 'green', 'gray') as color,
    '' as progress_percent, '' as progress_color,
    round((y.sdeposit-yp.sdeposit)*100/yp.sdeposit, 2) as change_percent
from y, yp
where y.sdeposit > 0
union
select
    2 as d,
    'Out ('||y.cpayment||')' as title,
    printf('₹%,.2f',y.spayment) as value,
    ''       as unit,
    iif(y.spayment > 0, 'red', 'gray') as color,
    '' as progress_percent, '' as progress_color,
    round((y.spayment-yp.spayment)*100/yp.spayment, 2) as change_percent
from y, yp
where y.spayment > 0
union
select
    3 as d,
    'Net ('||y.cnet||')' as title,
    printf('₹%,.2f',y.snet) as value,
    ''       as unit,
    iif(y.snet > 0, 'cyan', 'pink') as color,
    y.expratio as progress_percent,
    case
      when y.expratio > 80 then 'danger'
      when y.expratio > 70 then 'warning'
      when y.expratio > 50 then 'yellow'
      else 'success'
    end as progress_color,
    round((y.snet-yp.snet)*100/yp.snet, 2) as change_percent
from y, yp
where y.spayment > 0 and yp.sdeposit > 0
union
select
    4 as d,
    'Invest ('||yinvest.cnet||')' as title,
    printf('₹%,.2f',yinvest.snet) as value,
    ''       as unit,
    'lime' as color,
    '' as progress_percent,
    '' as progress_color,
    round((yinvest.snet-ypinvest.snet)*100/ypinvest.snet, 2) as change_percent
from yinvest, ypinvest
;
