# cask-appcast

Gets the latest available version, checkpoint and download URL(s) from appcast.

## Description

The purpose of `cask-appcast` is to get the latest available version, checkpoint
and download URL(s) from appcast by detecting which of supported providers is
being used. In the case of unsupported provider, only the checkpoint is
generated.

### Supported providers

At the moment only 2 providers are supported:

- Sparkle
- GitHub Atom

In the near future 3 more will be added:

- Apple Property List
- SourceForge
- JSON

### Options

## Examples

By default only the appcast URL(s) is/are needed:

```bash
$ cask-appcast https://www.adium.im/sparkle/appcast-release.xml
Appcast:              https://www.adium.im/sparkle/appcast-release.xml (200)
Checkpoint:           c0e7148f802efc6a1d255c420ec386c7de1fd1f4cd096970986a8bf891c5f342
Provider:             Sparkle
Latest version:       1.5.10.2
Latest download URL:  https://adiumx.cachefly.net/Adium_1.5.10.2.dmg
```

For 'GitHub Atom' provider only stable versions (releases that have green
'Latest release' label) are used. However, you can allow pre-releases (useful
for [homebrew-versions](https://github.com/caskroom/homebrew-versions)) by
adding the `-s` option with `unstable` argument:

```bash
$ cask-appcast -s unstable https://github.com/atom/atom/releases.atom
Appcast:              https://github.com/atom/atom/releases.atom (200)
Checkpoint:           bfbd1cf510a520741c612060390a9af78cc6c3c0a2ee58a91ce8995b2f5fcbed
Provider:             GitHub Atom
Latest version:       1.8.0-beta4 (Pre-release)
Latest download URLs: https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-1.8.0-beta4-delta.nupkg
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-1.8.0-beta4-full.nupkg
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-amd64.deb
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-amd64.tar.gz
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-api.json
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-mac-symbols.zip
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-mac.zip
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom-windows.zip
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/atom.x86_64.rpm
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/AtomSetup.exe
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/AtomSetup.msi
                      https://github.com/atom/atom/releases/download/v1.8.0-beta4/RELEASES
```
