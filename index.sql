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


-- prepare all variables
SET ctx_json  = json_object(
    'start'    , $start,
    'end'      , ifnull($end, current_date),
    't'        , ifnull($t, $start||' - '||$end), -- if no title is passed (eg: called from search), make it up

    -- this pstart and pend being null will only happen when search from the form.
    -- in that situation, use default: pstart = start - (end-start days)
    'pstart'   , ifnull($pstart, date($start, concat('-',julianday(ifnull($end, current_date))-julianday($start),' days'))),
    'pend'     , ifnull($pend,date($start,  '-1 days')),

    'category' , $category,                      -- this should be a json array; leaving as null is good
    'exclude'  , ifnull($exclude, ''),
    'payee'    , ifnull($payee, ''),
    'datagrid' , ifnull($datagrid, '')
  );

  -- draw menu
  SELECT 'dynamic' AS component, sqlpage.run_sql('shell.sql') AS properties;

-- create temp tables for the session - all query sql files below use these.
SELECT 'dynamic' AS component, sqlpage.run_sql('r_add_temp_tables.sql', $ctx_json) AS properties;

-- SELECT 'debug' as component, $ctx_json;

-- page title - need to extract populated t from ctx
SELECT 'title' as component, $ctx_json ->> '$.t' as contents;

-- different components that make up the result dashboard
SELECT 'dynamic' AS component, sqlpage.run_sql('r_bignumber_bar.sql',         $ctx_json) AS properties;
SELECT 'dynamic' AS component, sqlpage.run_sql('r_net_chart_by_time.sql',     $ctx_json) AS properties;

SELECT 'dynamic' AS component, sqlpage.run_sql('r_net_chart_by_category.sql', $ctx_json) AS properties;

SELECT 'dynamic' AS component, sqlpage.run_sql('r_net_tab_by_week.sql',       $ctx_json) AS properties;

SELECT 'dynamic' AS component, sqlpage.run_sql('r_top_n_merchants.sql',       $ctx_json) AS properties;
SELECT 'dynamic' AS component, sqlpage.run_sql('r_full_datagrid.sql',         $ctx_json) AS properties;
/*
-- search form to change the query
SELECT 'dynamic' AS component, sqlpage.run_sql('search_form.sql', $ctx_json) AS properties;
*/
