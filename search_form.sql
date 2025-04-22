SELECT 
    'form' as component,
    'GET' as method,
    'Filter' as validate
 ;
 /* NOTE: if you add a new parameter, ensure you pass it in the shell include in index.sql for it to be available in search_results.sql */
SELECT 
    'start' as name,
    'date' as type,
    'calendar' as prefix_icon,
    'From:' as prefix,
    '' as label,
    ifnull($start, date('now', 'start of month')) as value,
    'now' as max,
    6 as width
;
SELECT 
  'end' as name,
  'date' as type,
  'To:' as prefix,
  '' as label,
  ifnull($end, date('now')) as value,
  'now' as max,
  6 as width
;


WITH c AS (
SELECT distinct(category) as category FROM expense where category <> 'Transfer' order by 1)
SELECT
    'category[]' as name,
    'Categories' as label,
    'select' as type,
    true as multiple,
    true as create_new,
    true as searchable, 7 as width,
  json_group_array(json_object(
    'label', category,
    'value', category,
    'selected', sel.value is not null
)) as options
FROM c left join json_each($category) as sel
on c.category = sel.value;

select
  'exclude' as name,
  'Exclude categories' as label,
  'checkbox' as type,
  $exclude = 1 as checked,
  1 as value,
  3 as width;

select
  'datagrid' as name,
  'Show records' as label,
  'checkbox' as type,
  $datagrid = 1 as checked,
  1 as value,
  2 as width;

/*
select
    'include'    as name,
    'Include' as label,
    'radio' as type, 2 as width,
    'yes' as value, TRUE as checked
;
select
    'include'    as name,
    'Exclude' as label,
    'radio' as type, 2 as width,
    'no' as value, FALSE as checked
    ;
*/
