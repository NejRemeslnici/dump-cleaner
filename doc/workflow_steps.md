# Workflow steps

This is a reference documentation for individual [workflow steps](/README.md#how-does-dumpcleaner-work) of [DumpCleaner](/README.md).

#### [Data source steps](#data-source-steps-1)

step     | main purpose
---------|--------
[GroupByBytesize](#groupbybytesize) | groups data by length and byte size
[InspectContext](#inspectcontext) | shows debug information about the current step context
[LoadYamlFile](#loadyamlfile) | loads a YAML file into data
[RemoveAccents](#removeaccents) | removes accents from the data

#### [Cleaning steps](#cleaning-steps-1)

step     | main purpose
---------|--------
[AddRepetitionSuffix](#addrepetitionsuffix) | ensures a unique value by adding a repetition suffix to it
[FillUpWithString](#fillupwithstring) | fills the value with a static string
[GenerateRandomString](#generaterandomstring) | replaces the value with a random string
[InspectContext](#inspectcontext-1) | shows debug information about the current step context
[RandomizeEmail](#randomizeemail) | randomizes parts of an email address
[RandomizeFormattedNumber](#randomizeformattednumber) | randomizes parts of a formatted number
[RandomizeNumber](#randomizenumber) | randomly shifts a number to a certain extent
[SelectDataByBytesize](#selectdatabybytesize) | selects a subset by value length and byte size from the data
[SelectDataByPattern](#selectdatabypattern) | selects a subset by matching a pattern from the data
[TakeSample](#takesample) | takes a random sample from the data

#### [Failure steps](#failure-steps-1)

## Data source steps

The data source steps **prepare the data** (**”cleanup data“**) that can be later used in the [cleaning workflows](#cleaning-steps-1). These steps are linked to the [`cleanup_type`](/README.md#cleanup_types) itself and have no notion of the individual records in the dump table data. Steps are listed in alphabetical order:

### [GroupByBytesize](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/data_source_steps/group_by_bytesize.rb)

This step takes the cleanup data as a list of values (typically loaded from a dictionary file) and groups them according to their length and byte size (the number of bytes needed to encode the values). It processes the data into a hash, where the keys are constructed as `"<length>-<bytesize>"` strings. It is supposed to be used together with the [`SelectDataByBytesize`](#selectdatabybytesize) cleaning step.

The grouping has two goals:
- it allows replacing source data with random data of the same length which adds fidelity to the cleaned up data (long values stay long and vice versa),
- it allows obeying the technical limits of the MySQL Shell dump format which separates larger data into ”chunks“ and annotates them using byte-size-indexed files; DumpCleaner does not attempt to update these index files, thus it needs to keep the byte size of the values untouched.

#### Params:

- `under_keys`: notifies DumpCleaner that the cleanup data is not a list but actually a hash of multiple lists and that the grouping should be done only in lists under the specified keys of the data hash. This is useful in cases when the cleanup data needs to hold multiple unrelated lists of values.

### [InspectContext](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/data_source_steps/inspect_context.rb)

This is purely a debugging step that makes DumpCleaner print the current step context. The step context includes:

- `orig_value`: original value taken from the record field
- `current_value`: i.e. the running state of the result value in the current workflow
- `type`: the [cleanup type](/README.md#cleanup_types) that this step is working with
- `record`: the record context taken from the current record (see the `record_context_columns` option above)
- `cleanup_data`: the data available for the step (only a subset of all data is shown here)
- `repetition`: the current iteration in the uniqueness loop.

### [LoadYamlFile](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/data_source_steps/load_yaml_file.rb)

This is usually the first step in the ”data source“ workflow. It loads some data from a YAML file (a ”dictionary“) and returns it. The data can be, in general, any YAML-supported structure, but most commonly it will be a list of string values or a hash of multiple such lists.

Care should be taken when loading string data taken from various dictionaries. There must be quoting applied at least to the [words having special meaning](https://yaml.org/type/bool.html) in YAML, such as "no" or "n", otherwise the cleanup process will likely fail.

#### Params:

- `file`: specifies the path to the YAML file; this is a mandatory parameter.
- `under_key`: optionally makes the step put the loaded data into a hash under the specified key instead of returning the loaded data itself. This is useful for grabbing multiple value lists from different dictionary files.

### [RemoveAccents](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/data_source_steps/remove_accents.rb)

This step uses the [`unicode_normalize`](https://ruby-doc.org/stdlib-2.4.0/libdoc/unicode_normalize/rdoc/String.html) method to remove all accents from all values in the cleanup data, i.e., for example, ”naïve“ will be converted to ”naive“. This can be useful for example when we want to use the same YAML file to build a generic random words dictionary as well as a dictionary of logins or domains (which should have no accented characters in them).

#### Params:

- `under_keys`: optionally tells the step to only process the list under the specified keys in the cleanup data hash.

config | input data | output data |
------- | ----- | ----- |
| <pre lang="yml">- step: RemoveAccents&#13;  tete: te</pre> | `["naïve", "žluťoučký"]` | `["naive", "zlutoucky"]` |

## Cleaning steps

Contrary to the Source data workflow, steps in the Cleaning workflow do know about the currently processed record and **can access, or modify, the currently processed field value**. The first step gets its ”current value“ from the currently processed table record.

In general, the steps can either transform the current value or the [cleanup data](#data-source-steps-1) or both. Processing the cleanup data is often useful during the first few workflow steps because it can further prepare the data in relation to the current record / field. Later steps (usually the last one) then, with the help of the prepared data, do the cleaning itself. Steps are listed in alphabetical order:

### [AddRepetitionSuffix](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/add_repetition_suffix.rb)

This step add a repetition suffix to the current value. This is useful in unique columns when the randomized value conflicts with a value determined for one of the earlier records. As described in the [Uniqueness section](/README.md#unique-values), this step keeps the string length and byte size untouched. The step never adds suffix for repetition 0, i.e. for the very first iteration of the uniqueness loop or when there is no uniqueness requested in the first place.

If the current value is too small to even hold a repetition suffix, it is replaced by a randomly generated string of equal length.

### [FillUpWithString](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/fill_up_with_string.rb)

This step replaces the current value with a predefined static string. By default, it truncates or prolongs (by repeating) the string so that its byte size is the same as for the original value. If uniqueness is desired for the column, a [repetition suffix](#addrepetitionsuffix) may be added in cases of conflicts.

#### Params:

- `string`: the string to replace the current value with; it is automatically truncated or prolonged to the desired number of bytes; the default string is `"anonymized <type>"` where `<type>` is the name of the current [`cleanup_type`](/README.md#cleanup_types).
- `padding`: if the truncated or prolonged string still does not perfectly fit the desired byte size (due to multi-byte characters in the string and/or original value), the string is padded with the contents of this parameter. It should normally be set to a 1-byte single character. By default this is a space `" "`.
- `strict_bytesize_check`: if set to true, the step will raise an error if the `string` byte size differs from the byte size of the current value. This is useful for resetting all values of a given table column to the same string and ensuring byte size consistency along the way.

### [GenerateRandomString](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/generate_random_string.rb)

This step replaces the current value using a generated a random string with the same byte size. The randomness is [deterministic](/README.md#randomization-is-deterministic). By default, the random string will consist of alphanumeric characters.

#### Params:

- `character_set`: determines the character set to be used when generating the string. Currently supported predefined values are:
  - `alphanumeric`: the default - lower- and uppercase letters and numbers
  - `alpha`: lower- and uppercase letters only
  - `lowercase`: lowercase letters only
  - `uppercase`: uppercase letters only
  - `numeric`: numbers only

  Or, the character set may be passed in explicitly as an array of characters.

### [InspectContext](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/inspect_context.rb)

This step serves the exact same purpose as the [InspectContext](#inspectcontext) step in the ”data source“ workflow.

### [RandomizeEmail](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/randomize_email.rb)

This step tries to randomize an email address in a clever, high-fidelity way. In general, it replaces both the mailbox part as well as the domain of the email address with random words taken from a dictionary. For the mailbox part, it keeps the dots (`"."`) in it and randomizes the words surrounding them.

If finding a suitable word from the dictionary fails (e.g. there is no word with the necessary byte size present in it), the step generates a random string of the proper size instead.

By default, the step keeps the TLD part of the domain. Optionally, it can keep the whole domain which may be convenient for well-known domains, such as gmail.com or example.com. Note that the step generally does no particular effort to guarantee that it doesn’t generate a valid, existing email address.

In case unique column values are requested, the step may add [repetition suffix](#addrepetitionsuffix) to the randomized parts of the mail address.

If an invalid email address is encountered, a warning is logged and the processing switches to the [failure workflow](#failure-steps-1).

#### Params:

- `domains_to_keep_data_key`: the key in the cleanup data hash which contains the list of well-known domains; email address from such domains will keep the domain part unsanitized; default value: `domains_to_keep`
- `words_data_key`: the key in the cleanup data hash which contains the list of words to take random samples from; the list should be grouped by the byte size (use [`GroupByBytesize`](#groupbybytesize) with the `under_keys` param); default value: `words`.

### [RandomizeFormattedNumber](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/randomize_formatted_number.rb)

This step randomizes the specified parts of a formatted number. It can be used for randomizing the last N digits of a number, a phone number, an IP address etc. The step requires a regular expression to be passed in, specifying the [named match groups](https://ruby-doc.org/3.3.2/Regexp.html#class-Regexp-label-Named+Captures) to be randomized or kept intact. The randomized parts of the formatted value are replaced by a random number with a corresponding number of digits.

If an invalid formatted number is encountered (i.e. a number which does not match the regexp), a warning is logged and the processing switches to the [failure workflow](#failure-steps-1).

#### Params:

- `format`: the regexp with the [named match groups](https://ruby-doc.org/3.3.2/Regexp.html#class-Regexp-label-Named+Captures) defined, that determine which parts of the value will be replaced by a random number and which will be kept. The matching groups in the regexp must cover the whole formatted value, otherwise the length of the resulting value won’t match the original. The parts to be randomized must be covered by match groups named `x…` (beginning with the letter `x`), other parts must be covered by match groups named with another first letter. Each match group must have a unique name.

#### Examples:

If `1-123-456-789` is the current value then the `format` of `(?<front>\d-\d{3}-)(?<x1>\d{3})(?<hyphen>-)(?<x2>\d{3})` would randomize the last six digits of the value, resulting in e.g. `1-123-786-802`. The match groups named `x1` and `x2` cover the parts that should get randomized, other match groups cover the rest of the value which is left alone.

### [RandomizeNumber](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/randomize_number.rb)

The goal of this step is to randomize a floating point or integer number to a certain extent. I.e., the current value is not fully replaced, it is slightly and randomly shifted instead. The number is converted to a floating point number before randomization and the final sanitized value is rounded to the same decimal places as was the original.

Note that the sign of the number is never changed, even in cases when the calculation leads to a number with the opposite sign. This is due to the need to keep the byte size of the value intact under all circumstances.

#### Params:

- `difference_within`: maximum difference between the original value and the randomized one. The limit is exclusive, i.e. the final difference will always be at least a bit smaller and will never reach the maximum difference itself.

### [SelectDataByBytesize](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/select_data_by_bytesize.rb)

This step expects the cleanup data to be a hash of lists grouped by the byte size (see [GroupByBytesize](#groupbybytesize)) and selects the list of values that have the same length and bytesize as the currently processed value.

### [SelectDataByPattern](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/select_data_by_pattern.rb)

This step expects the cleanup data to be a hash of lists and selects the list determined by matching the current value against a set of regexp patterns. For example, let’s have two lists of names, male and female names, in the cleanup data hash and let’s pretend that we can guess the gender from a pattern in a person’s last name reasonably well (which is indeed possible in some languages). We can then for example set up a pattern to select female data and leave all other matches to male data.

#### Params:

- `patterns`: a mandatory parameter that is an array of hashes with the following keys:
  - `pattern`: the repexp pattern to match the current value against
  - `flags`: optional [regexp flags](https://docs.ruby-lang.org/en/master/Regexp.html#class-Regexp-label-Modes) (modes), such as `"i"` for case-insensitive matching
  - `key`: the key in cleanup data to select if the `pattern` matches the current value
- `default_key`: this key is selected from the cleanup data hash if no `pattern` matches the current value (default: `nil`).

### [TakeSample](https://github.com/NejRemeslnici/dump-cleaner/blob/main/lib/dump_cleaner/cleanup/cleaning_steps/take_sample.rb)

This step takes a random sample from a list in the cleanup data. If uniqueness is requested for the currently processed value, the step can either retry taking a sample or add a repetition suffix.

If the cleanup data is empty or missing, the procedure switches to the [failure workflow](#failure-steps-1).

#### Params:

- `uniqueness_strategy`: the strategy this step undertakes when it hits a conflicting value while uniqueness is desired:
  - `resample`: the step takes another random sample from the same data
  - `suffix`: the step adds a [repetition suffix](#addrepetitionsuffix) to the sample taken in the first repetition loop.

## Failure steps

In general, any step from the [Cleaning workflow](#cleaning-steps-1) may be used as a Failure workflow step as well. In practice, some of the steps are used more commonly than others here.

If even the failure workflow fails to return some value (returns a `nil` value), the behavior is not fully specified. An error is logged and a blank value is probably  written to the destination dump, which may lead to some ”data corruption“ warnings during re-importing the dump.
