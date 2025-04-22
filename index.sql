SELECT 'dynamic' AS component,
	sqlpage.run_sql('shell.sql')
	AS properties;


SELECT 'dynamic' AS component,
  sqlpage.run_sql('search_results.sql', json_object('t', iif($start is null,strftime('%Y-%m', 'now'), ifnull($t, $start||' - '||$end)),
                                                    'start', ifnull($start, date('now','start of month')),
													'end', ifnull($end, current_date),
													'category',ifnull($category,''),
													'exclude', ifnull($exclude,''),
													'datagrid', ifnull($datagrid,''))
  )
	AS properties;

SELECT 'dynamic' AS component,
	sqlpage.run_sql('search_form.sql')
	AS properties;
