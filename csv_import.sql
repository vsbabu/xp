SELECT 'dynamic' AS component,
	sqlpage.run_sql('shell.sql')
	AS properties;

select 
    'form'       as component,
    'CSV import' as title,
    'Load data'  as validate,
    'csv_process.sql' as action;
select 
    'expense_data_input' as name,
    'file'               as type,
    'text/csv'           as accept,
    'Expenses'           as label,
    'Upload a CSV with columns as id,dt,account,payee, category, payment, deposit,net etc.' as description,
    TRUE                 as required;


select 
    'alert'                     as component,
    'Warning'                   as title,
    'Note that about 1 min may be needed to load 10K records. Wait!' as description,
    'alert-triangle'            as icon,
    'yellow'                    as color;

select 
    'alert'                     as component,
    'Warning'                   as title,
    'EXISTING RECORDS IN THE DB WILL BE DELETED!!!' as description,
    'alert-triangle'            as icon,
    'yellow'                    as color;
