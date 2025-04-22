# XP

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
- If you want to create a larger sample, see `sample/gensamplecsv.py`. It requires _pandas_ and _faker_ as dependencies and will - overwrite _sample.csv_. So, better to copy the python script somewhere else and edit it and then run it.

### Using your own data

- Create CSV file like given in the sample, with your own data. Either use the web interface for importing CSV as above or make your own that does not delete existing data if you prefer appending new ones periodically.
- Best is to create a new `personal.json` config file that points to your own `personal.db` file like below.
  ```json
  {
    "database_url": "sqlite://./personal.db?mode=rwc"
  }
  ```

````
You can then run using this database as
```shell
sqlpage.bin -c personal.json
````
