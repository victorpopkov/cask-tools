# cask-homepage

Check homepages of the casks and try to fix them.

- [Description](#description)
  - [Lists of homepages](#lists-of-homepages)
  - [Available options](#available-options)
  - [Available warnings (rules)](#available-warnings-rules)
- [Examples](#examples)
  - [Default](#default)
  - [CSV lists](#csv-lists)

## Description

<img src="http://caskroom.victorpopkov.com/cask-scripts/cask-homepage.gif" data-canonical-src="http://caskroom.victorpopkov.com/cask-scripts/cask-homepage.gif" width="700" />

The `cask-homepage` script is designed to check homepages of the casks for
availability by checking their response statuses. It's useful in finding casks
that are no longer maintained or available. It also checks the URL for these
rules (in brackets) below and gives appropriate warnings if violated:

- [Host has changed](#host-has-changed-host) _(host)_
- [Path has changed](#path-has-changed-path) _(path)_
- [Only HTTP is available](#only-http-is-available-http) _(http)_
- [HTTPS is available](#https-is-available-https) _(https)_
- [Server prefers to include WWW](#server-prefers-to-include-www-www) _(www)_
- [Server prefers to exclude WWW](#server-prefers-to-exclude-www-no_www) _(no_www)_
- [Server prefers to include a trailing slash](#server-prefers-to-include-a-trailing-slash-slash)
  _(slash)_
- [Server prefers to exclude a trailing slash](#server-prefers-to-exclude-a-trailing-slash-no_slash)
  _(no_slash)_
- [Missing a bare domain URL trailing slash](#missing-a-bare-domain-url-trailing-slash-bare_slash)
  _(bare_slash)_

> The word in brackets represents the rule itself and can be found a warning in
> CSV or can be used with `-i, --ignore` option.

The script also can automatically fix those warnings when running it in
combination with the `-f, --fix` option.

### Lists of homepages

Since there are a lot of casks in [Homebrew-Cask](https://github.com/caskroom/homebrew-cask)
and [Homebrew-Versions](https://github.com/caskroom/homebrew-versions) some of
them can become unavailable due to various reasons which usually is reflected on
the homepage. To help maintainers find such casks the weekly result of this
script is available here:

- <http://caskroom.victorpopkov.com/homebrew-cask/homepages.csv>
- <http://caskroom.victorpopkov.com/homebrew-versions/homepages.csv>

Please note, that the lists are regenerated **every week at 16:05 (GMT+0) on
Saturday**. Please double check before submitting a PR, to make sure that the
cask hasn't been updated by someone else yet.

### Available options

#### `-l, --pull <remote>`

Use to specify a remote to pull from (defaults to 'upstream').

#### `-p, --push <remote>`

Use to specify a remote to push to (defaults to 'origin').

#### `-b, --push-branch <name>`

Use to specify a branch name to push to.

By default it's generated automatically when fixing mode is enabled using the
format: `cask-homepage_<random>`. When you specify you own one, take into
account that **all existing changes in this branch will be overwritten** using
`git push --force`.

#### `-e, --push-edit`

Edit pushed changes.

This option can be used if you need to make pushed changes: for example if you
already created a PR and you need to modify some of the casks.

It automatically pulls the selected branch from the `origin`, asks which casks
to modify and launches the default editor to modify them. After making all the
changes it rebases the changes and pushes to the same branch again.

#### `-H, --header <header>`

Set browser header.

By default `User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2)
AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36` is
used.

#### `-o, --output <filepath>`

Output the results in CSV format into a file.

For example, to output a CSV list in your home directory:

```bash
cask-homepage -o ~/outdated.csv
```

#### `-f, --fix (<total>)`

Try to fix warnings automatically (optional: a total number of casks to fix).

#### `-a, --all`

Show and output all casks even if homepages are good.

By default, only the casks with homepage errors or warnings are shown on
screen and added to the CSV file. This parameter forces to show all the casks
even if the homepage is good.

#### `-d, --delete-branches`

Deletes local and remote branches named `cask-homepage_<random>`.

#### `-v, --version`

Show current script version.

#### `-h, --help`

Show the usage message with options descriptions.

### Available warnings (rules)

These are the warnings that are currently supported (rule itself is in
brackets):

- [Host has changed](#host-has-changed-host) _(host)_
- [Path has changed](#path-has-changed-path) _(path)_
- [Only HTTP is available](#only-http-is-available-http) _(http)_
- [HTTPS is available](#https-is-available-https) _(https)_
- [Server prefers to include WWW](#server-prefers-to-include-www-www) _(www)_
- [Server prefers to exclude WWW](#server-prefers-to-exclude-www-no_www) _(no_www)_
- [Server prefers to include a trailing slash](#server-prefers-to-include-a-trailing-slash-slash)
  _(slash)_
- [Server prefers to exclude a trailing slash](#server-prefers-to-exclude-a-trailing-slash-no_slash)
  _(no_slash)_
- [Missing a bare domain URL trailing slash](#missing-a-bare-domain-url-trailing-slash-bare_slash)
  _(bare_slash)_

If one of the enabled rules is violated one of the warnings from above will be
shown. Each successfully checked cask can have multiple warnings.

#### Host has changed _(host)_

It's also sometimes important to catch only those redirects that have a change
in the host itself. This rule is a good way to find those.

Example:

```
Cask name:       1password
Cask homepage:   https://agilebits.com/onepassword [301]
Status:          warning

                 1. Host has changed → https://1password.com/onepassword
                 2. Redirect found → https://1password.com/
```

#### Path has changed _(path)_

It helps to find URLs where path has been changed.

Example:

```
Cask name:       cura-beta
Cask homepage:   https://ultimaker.com/en/products/software [301]
Status:          warning

                 1. Path has changed → https://ultimaker.com/en/products/cura-software
```

#### Only HTTP is available _(http)_

Sometimes HTTPS version is no longer available so the URL redirects to HTTP
version instead. This rule helps to catch this kind of redirects.

Example:

```
Cask name:       doitim
Cask homepage:   https://doit.im/ [302]
Status:          warning

                 1. Only HTTP is available → http://doit.im/
```

#### HTTPS is available _(https)_

Since the HTTPS is more preferred over the usual plain HTTP the script checks if
it's available and gives an appropriate warning message if found. It will also
check if it's available even if host has been changed.

Example:

```
Cask name:       010-editor
Cask homepage:   http://www.sweetscape.com/ [301]
Status:          warning

                 1. HTTPS is available → https://www.sweetscape.com/
```

#### Server prefers to include WWW _(www)_

This rule checks whether server prefers to forcefully append a WWW to the URL.

Example:

```
Cask name:       bee
Cask homepage:   http://neat.io/bee/ [301]
Status:          warning

                 1. Server prefers to include WWW → http://www.neat.io/bee/
```

#### Server prefers to exclude WWW _(no_www)_

This rule checks whether server prefers to forcefully remove a WWW from the URL.

Example:

```
Cask name:       appcleaner
Cask homepage:   https://www.freemacsoft.net/appcleaner/ [301]
Status:          warning

                 1. Server prefers to exclude WWW → https://freemacsoft.net/appcleaner/
```

#### Server prefers to include a trailing slash _(slash)_

This rule checks whether server prefers to forcefully append a trailing slash to
the URL.

Example:

```
Cask name:       ghost
Cask homepage:   https://ghost.org/downloads [301]
Status:          warning

                 1. Server prefers to include a trailing slash → https://ghost.org/downloads/
```

#### Server prefers to exclude a trailing slash _(no_slash)_

This rule checks whether server prefers to forcefully remove a trailing slash
from the URL. It ignores all the cases where _bare_slash_ is needed.

Example:

```
Cask name:       logoist
Cask homepage:   http://www.syniumsoftware.com/logoist/ [301]
Status:          warning

                 1. Server prefers to exclude a trailing slash → http://www.syniumsoftware.com/logoist
```

#### Missing a bare domain URL trailing slash _(bare_slash)_

It's highly recommended to use a trailing slash in a bare domain URL like a
homepage. However, most mainstream browsers "append a trailing slash"
automatically to the request.

From [RFC 2616](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html):

> Please note, that the absolute path cannot be empty; if none is present in the
> original URI, it MUST be given as "/" (the server root).

Example:

```
Cask name:       5kplayer
Cask homepage:   https://www.5kplayer.com [200]
Status:          warning

                 1. Missing a bare domain URL trailing slash → https://www.5kplayer.com/
```

## Examples

### Default

By default you just have to `cd` into the Casks directory and run the script. It
will automatically use all the rules by default and should only those casks that
have some warnings or errors.

```bash
$ cd ~/path/to/homebrew-cask/Casks
$ cask-homepage
Checking homepages of 3435 casks using these rules:

bare_slash   enabled    Missing a bare domain URL trailing slash
host         enabled    Host has changed
http         enabled    Only HTTP is available
https        enabled    HTTPS is available
no_slash     enabled    Server prefers to exclude a trailing slash
no_www       enabled    Server prefers to exclude WWW
path         enabled    Path has changed
slash        enabled    Server prefers to include a trailing slash
www          enabled    Server prefers to include WWW
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       010-editor
Cask homepage:   http://www.sweetscape.com/ [301]
Status:          warning

                 1. HTTPS is available → https://www.sweetscape.com/
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       1password
Cask homepage:   https://agilebits.com/onepassword [301]
Status:          warning

                 1. Host has changed → https://1password.com/onepassword
                 2. Path has changed → https://1password.com/
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       ableton-live
Cask homepage:   https://ableton.com/en/live [301]
Status:          warning

                 1. Server prefers to include WWW → https://www.ableton.com/en/live/
                 2. Server prefers to include a trailing slash → https://www.ableton.com/en/live/
...
```

### CSV lists

In some cases it's useful to output all the found outdated casks into separate
CSV lists:

- <http://caskroom.victorpopkov.com/homebrew-cask/homepages.csv>
- <http://caskroom.victorpopkov.com/homebrew-versions/homepages.csv>

In order to do that you have to `cd` into the Casks directory and run the script
with `-o` option and `~/path/to/output.csv` argument. For example:

```bash
cd ~/path/to/homebrew-versions/Casks
cask-homepage -o '~/path/to/output.csv'
```
