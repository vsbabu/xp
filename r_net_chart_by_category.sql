
SELECT 'card' AS component, 2 as columns;
-- random string is added to disable caching get request from previous call
SELECT sqlpage.link('r_net_chart_by_category_treemap', $ctx_json, '&_sqlpage_embed&r='||sqlpage.random_string(32)) AS embed, 3 as width;
SELECT sqlpage.link('r_net_chart_by_category_time', $ctx_json, '&_sqlpage_embed&r='||sqlpage.random_string(32)) AS embed, 9 as width;
