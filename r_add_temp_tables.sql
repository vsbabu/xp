-- temporary table is session specific; so no collitions and is autodropped after the session is closed.
-- this reduces the query code length a lot.
-- sqlpage closes the session AFTER a request is served.
-- Quick refresh fails at create temporary table. That is because
-- connection is reused from the pool, but session is different.
-- We can safely drop if exists without impacting concurrent series
-- and proceed.
DROP TABLE IF EXISTS filtered;
CREATE TEMPORARY TABLE filtered AS SELECT e.*
FROM expense e
WHERE DATE(e.dt) BETWEEN
    DATE($start) AND DATE($end) AND e.category IN (
    SELECT value AS category FROM JSON_EACH($category) WHERE $category <> '' AND IFNULL($exclude,'') = ''
    UNION
    SELECT DISTINCT(category) FROM expense WHERE IFNULL($category,'') = ''
    UNION
    SELECT DISTINCT(x.category) FROM expense x WHERE $category <> '' AND IFNULL($exclude, '') <> ''
                      AND x.category NOT IN (SELECT value AS category FROM JSON_EACH($category))
    )
    AND (($payee <> '' AND EXISTS (SELECT 1 FROM payees WHERE payee MATCH $payee AND id=e.id )) OR ($payee = ''))
;

DROP TABLE IF EXISTS filtered_p;
CREATE TEMPORARY TABLE filtered_p AS SELECT e.*
FROM expense e
WHERE DATE(e.dt) BETWEEN $pstart AND $pend
  AND e.category IN (
    SELECT value AS category FROM JSON_EACH($category) WHERE $category <> '' AND ifnull($exclude,'') = ''
    UNION
    SELECT DISTINCT(category) FROM expense WHERE IFNULL($category,'') = ''
    UNION
    SELECT DISTINCT(x.category) FROM expense x WHERE $category <> '' AND IFNULL($exclude, '') <> ''
                      AND x.category NOT IN (SELECT value AS category FROM JSON_EACH($category))
    )
    AND (($payee <> '' AND EXISTS (SELECT 1 FROM payees WHERE payee MATCH $payee AND id=e.id )) OR ($payee = ''))
;

-- FIXME: Categories should've a lookup value for grouping in db instead of this temp table and a gui to tag Categories
--        according to people's data
DROP TABLE IF EXISTS category_classification;
CREATE TEMPORARY TABLE category_classification (
      category TEXT
    , classification TEXT
);
INSERT INTO category_classification (category, classification) VALUES
      ('Tax',           'Government')
    , ('TDS',           'Government')
    , ('Hire',          'Essential')
    , ('Fuel',          'Essential')
    , ('Grocery',       'Essential')
    , ('Dinner',        'Essential')
    , ('Telephone',     'Essential')
    , ('Medicine',      'Essential')
    , ('Car',           'Vehicles')
    , ('Bike',          'Vehicles')
    , ('School',        'Future')
    , ('Insurance',     'Future')
    , ('Interest',      'Returns')
    , ('Reconcile',     'Returns')
    , ('Salary',        'Essential')
    , ('Fun',           'Often')
    , ('Gifts',         'Often')
    , ('Clothes',       'Often')
;
