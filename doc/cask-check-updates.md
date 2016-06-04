# cask-check-updates

Scans casks with appcasts for outdated ones and automatically gets the latest
version(s). It also normalizes retrieved versions to match the pattern used in
casks.

## Description

The `cask-check-updates` was designed specifically to find outdated casks that
have appcasts and automatically retrieve latest available versions. It doesn't
require OS X to run and can generate CSV lists.

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
`-s` option with `unstable` argument needs to be added:

```bash
$ cd ~/path/to/homebrew-versions/Casks
$ cask-check-updates -s unstable
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
cask-check-updates -s unstable -o '~/path/to/output.csv'
```
