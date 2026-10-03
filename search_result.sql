-- clear criteria cookie to populate it with values properly when redirect happens
SELECT 'cookie' AS component,
    'filter_criteria' AS name,
     TRUE AS remove,
     FALSE AS secure
;

-- this is to clear the search form when nothing is passed
SELECT
    'redirect' AS component,
    '/?' AS link
WHERE $start is null;

-- this is to set an exists for top bar search icon highlight BEFORE redirect,
-- if any search criteria is set
SELECT 'cookie' AS component,
    'filter_criteria' AS name,
     json_quote(json_object('exists', true)) AS value,
     FALSE AS secure
WHERE ($account is not null)
   OR ($category is not null)
   OR ($payee is not null)
   OR ($datagrid is not null)
;
-- this is to redirect after setting parameters properly
SELECT
    'redirect' AS component,
    '/?'
    || 'start=' || $start
    || '&end=' || $end
    || iif($account is not null, '&account='||$account,'')
    || iif($category is not null, '&category='||$category,'')
    || iif($exclude is not null, '&exclude='||$exclude,'')
    || iif($payee is not null, '&payee='||$payee,'')
    || iif($datagrid is not null, '&datagrid='||$datagrid,'')
    AS link
WHERE $start is not null
;

/* this intermediate is there to get rid of the filter_form_modal window opening up in index.html */
