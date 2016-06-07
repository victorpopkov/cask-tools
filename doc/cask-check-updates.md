# cask-check-updates

Scan casks with appcasts for outdated ones and get the latest available
version(s).

## Description

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

#### `-u, --unstable`

Try to get unstable releases if possible.

Some appcast providers can also specify the stability for each release. For
example 'GitHub Atom' have green 'Latest release' label near each stable release
or 'Pre-release' for unstable. Setting this option forces to use unstable
releases where possible which are especially useful when dealing with
[Homebrew-Versions](https://github.com/caskroom/homebrew-versions).

#### `-c, --checkpoint`

Output appcast checkpoint.

#### `-p, --provider`

Output appcast provider.

#### `-V, --app-version`

Output app version and build (if available).

#### `-d, --downloads`

Output download URL(s).

#### `-v, --version`

Show current script version.

#### `-h, --help`

Show the usage message with options descriptions.

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
