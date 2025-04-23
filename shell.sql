-- This shell goes to every page

WITH RECURSIVE sequence AS (
  SELECT 0 AS number
  UNION ALL
  SELECT number + 1
  FROM sequence
  WHERE number < 15
),
bounds as (
select
  strftime('%Y',min(date(dt))) as min_yr,
  strftime('%Y',max(date(dt))) as max_yr,
  min(date(dt)) as min_dt,
  max(date(dt)) as max_dt,
  cast(strftime('%Y',max(date(dt))) as int) + case when cast(strftime('%m', max(date(dt))) as int) between 4 and 12 then 1 ELSE 0 END as fy_end_year
from expense
),
years as (
  SELECT s.number + 2 as o,
  'FY '||strftime('%Y',date(b.min_yr||'-04-01', '+'||s.number||' year')) ||
    '-'|| strftime('%Y',date(b.min_yr||'-03-31', '+'||(s.number+1)||' year')) as title,
  date(b.min_yr||'-04-01', '+'||s.number||' year') as start,
  date(b.min_yr||'-03-31', '+'||(s.number+1)||' year') as end
  FROM sequence s, bounds b
  WHERE date(b.min_yr||'-03-31', '+'||(s.number+1)||' year') <= date(b.fy_end_year||'-03-31')
  union
  SELECT
  s.number + 2 + 1 as o,
  strftime('%Y',date(b.max_yr||'-01-01', '-'||s.number||' year')) as title,
  date(b.max_yr||'-01-01', '-'||s.number||' year') as start,
  date(b.max_yr||'-12-31', '-'||s.number||' year') as end
  FROM sequence s, bounds b
  WHERE date(b.max_yr||'-01-01', '-'||s.number||' year') >= date(b.min_yr||'-01-01')
  order by 2 desc
),
submenu_yr as (
  SELECT json_group_array(json_object(
  'title', title,
  'link', '/?t='||title||'&start='||start||'&end='||end
  )) as sm from years
),
qtrs as (
select
  -- floor function is not compile timed to sqlpage; hence using cast
  strftime('%Y-Q',date(current_date, '-'||(3*s.number)||' months'))||
    cast((strftime('%m',date(current_date, '-'||(3*s.number)||' months'))+2)/3 as integer) as qtr
  , date(strftime('%Y-'||substr('00'||(3*(cast((strftime('%m',date(current_date, '-'||(3*s.number)||' months'))+2)/3 as integer)-1)+1), -2)||'-01', date(current_date, '-'||(3*s.number)||' months'))) as start
  , date(strftime('%Y-'||substr('00'||(3*(cast((strftime('%m',date(current_date, '-'||(3*s.number)||' months'))+2)/3 as integer)-1)+1), -2)||'-01', date(current_date, '-'||(3*s.number)||' months')), '+95 days', 'start of month', '-1 day') as end
  from sequence s
),
submenu_qtr as (
  SELECT json_group_array(json_object(
  'title', qtr,
    'link', '/?t='||qtr||'&start='||start||'&end='||end
  )) as sm from qtrs
),
months as (
  SELECT
  strftime('%Y-%m', current_date, 'start of month', '-'||(s.number)||' month' ) as title,
  date(current_date, 'start of month', '-'||s.number||' month') as start,
  date(current_date, 'start of month', '-'||s.number||' month', '+1 month', '-1 day') as end
  FROM sequence s, bounds b
  WHERE
  date('now', 'start of month', '-'||(s.number+1)||' month' ) >= b.min_dt
  and s.number < 12
  order by 1 desc
),
submenu_month as (
  SELECT json_group_array(json_object(
  'title', title,
  'link', '/?t='||title||'&start='||start||'&end='||end
  )) as sm from months
),
recents as (
  SELECT 1 o, '3 months  (' || date(current_date, '-3 months') || ')' as title, date(current_date, '-3 months') as start,  current_date as end
  union
  SELECT 2 o, '3 months»  (' || date(current_date, '-3 months', 'start of month') || ')' as title, date(current_date, '-3 months', 'start of month') as start,  current_date as end
  union
  SELECT 3 o, '6 months  (' || date(current_date, '-6 months') || ')' as title, date(current_date, '-6 months') as start,  current_date as end
  union
  SELECT 4 o, '6 months»  (' || date(current_date, '-6 months', 'start of month') || ')' as title, date(current_date, '-6 months', 'start of month') as start,  current_date as end
  union
  SELECT 5 o, strftime('Year %Y', current_date) as title, date(current_date, 'start of year') as start,  current_date as end
),
submenu_recent as (
  SELECT json_group_array(json_object(
  'title', title,
  'link', '/?t='||title||'&start='||start||'&end='||end
  )) as sm from recents order by o
)
SELECT 'shell' AS component,
	'XP' AS title, 'assets/favicon.ico' as favicon,
  'assets/favicon.ico' as image,
  'fluid' as layout, 
	IIF(COALESCE(sqlpage.cookie('topsidebar'),'') = '', false, true) as sidebar,
	sqlpage.cookie('lightdarkstatus') AS theme,
	'/' AS link,
  'en' as lang,
  'XP SQLPage' as description,
  '[
  {"title":"Monthly", "icon":"calendar-month", "submenu" :'|| submenu_month.sm ||'},
  {"title":"Quarterly", "icon":"calendar-pin", "submenu" :'|| submenu_qtr.sm ||'},
  {"title":"Yearly", "icon":"calendar-dollar", "submenu": '|| submenu_yr.sm || '},
  {"title":"Recent", "icon":"calendar-clock", "submenu": '|| submenu_recent.sm || '},
  {"title":"", "icon":"'||IIF(COALESCE(sqlpage.cookie('topsidebar'),'') = '', 'layout-sidebar-left-collapse', 'layout-navbar-collapse')||'","link":"/toggle_menu.sql"},
  {"title":"", "icon":"'||IIF(COALESCE(sqlpage.cookie('lightdarkstatus'),'') = '', 'moon-stars', 'sun-high')||'","link":"/toggle_theme.sql"}
  ]' AS menu_item,
  '[XP](https://github.com/vsbabu/xp/) built with [SQLPage '||sqlpage.version()||'](https://sql-page.com/)'
AS footer from submenu_month, submenu_qtr, submenu_yr, submenu_recent;
