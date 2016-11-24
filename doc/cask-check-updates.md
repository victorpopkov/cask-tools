# cask-check-updates

Scan casks with appcasts for outdated ones and get the latest available
version(s).

- [Description](#description)
  - [Supported providers](#supported-providers)
  - [Lists of outdated casks](#lists-of-outdated-casks)
  - [Available options](#available-options)
- [Configuration](#configuration)
  - [Rules](#rules)
- [Examples](#examples)
  - [Default](#default)
  - [Unstable releases](#unstable-releases)
  - [CSV lists](#csv-lists)

## Description

<img src="http://caskroom.victorpopkov.com/cask-scripts/cask-check-updates.gif" data-canonical-src="http://caskroom.victorpopkov.com/cask-scripts/cask-check-updates.gif" width="700" />

The `cask-check-updates` was designed specifically to find outdated casks that
have appcasts and automatically retrieve latest available versions. It also
normalizes retrieved versions to match the patterns used in casks.

Doesn't require OS X to run and can generate CSV lists.

### Supported providers

At the moment only 2 providers are supported:

- Sparkle
- GitHub Atom

In the near future 3 more will be added:

- Apple Property List
- SourceForge
- JSON

### Lists of outdated casks

Since casks for [Homebrew-Cask](https://github.com/caskroom/homebrew-cask) and
[Homebrew-Versions](https://github.com/caskroom/homebrew-versions) are becoming
outdated almost each day, the most recent lists of outdated ones for convenience
can be found here:

- <http://caskroom.victorpopkov.com/homebrew-cask/outdated.csv>
- <http://caskroom.victorpopkov.com/homebrew-versions/outdated.csv>

Please note, that the lists are regenerated **every day at 16:00 (GMT+0)**. So
double check before submitting a PR, that those haven't been updated by someone
else yet.

### Available options

#### `-g, --github <user>:<token>`

GitHub username and personal token.

Since GitHub have an API limit, it's preferable to set these before making any
request to GitHub. Otherwise, there is a possibility that you will get the
`API rate limit exceeded` message. By default the values are retrieved using:

```bash
git config --get github.user
git config --get github.token
```

Please verify if those values are set on your system.

#### `-H, --header <header>`

Set browser header.

By default `User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2)
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36` is
used.

#### `-o, --output <filepath>`

Output the results in CSV format into a file.

For example, to output a CSV list in your home directory:

```bash
cask-check-updates -o ~/outdated.csv
```

#### `-u, --unstable`

Try to get unstable releases if possible.

Some appcast providers can also specify the stability for each release. For
example 'GitHub Atom' have green 'Latest release' label near each stable release
or 'Pre-release' for unstable. Setting this option forces to use unstable
releases where possible which are especially useful when dealing with
[Homebrew-Versions](https://github.com/caskroom/homebrew-versions).

#### `-a, --all`

Show and output all casks even updated ones.

By default, only the casks that need to be updated are shown on screen and added
to the CSV file. This parameter forces to show all the casks even if they are
having the latest version but checkpoints don't match.

#### `-c, --checkpoints`

Validate checkpoints.

By default, the checkpoints validation is not shown on screen. Use this parameter
to enable it.

#### `-v, --version`

Show current script version.

#### `-h, --help`

Show the usage message with options descriptions.

## Configuration

Since versions used in casks doesn't always use the only version which is used
by default (`2.3.5,308 → 2.3.5`) in this script, some of them need to have a
build instead (`2.3.5,308 → 308`) or even have a combination of those
(`2.3.5,308`). Even the order of them can be different (`308,2.3.5`). In
addition, some casks even need to include some parts of the download URL since
those can also change in each new release:

```
https://dl.devmate.com/com.macpaw.CleanMyMac3/3.3.6/1463736430/CleanMyMac3-3.3.6.zip
3.3.6 → 3.3.6,1463736430
```

Another problem is that some appcasts provide versions with excessive text that
should be deleted (`3.0.20160607-nightly → 3.0.20160607`) or even normalized
using different patterns (`rel-184 → 1.84`).

To solve this inconsistency, XML [configuration](../lib/cask-scripts/config/cask-check-updates.xml)
file is used that include different rules.

### Rules

In total 5 different rules are available:

- **version-delimiter-build** `2.3.5,308 → 2.3.5,308`
- **version-only** `2.3.5,308 → 2.3.5`
- **build-only** `2.3.5,308 → 308`
- **matching-tag** (filter using the matching tag)
- **custom** (use different patterns)

The first three rules should be self-explanatory. The most confusing ones are
**matching-tag** and **custom**.

#### matching-tag

In some rare cases, some appcasts can have multiple applications released in
one. For example [adobe-bloodhound.rb](https://github.com/caskroom/homebrew-cask/blob/master/Casks/adobe-bloodhound.rb)
or [xquartz.rb](https://github.com/caskroom/homebrew-cask/blob/master/Casks/xquartz.rb).
This rule helps to omit the unnecessary releases by grepping them with specified
tag.

#### custom

When all the above rules don't solve the problem, the last resort is to use
the **custom**. This is the most flexible one and has different tags available
that can help to achieve the desired result:

- **version**
- **build**
- **delimiter**
- **text**
- **devmate-part**
- **hockeyapp-part**
- **amazonaws-part**
- **hackplan-part**

Each of those can have a _pattern_ and _replacement_ attributes that exploit the
Ruby `gsub(pattern, replacement)`.

## Examples

### Default

By default you just have to `cd` into the Casks directory and run the script:

```bash
$ cd ~/path/to/homebrew-cask/Casks
$ cask-check-updates
Checking updates for 1135 casks...
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      airtool
Cask version:   1.3.2 | 1.3.3,11 → 1.3.3 (latest)
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      beaconscanner
Cask version:   1.1.8 | 1.11 (latest)
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      bilibili
Cask version:   2.40 | 2.42 (latest)
...
```

### Unstable releases

Since [Homebrew-Versions](https://github.com/caskroom/homebrew-versions) uses
unstable releases some appcast providers like 'GitHub Atom' have the stability
specified. For example 'GitHub Atom' have stability labels like 'Latest release'
or 'Pre-release'. In order to retrieve the latest versions of pre-releases the
`-u` option needs to be added:

```bash
$ cd ~/path/to/homebrew-versions/Casks
$ cask-check-updates -u
Checking updates for 22 casks...
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      airmail-beta
Cask version:   3.0,368 | 3.0,369 (latest)
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      iterm2-nightly
Cask version:   3.0.20160602 | 3.0.20160604-nightly → 3.0.20160604
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:      vivaldi-snapshot
Cask version:   1.2.490.32 | 1.3.501.6 (latest)
...
```

### CSV lists

In some cases it's useful to output all the found outdated casks into separate
CSV lists:

- <http://caskroom.victorpopkov.com/homebrew-cask/outdated.csv>
- <http://caskroom.victorpopkov.com/homebrew-versions/outdated.csv>

In order to do that you have to `cd` into the Casks directory and run the script
with `-o` option and `~/path/to/output.csv` argument. For example:

```bash
cd ~/path/to/homebrew-versions/Casks
cask-check-updates -u -o '~/path/to/output.csv'
```
