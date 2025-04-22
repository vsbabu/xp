SELECT 'dynamic' AS component,
	sqlpage.run_sql('shell.sql')
	AS properties;

delete from expense;
copy expense(id
  ,dt
  ,account
  ,payee
  ,category
  ,payment
  ,deposit
  ,net
  ,quarter
  ,month
  ,day
) from 'expense_data_input'
with (header true, delimiter ',', quote '"')
;

select 
    'alert'                    as component,
    'Your data is loaded!' as title,
    'analyze'                  as icon,
    'teal'                     as color,
    FALSE                       as dismissible,
    'Your file is successfully loaded. I hope - there is no error checking for this alert:) ' as description;
select 
    '/'       as link,
    'Start using it!' as title;
