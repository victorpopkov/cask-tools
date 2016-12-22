# cask-appcast

Get the latest available version, checkpoint and download URL(s) from appcast.

- [Description](#description)
  - [Supported providers](#supported-providers)
  - [Available options](#available-options)
- [Examples](#examples)
  - [GitHub Atom](#github-atom)
  - [SourceForge](#sourceForge)
  - [Sparkle](#sparkle)

## Description

<img src="http://caskroom.victorpopkov.com/cask-tools/cask-appcast.gif" data-canonical-src="http://caskroom.victorpopkov.com/cask-tools/cask-appcast.gif" width="700" />

The purpose of `cask-appcast` is to get the latest available version, checkpoint
and download URL(s) from appcast by detecting which of supported providers is
being used. In the case of unsupported provider, only the checkpoint is
generated.

### Supported providers

At the moment 3 providers are supported:

- GitHub Atom
- SourceForge
- Sparkle

In the future more will be added:

- Apple Property List
- Custom JSON
- Custom XML
- OSDN

### Available options

#### `-h, --help`

Show context-sensitive help.

#### `-u, --user-agent=USER-AGENT`

Set 'User-Agent' header value.

By default `User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2)
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36` is
used.

#### `-t, --timeout=10s`

Set custom request timeout (default is 10s).

#### `--github-auth=USER:TOKEN`

GitHub username and personal token.

Since GitHub have an API limit, it's preferable to set these before making any
request to GitHub. Otherwise, there is a possibility that you will get the
`API rate limit exceeded` message. By default the values are retrieved using:

```bash
git config --get github.user
git config --get github.token
```

Please verify if those values are set on your system.

#### `--github-latest`

Try to get only stable GitHub releases where possible.

GitHub has green 'Latest release' label near stable release or 'Pre-release' for
unstable. Setting this option forces to use only those releases which have
stable tag. It useful when we need only when we are dealing with appcasts in
[Homebrew-Cask](https://github.com/caskroom/homebrew-cask).

#### `-f, --filter=REGEXP`

Filter releases using RegExp.

This option is mainly used in cases when multiple applications are released in
the one appcast. For example, in [adobe-bloodhound.rb](https://github.com/caskroom/homebrew-cask/blob/master/Casks/adobe-bloodhound.rb)
to get releases for macOS only we can use RegExp "^Bloodhound" as a filter.

#### `-c, --checkpoint`

Output appcast checkpoint.

#### `-p, --provider`

Output appcast provider.

#### `-V, --app-version`

Output app version and build (if available).

#### `-d, --downloads`

Output download URL(s).

#### `-i, --insecure-skip-verify`

Skip server certificate verification.

#### `-v, --version`

Show application version.

## Examples

By default only the appcast URL is needed and it will get the latest release.

### GitHub Atom



```bash
$ cask-appcast https://github.com/atom/atom/releases.atom
Appcast:                https://github.com/atom/atom/releases.atom [200]
Checkpoint:             dbecabfa2b5a92eebab4ec360be5b01b1ffa4e6046165808f5b0c01ed55be369
Provider:               GitHub Atom
Authorization:          authorized | username
Latest version:         1.13.0-beta8 | Pre-release
Latest download URLs:   https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-1.13.0-beta8-delta.nupkg
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-1.13.0-beta8-full.nupkg
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-amd64.deb
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-amd64.tar.gz
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-api.json
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-mac-symbols.zip
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-mac.zip
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom-windows.zip
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/atom.x86_64.rpm
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/AtomSetup.exe
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/AtomSetup.msi
                        https://github.com/atom/atom/releases/download/v1.13.0-beta8/RELEASES
```

### SourceForge

```bash
Appcast:                https://sourceforge.net/projects/texstudio/rss [200]
Checkpoint:             caafb1c44826d4204a21cd8db344ec65711386c111c89c499a2de613a92daef8
Provider:               SourceForge
Latest version:         2.12.0
Latest download URLs:   https://sourceforge.net/projects/texstudio/files/texstudio/TeXstudio%20development/texstudio-2.12.0-rc-win-portable-qt5.6.2.zip/download
                        https://sourceforge.net/projects/texstudio/files/texstudio/TeXstudio%20development/texstudio-2.12.0-rc-win-qt5.6.2.exe/download
```

### Sparkle

```bash
$ cask-appcast https://www.adium.im/sparkle/appcast-release.xml
Appcast:               https://www.adium.im/sparkle/appcast-release.xml [200]
Checkpoint:            c0e7148f802efc6a1d255c420ec386c7de1fd1f4cd096970986a8bf891c5f342
Provider:              Sparkle
Latest version:        1.5.10.2
Latest download URL:   https://adiumx.cachefly.net/Adium_1.5.10.2.dmg
```
