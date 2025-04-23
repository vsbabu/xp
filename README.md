## XP

Is a personal expense dashboard viewer built using [SQLPage](https://sql-page.com/ "SQLPage"). It assumes data is in a single table called `expense` in a sqlite3 database (see `sample/migrations/01_create_schema.sql`).

![Screenshot](screenshot_light.png "Screenshot")

### Features

- A dynamic menu is built using the data available in the database to provide queries by various date ranges like recent months, quarters, financial years etc. By default, current month is shown. See `shell.sql`.
- Various data summarization for a given search/filter is available as tables and graphs.You can also choose to show individual records. See `search_results.sql`.
- A search form pre-filled with current filter is there at the bottom. It also has an option to multi-select categories of expenses to further filter down. You can also exclude selected categories. See `search_form.sql`.

### Getting started

- Clone this repository
- Install `sqlpage.bin` somewhere.
- Run `sqlpage.bin -d ./sample`. This should create an empty sqlpage.db and run migrations to create schema.
- Navigate to http://localhost:8080/ - you should see an empty dashboard.
- Go to http://localhost:8080/csv_import.sql and load _sample/sample.csv_.
- Once it is done, you should have 10K records in the database. You can now explore the dasboard via menus.
- If you want to create a larger sample, see `sample/gensamplecsv.py` description below. 

### Using your own data

- Create CSV file like given in the sample, with your own data. Either use the web interface for importing CSV as above or make your own that does not delete existing data if you prefer appending new ones periodically.
- Best is to create a new `personal.json` config file that points to your own `personal.db` file like below.
  ```json
  {
    "database_url": "sqlite://./personal.db?mode=rwc"
  }
  ```

You can then run using this database as

  ```shell
  sqlpage.bin -c personal.json
  ```

### Code Organization
- [index.sql](index.sql) - main container file. This points to the root of the rendered site. If query string has missing parameters, it is filled with default values before calling `shell.sql`.
  - [shell.sql](shell.sql) - included to draw the menu items. It has SQL for generating various date ranges based on minimum and maximum available data in the `expense` table. It also includes calls to _toggle_ menu items for dark mode and side menu.
    - [toggle_menu.sql](toggle_menu.sql) - sets a cookie when clicked and switch to side menu. On clicking again, cookie is removed. Presence of cookie is used to change default menu location and default icon.
    - [toggle_theme.sql](toggle_theme.sql) - sets a cookie when clicked and switch to dark theme. On clicking again, cookie is removed. Action is like previous one.
  - [search_results.sql](search_results.sql) - runs a series of queries to build the dashboard based on the input parameters like date range, categories etc. Initially, these queries all had similar looking CTEs. I changed it to generate a temporary table that has filtered data and then onwards, that table is used for all queries. This serves two purposes (a) size of SQL code is less (b) temporary table acts as a cache. Since temporary tables are specific to sessions, it shouldn't collide with other parallel users. Also, I've hard coded Indian Rupee (₹) as the currency and formatted it using `printf()` because Indian formatting is different from thousands/millions. SQLPage currently formats according to that convention even when currency is specified as Indian Rupee (_INR_).
  - [search_form.sql](search_form.sql) - has parameters pre-filled according to query string (or defaults in its absence). Changing these and filtering will reload the page with form parameters passed as query string.
  - [csv_import.sql](csv_import.sql) - has a form to replace the `expense` table with a csv file. It calls [csv_process.sql](csv_process.sql) to load the csv uploaded into the table.
  - [assets/](assets/) - favicon files
  - [sample/migrations/01_create_schema.sql](sample/migrations/01_create_schema.sql) - this runs on server startup and is used to create the schema - just one table `expense`
  - [sample/migrations/02_load_sample.sqlite3](sample/migrations/02_load_sample.sqlite3) - this is NOT run automatically because it does not have _.sql_ extension. It can be used to directly load csv file into database using _sqlite3 cli_ - it is much faster than the web interface.
  - [sample/sample.csv](sample/sample.csv) - a generated sample file with 10K records
  - [sample/gensamplecsv.py](sample/gensamplecsv.py) - file that generates random sample data into _sample.csv_. It requires _pandas_ and _faker_ as dependencies and will overwrite _sample.csv_. So, better to copy the script somewhere else, edit it and then run it. You can use this to create larger or customized sample data to load.

### Notable stuff

- There is no security. It is supposed to be used by you on your local machine. Ensure there is a firewall!
- If you want security for such websites, say for internal use, my go to solution has been using nginx and [oauth_proxy](https://github.com/oauth2-proxy/oauth2-proxy) in the front.
- Some columns in the db are pre-computed and loaded, but not used at the moment. I added these for some future  ideas I have.

### Credits

- Favicon was generated using [Grok 3](https://grok.com), then removed background using [remove bg](https://www.remove.bg/upload) and converted using [favicon.ico](https://favicon.io/).
- [SQLite](https://sqlite.org/) for a phenomenal database engine.
- [SQLPage community](https://github.com/sqlpage/SQLPage/discussions) for very useful discussions.

