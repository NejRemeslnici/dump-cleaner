# DumpCleaner

DumpCleaner is a tool that can randomize or anonymize your database dumps. Currently, it works with the [MySQL Shell Dump](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-utilities-dump-instance-schema.html) format (other formats may be added later).

## Why?

The main purpose of this tool is to provide a **safe way to work with production data during development**. Often, production databases can easily fit into the developers’ computers and if they don’t, the database tools usually provide a way to [dump a _subset_](https://dev.to/nejremeslnici/mysql-shell-the-best-tool-for-your-logical-backups-44fk#partial-imports-of-the-logical-dumps) of the data (and leave the audit logs behind, for example).

We believe that working with production data has several benefits over developing against a near-empty and/or a completely made-up data set:

- The volume of data in various tables reflects the production volume. This helps uncover slow queries, missing indices, or unoptimized data retrieval patterns much earlier in the development loop.
- The data that developers work with is realistic. [Faker](https://github.com/faker-ruby/faker) is nice but it can never reach the breadth and variety of real data made by real people using your app.
- Developers don’t have to access the production database (they don’t even have to have the privileges to access it) to test their hypotheses about the data or learn the common patterns or edge cases.

That said, having an exact production data copy at developers’ local machines is insecure and could very well lead to personal data leaks and violations of GDPR or similar legislation. Developers usually do not need to know the exact version of an individual data record (say an individual user’s phone number), they need **a realistic-enough approximation** of the data (say a random number from the same phone carrier). That’s where the DumpCleaner’s main feature, a high-fidelity data anonymization / randomization, comes at hand.

### The goals of this project

- DumpCleaner works with **database _dumps_** rather than databases themselves. Doing that, it fits nicely into the process of cloning the production data to the developer machines.
- It produces **high-fidelity data** during the randomization / anonymization, for example it allows to replace:
  - an individual’s phone number with a random number from the same phone carrier,
  - a gmail.com email address with a different random mailbox at gmail.com,
  - a user’s geographic location with a random location within a few miles from the original one,
  - someone’s name with another random name taken from a dictionary of names you specify,
  - someone’s IP address with a random IP address having the same prefix (same or similar subnet),
  - and so on…
- It works **deterministically**, i.e. multiple runs over the same source data usually result in the same cleaned data.
- It can generate **unique data** across a given table column if needed.
- It can **ignore certain columns and/or records** in the dump based on a set of conditions to e.g. NOT randomize data about certain admin users.
- It obeys the inherent limits of the given dump format, if any (for example, it takes great care to keep the length and byte size of the updated data the same as original so as not to corrupt the MySQL Shell dump chunk index files).

All in all, this tool is just a „more clever and configurable `awk`“, i.e. a text replacement tool.

#### Non-goals and limitations

- This is not an effort to fully anonymize all production personal data according to GDPR rules. In simple cases DumpCleaner might achieve that but in general it is probably not performant and flexible enough.
- The quality of the data randomization often relies heavily on the quality of source dictionaries. There is only a small effort for the tool to be able to _fake_ high fidelity data regardless of the dictionaries, there are [other tools](https://github.com/faker-ruby/faker) for that. If you need the resulting data to be more specific, you can usually prepare a more specific dictionary for your domain.
- Speed: while this tool can process millions of records in a few minutes, there are currently no speed optimizations applied or planned. This is probably not a good tool for live anonymization of bigger amounts of data. It is rather meant to be run as a background task somewhere on your server during the night, just after it dumps out the database backups.
- Currently, DumpCleaner works with the [MySQL Shell Dump](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-utilities-dump-instance-schema.html) format under default settings but other formats may be added later.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG

## Usage

Using of the gem is easy (it is configuring it that is relatively more demanding, see below): the gem provides a `dump_cleaner` executable that should be called with a few arguments:

```sh
$ dump_cleaner -f <source_dump_path> -t <destination_dump_path> [-c <config_file>]
```

where:
- `-f` / `--from=` sets the path to the source (original, non-anonymized) data dump; for MySQL Shell this is the directory with the dump created by the MySQL Shell dump utility
- `-t` / `--to=` sets the path to the destination (anonymized) data dump; for MySQL Shell this is the directory with the dump which will be created or overwritten by DumpCleaner
- `-c` / `--config=` sets the path to the configuration file, see below (default: `config/dump_cleaner.yml`)

### A basic example

The repository includes a [sample MySQL Shell dump](https://github.com/NejRemeslnici/dump-cleaner/tree/main/spec/support/data/mysql_shell_dump) that has been produced by [running](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-utilities-dump-instance-schema.html#mysql-shell-utilities-dump-opt-run) the MySQL Shell dump utility against the `db` database:

```
MySQLShell JS> util.dumpSchemas(["db"], "mysql_shell_dump");
```

The dump contains a `users` table with the following sample contents:

```sh
$ zstdcat spec/support/data/mysql_shell_dump/db@users@@0.tsv.zst

# id    name         email                         phone_number
1       Johnson      johnson@gmail.com             +420774678763
2       Smith        amiright@example.com          +420733653796
3       Williams     anette.williams@example.com   N/A
```

Now, after running DumpCleaner with the following options including a [certain config file](https://github.com/NejRemeslnici/dump-cleaner/blob/main/spec/support/data/mysql_shell_dump_cleaner.yml):

```sh
$ dump_cleaner -f mysql_shell_dump -t mysql_shell_anonymized_dump \
               -c mysql_shell_dump_cleaner.yml
```

a destination dump directory is created with a copy of the source dump but with the data in the `users` table randomized, in this case in the following way:

```sh
$ zstdcat spec/support/data/mysql_shell_anonymized_dump/db@users@@0.tsv.zst

# id    name         email                         phone_number
1       Jackson      variety@gmail.com             +420774443735
2       Allen        contains@present.com          +420733637921
3       Harrison     should.visitors@program.com   N/A
```

There are a few things to note here:
- The names or mail boxes are replaced by random words from the dictionary specified in the config file.
- The replacements did not change the size of the data (actually it keeps the byte size).
- The well-known email domains as well as phone number carrier prefixes have been kept but other parts of the data randomized.
- Some values were ignored (`N/A`) as specified in the config file.

If DumpCleaner was run once again over the same source data and using the same config, it would produce exactly the same randomized data in the output.

### How does DumpCleaner work?

DumpCleaner first reads the config file (see below for details). From the configuration, it finds the tables and columns that need to be sanitized by the cleaning process. It parses the dump data for each table, extracts the fields from each record and runs the following workflows for each field:

- A **”data source“ workflow** that grabs the data for the given data type that will be needed for the cleaning workflow that comes next.
- A **”cleaning“ workflow** usually further extracts the relevant part from the somewhat generic source data based on the field value and then, more importantly, ”cleans“ the field value by randomizing or anonymizing it somehow.
- Optionally, a **”failure“ workflow** which serves as a last resort when the previous steps fail for some reason (return a `nil` value). This workflow usually replaces the field value with a completely random one.

After all configured table columns have been cleaned, the tool copies the remaining data from the original dump so that the destination dump is complete and ready for re-import.

The overall process is summarized in the diagram below, too:

```mermaid
flowchart LR
    A(start) --> AA[read\nconfig]
    AA --> B{{each\ntable}}
    B --> BB{{each\nrecord}}
    BB --> C{{each\nfield}}
    C -->D[run the\ndata source steps]
    D -->E[run the\ncleaning steps]
    E -->F{failed?}
    F -->|yes|G[run the\nfailure steps]
    G --> H
    F -->|no|H{result\nunique?}
    H -->|yes or\nirrelevant|L{more\ndata to\nclean?}
    H --> |no but wanted| E
    L -.-> |yes| C
    L -.-> |yes| BB
    L -.-> |yes| B
    L --> |no| M[copy\nremaining\n data]
    M --> Z(end)
```

## Configuration

A basic DumpCleaner configuration file might look like this:

```yaml
dump_cleaner:
  log_level: info

dump:
  format: mysql_shell

cleanup_tables:
  - db: db
    table: users
    columns:
      - name: name
        cleanup_type: last_name
      - name: e_mail
        cleanup_type: email
        unique: true
      - name: phone_number
        cleanup_type: phone_number_intl

cleanup_types:
  last_name:
    data_source:
      - step: LoadYamlFile
        params:
          file: spec/support/data/dict/last_names.yml
      - step: GroupByBytesize
    cleaning:
      - step: SelectDataByBytesize
      - step: TakeSample
    failure:
      - step: FillUpWithString

  email:
    data_source:
      ...
    cleaning:
      - step: RandomizeEmail
    failure:
      - step: FillUpWithString

  phone_number_intl:
    cleaning:
      - step: RandomizeFormattedNumber
        params:
          # +420123456789
          format: (?<front>\+(?:\d{6}))(?<x>\d{6})
    failure:
      - step: FillUpWithString
    keep_same_conditions:
      - condition: eq
        value: "N/A"
```

The individual config options are as follows:

### `dump_cleaner`

Currently this allows setting the log level. The DumCleaner output is printed to `STDOUT` and the default log level is `INFO`.

### `dump`

This setting currently only defines the format of the data dump. The only recognized format now is `mysql_shell`.

### `cleanup_tables`

This is where things start to be more interesting. The `cleanup_tables` key specifies which tables and their columns should be cleaned and what `cleanup_type` each column is, e.g. which variant of the cleanup process will be used. Optionally, a column may also include a `unique` key: when set to `true` the randomized values in this column will be ensured to be unique across the table.

Optionally, the `keep_same_conditions` key may also hold Conditions (see below) for ignoring the cleanup of a record from the table, if they evaluate to a truthy value for it. This is useful if you want to keep some of the records (say admin users) in the original state.

Optionally, an `id_column` key may be given that determines the foreign key which is responsible for determining the identity of the table records. For example a table associated with a `users` table might have the `id_column` set to `user_id` and this will ensure that the same values in this table will be the same as the corresponding values in the `users` table, keeping consistency across the tables.

### `cleanup_types`

The core of the configuration lies here. Under this key the relevant steps for the `data_source`, `cleaning` or `failure` workflows are specified, with optional `params`. In general, the output of one step makes the input of the following step. It is considered an error if a `cleaning` step returns a `nil` value and that’s when the `failure` procedure takes place.

See a **dedicated page** for the individual steps documentation.

Moreover, under a `keep_same_conditions` key, Conditions (see below) for ignoring the cleanup of the given cleanup type may be given. If they evaluate to true for the given field value, it’s cleanup is not run and the original value is returned.

Finally, the `ignore_keep_same_record_conditions` key may be set to true to indicate that this field value should be always cleaned, even if the `keep_same_conditions` were used for the whole record at the `cleanup_table` level.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome [on GitHub](https://github.com/NejRemeslnici/dump-cleaner/issues).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
