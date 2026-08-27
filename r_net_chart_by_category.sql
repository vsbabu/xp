
select 
    'divider'            AS component,
    'Expenses (₹'   ||  Cast(-1 * Sum(f.net) AS INTEGER) || ')'
                         AS contents,
    true                 AS bold,
    4                 AS size
FROM  filtered f
WHERE f.category NOT IN ( 'Transfer', 'Reconcile', 'Salary', 'Interest' );

SELECT 'html' AS component, '<div class="row g-0 gap-3">' AS html;
SELECT 'dynamic' as component, sqlpage.run_sql('r_net_chart_by_category_treemap.sql', $ctx_json) AS properties;
SELECT 'dynamic' as component, sqlpage.run_sql('r_net_chart_by_category_time.sql', $ctx_json) AS properties;
SELECT '</div>' AS html;
