-- if no start date is passed, assume it is home page and redirect to current month
SELECT
    'redirect' AS component,
    '/?t='
    || strftime('%Y-%m', current_date, 'start of month')
    || '&start='
    || date(current_date, 'start of month')
    || '&end='
    || current_date
    || '&pstart='
    || date(current_date, 'start of month', '-1 months')
    || '&pend='
    || date(current_date,  '-1 months')
    AS link
WHERE $start is null;

SELECT 'dynamic' AS component,
	sqlpage.run_sql('shell.sql')
	AS properties;


SELECT 'dynamic' AS component,
  sqlpage.run_sql('search_results.sql',
    json_object(
        't', ifnull($t, $start||' - '||$end),
        'start', $start,
        'end', ifnull($end, current_date),
        'category',ifnull($category,''),
        'exclude', ifnull($exclude,''),
        'payee', ifnull($payee, ''),
        'datagrid', ifnull($datagrid,''),
        -- this pstart and pend being null will only happen when search from the form. 
        -- in that situation, use default: pstart = start - (end-start days)
        'pstart', ifnull($pstart,
               date($start, concat('-',julianday(ifnull($end, current_date))-julianday($start),' days'))),
        'pend', ifnull($pend,date($start,  '-1 days'))
      )
  )
	AS properties;

SELECT 'dynamic' AS component,
	sqlpage.run_sql('search_form.sql')
	AS properties;
