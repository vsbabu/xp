SELECT 'dynamic' AS component,
	sqlpage.run_sql('shell.sql')
	AS properties;


SELECT 'dynamic' AS component,
  sqlpage.run_sql('search_results.sql',
    json_object(
        't', iif($start is null,strftime('%Y-%m', 'now'), ifnull($t, $start||' - '||$end)),
        'start', ifnull($start, date('now','start of month')),
        'end', ifnull($end, current_date),
        'category',ifnull($category,''),
        'exclude', ifnull($exclude,''),
        'payee', ifnull($payee, ''),
        'datagrid', ifnull($datagrid,''),
        -- NOTE This default calculation is incorrect in many instances. That is why this is calculated in  previous_range from menu
        -- and passed from query string to index.sql to here. During custom search, these will be null and a best effort case is handled for ifnull.
        -- It will also me null for homepage landing which is current month to current date. That is the condition coded here for full previous month.
        'pstart', ifnull($pstart, date(ifnull($start, date('now','start of month')), concat('-',(julianday(ifnull($end, current_date))-julianday(ifnull($start, date('now','start of month'))))/30,' months'), 'start of month')),
        'pend', ifnull($pend,date(ifnull($start, date('now','start of month')), '-1 days'))
      )
  )
	AS properties;

SELECT 'dynamic' AS component,
	sqlpage.run_sql('search_form.sql')
	AS properties;
