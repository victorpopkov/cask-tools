# cask-homepage

Check homepages of the casks and try to fix them.

- [Description](#description)
  - [Lists of homepages](#lists-of-homepages)
  - [Available options](#available-options)
  - [Available warnings (rules)](#available-warnings)
- [Examples](#examples)
  - [Default](#default)
  - [CSV lists](#csv-lists)

## Description

The `cask-homepage` script is designed to check homepages of the casks for
availability by checking their response statuses. It's useful in finding casks
that are no longer maintained or available. It also checks the URL for these
rules (in brackets) below and gives appropriate warnings if violated:

- [HTTPS is available](#https-is-available-https) _(https)_
- [Only HTTP is available](#only-http-is-available-http) _(http)_
- [Redirect found](#redirect-found-redirect) _(redirect)_
- [Domain has changed](#domain-has-changed-domain) _(domain)_
- [Missing a trailing slash at the end](#missing-a-trailing-slash-at-the-end-slash)
  _(slash)_

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

#### `-i, --ignore <warnings>`

Ignore specified warnings separated by a comma: redirect https and slash.

It's useful when you would like to disable some warnings during the check. For
example to disable all warnings and display only casks that have homepage
errors:

```bash
cask-homepage -i https,http,redirect,domain,slash
```

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

#### `-d, --delete-branch`

Deletes local and remote branch named 'cask-homepage_fix'.

#### `-v, --version`

Show current script version.

#### `-h, --help`

Show the usage message with options descriptions.

### Available warnings (rules)

These are the warnings that are currently supported (rule itself is in
brackets):

- [HTTPS is available](#https-is-available-https) _(https)_
- [Only HTTP is available](#only-http-is-available-http) _(http)_
- [Redirect found](#redirect-found-redirect) _(redirect)_
- [Domain has changed](#domain-has-changed-domain) _(domain)_
- [Missing a trailing slash at the end](#missing-a-trailing-slash-at-the-end-slash)
  _(slash)_

#### HTTPS is available _(https)_

Since the HTTPS is more preferred over the usual HTTP the script checks if it's
available and gives an appropriate warning message.

Example:

```
Cask name:       010-editor
Cask homepage:   http://www.sweetscape.com/
Status:          warning

                 1. HTTPS is available → https://www.sweetscape.com/
```

#### Only HTTP is available _(http)_

Sometimes HTTPS version is no longer available so the URL redirects to HTTP
version instead. This rule helps to catch this kind of redirects.

Example:

```
Cask name:       airdisplay
Cask homepage:   https://avatron.com/apps/air-display/ [301]
Status:          warning

                 1. Only HTTP is available → http://avatron.com/apps/air-display/
```

#### Redirect found _(redirect)_

Usually when the homepage changes a redirect is added to the old URL to help
users find the new homepage location. However, the usage of old URL is not
recommended since in the future in can become unavailable.

> Please note, that **this rule doesn't disable _http_ and _domain_ rules** even
> though they are also a part of the redirect.

Example:

```
Cask name:       1password
Cask homepage:   https://agilebits.com/onepassword [301]
Status:          warning

                 1. Redirect found → https://1password.com/
```

#### Domain has changed _(domain)_

It's also sometimes important to catch only those redirects that have a change
in the domain. This rule catches this kind of redirects.

Example:

```
Cask name:       festify
Cask homepage:   https://getfestify.com/ [301]
Status:          warning

                 1. Domain has changed → https://festify.rocks/
```

#### Missing a trailing slash at the end _(slash)_

It's highly recommended to use a trailing slash in a bare domain URL like a
homepage. However, most mainstream browsers "append a trailing slash"
automatically to the request.

From [RFC 2616](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html):

> Please note, that the absolute path cannot be empty; if none is present in the
> original URI, it MUST be given as "/" (the server root).

Example:

```
Cask name:       5kplayer
Cask homepage:   https://www.5kplayer.com
Status:          warning

                 1. Missing a trailing slash at the end → https://www.5kplayer.com/
```

## Examples

### Default

By default you just have to `cd` into the Casks directory and run the script:

```bash
$ cd ~/path/to/homebrew-cask/Casks
$ cask-homepage
Checking homepages of 3420 casks...
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       010-editor
Cask homepage:   http://www.sweetscape.com/
Status:          warning

                 1. HTTPS is available → https://www.sweetscape.com/
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       1password
Cask homepage:   https://agilebits.com/onepassword [301]
Status:          warning

                 1. Redirect found → https://1password.com/
---------------------------------------------------------------------------------------------------------------------------------------------
Cask name:       4peaks
Cask homepage:   http://nucleobytes.com/index.php/4peaks [301]
Status:          warning

                 1. Redirect found → http://nucleobytes.com/4peaks/
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
cask-homepage -u -o '~/path/to/output.csv'
```
