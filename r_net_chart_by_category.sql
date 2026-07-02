
SELECT 'html' AS component, '<div class="row">' AS html;
SELECT 'dynamic' as component, sqlpage.run_sql('r_net_chart_by_category_treemap.sql', $ctx_json) AS properties;
SELECT 'dynamic' as component, sqlpage.run_sql('r_net_chart_by_category_time.sql', $ctx_json) AS properties;
SELECT '</div>' AS html;
