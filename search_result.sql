SELECT
    'redirect' AS component,
    '/?'
    || 'start=' || $start
    || '&end=' || $end
    || iif($category is not null, '&category='||$category,'')
    || iif($exclude is not null, '&exclude='||$exclude,'')
    || iif($payee is not null, '&payee='||$payee,'')
    || iif($datagrid is not null, '&datagrid='||$datagrid,'')
    AS link
;
/* this intermediate is there to get rid of the filter_form_modal window opening up in index.html */
