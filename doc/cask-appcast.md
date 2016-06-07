# cask-appcast

Get the latest available version, checkpoint and download URL(s) from appcast.

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

#### `-m, --match <tag>`

Try to filter using the matching tag.

This option is mainly used in cases when multiple applications are released in
the one appcast. For example [adobe-bloodhound.rb](https://github.com/caskroom/homebrew-cask/blob/master/Casks/adobe-bloodhound.rb).

#### `-u, --unstable`

Try to get unstable releases if possible.

Some appcast providers can also specify the stability for each release. For
example 'GitHub Atom' have green 'Latest release' label near each stable release
or 'Pre-release' for unstable. Setting this option forces to use unstable
releases where possible which are especially useful when dealing with appcasts
for [Homebrew-Versions](https://github.com/caskroom/homebrew-versions).

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
adding the `-u` option argument:

```bash
$ cask-appcast -u https://github.com/atom/atom/releases.atom
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
