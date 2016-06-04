# cask-scripts

Collection of small scripts designed to help maintain the
[Homebrew-Cask](https://github.com/caskroom/homebrew-cask) project.

## List of scripts

To learn more about each script explore [doc](doc/) directory.

### [cask-appcast](doc/cask-appcast.md)

Gets the latest available version, checkpoint and download URL(s) from appcast.

### [cask-check-updates](doc/cask-check-updates.md)

Scans casks with appcasts for outdated ones and automatically gets the latest
version(s). It also normalizes retrieved versions to match the pattern used in
casks.

## Installation

### Mac OS X

The easiest way to install these scripts is using the
[homebrew-cask-scripts](https://github.com/victorpopkov/homebrew-cask-scripts)
repository. You’ll need [Homebrew](http://brew.sh/) installed and then
[Tap](https://github.com/Homebrew/homebrew/wiki/brew-tap) that repository by
running:

```bash
brew tap victorpopkov/cask-scripts
```

Afterwards, install the desired script as any other *formula*. For example, to
install `cask-appcast`, run:

```bash
brew install cask-appcast
```

## Running tests

For testing purposes [Bats](https://github.com/sstephenson/bats) is used, so
before running tests make sure it's installed on your system. After that you can
run all the tests using `make test` or `bats test` commands.

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
