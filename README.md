# cask-scripts
Collection of small scripts to help maintain the [Homebrew-Cask](https://github.com/caskroom/homebrew-cask) project:
 - [cask-appcast](#cask-appcast)
 - [cask-check-updates](#cask-check-updates)

## cask-appcast

The purpose of `cask-appcast` is to get the latest available version, checkpoint and download URLs from appcast by detecting which of supported providers is being used:
 - Sparkle
 - GitHub Atom

*Usage example:*

```bash
$ cask-appcast https://www.adium.im/sparkle/appcast-release.xml https://github.com/atom/atom/releases.atom
Checking 2 appcasts...
------------------------------------------------------------------------------------------------------------------
Appcast:              https://www.adium.im/sparkle/appcast-release.xml (200)
Checkpoint:           c0e7148f802efc6a1d255c420ec386c7de1fd1f4cd096970986a8bf891c5f342
Provider:             Sparkle
Latest version:       1.5.10.2
Latest download URL:  https://adiumx.cachefly.net/Adium_1.5.10.2.dmg
------------------------------------------------------------------------------------------------------------------
Appcast:              https://github.com/atom/atom/releases.atom (200)
Checkpoint:           86e693608b87f3fa8c89f01a712e71f7b1a1e58ce1f63dfde9239d24caedd08a
Provider:             GitHub Atom
Latest version:       1.7.3 (Latest)
Latest download URLs: https://github.com/atom/atom/releases/download/v1.7.3/atom-1.7.3-delta.nupkg
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-1.7.3-full.nupkg
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-amd64.deb
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-api.json
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-mac-symbols.zip
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-mac.zip
                      https://github.com/atom/atom/releases/download/v1.7.3/atom-windows.zip
                      https://github.com/atom/atom/releases/download/v1.7.3/atom.x86_64.rpm
                      https://github.com/atom/atom/releases/download/v1.7.3/AtomSetup.exe
                      https://github.com/atom/atom/releases/download/v1.7.3/RELEASES
------------------------------------------------------------------------------------------------------------------
```

## cask-check-updates

The `cask-check-updates` was designed specifically to find outdated casks that have appcasts and get versions. It doesn't require OS X to run and can generate output CSV lists. At the moment, it supports only 2 providers for getting the latest version:
 - Sparkle
 - GitHub Atom

*Usage examples:*
```bash
$ cd ~/path/to/homebrew-versions/Casks
$ cask-check-updates -s unstable -a -c
Checking updates for 20 casks...
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:        airmail-beta
Cask version:     2.6.1,360 | 2.6.1,361 (latest)
Cask appcast:     https://rink.hockeyapp.net/api/2/apps/84be85c3331ee1d222fd7f0b59e41b04 (200) | outdated checkpoint (32d79f... => 3826d7...)
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:        atom-beta
Cask version:     1.8.0-beta3 | 1.8.0-beta3
Cask appcast:     https://github.com/atom/atom/releases.atom (200) | valid (86e693...)
...
```

> The `-a/--all` option shows casks even if those are updated. The `-c/--checkpoints` validates appcast checkpoints.

```bash
$ cd ~/path/to/homebrew-cask/Casks
$ cask-check-updates -c cocktail
Cask name:        cocktail
Cask versions:    5.1   | 5.1
                  5.6   | 5.6
                  6.9   | 6.9
                  7.9.1 | 7.9.1
                  8.8.1 | 8.8.2 (latest)
                  9.2.4 | 9.2.4
Cask appcasts:    http://www.maintain.se/downloads/sparkle/snowleopard/snowleopard.xml (200)   | valid (3fb0fd...)
                  http://www.maintain.se/downloads/sparkle/lion/lion.xml (200)                 | valid (81397a...)
                  http://www.maintain.se/downloads/sparkle/mountainlion/mountainlion.xml (200) | valid (916ed1...)
                  http://www.maintain.se/downloads/sparkle/mavericks/mavericks.xml (200)       | valid (9a81f9...)
                  http://www.maintain.se/downloads/sparkle/yosemite/yosemite.xml (200)         | outdated checkpoint (3618d6... => 4c059f...)
                  http://www.maintain.se/downloads/sparkle/elcapitan/elcapitan.xml (200)       | valid (421755...)
...
```

*Generating CSV lists example:*
```bash
# generating CSV list for homebrew-cask
cd ~/path/to/homebrew-cask/Casks
cask-check-updates -o '~/path/to/output.csv'

# generating CSV list for homebrew-versions
cd ~/path/to/homebrew-versions/Casks
cask-check-updates -s unstable -o '~/path/to/output.csv'
```

The latest lists from example above for both [Homebrew-Cask](https://github.com/caskroom/homebrew-cask) and [Homebrew-Versions](https://github.com/caskroom/homebrew-versions) can be found here:
 - http://caskroom.victorpopkov.com/homebrew-cask/outdated.csv
 - http://caskroom.victorpopkov.com/homebrew-versions/outdated.csv

> The lists are regenerated every day at 16:00 (GMT+0).

## License

The Unlicense (Public Domain).
