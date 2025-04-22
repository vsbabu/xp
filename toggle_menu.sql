SELECT 'cookie' AS component,
	'topsidebar' AS name,
	IIF(COALESCE(sqlpage.cookie('topsidebar'),'') = '', 'side', '') AS value;

SELECT 'redirect' AS component, sqlpage.header('referer') AS link;
