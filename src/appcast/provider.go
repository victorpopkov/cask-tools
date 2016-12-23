package appcast

import (
	"fmt"
	"regexp"

	"github.com/fatih/color"
)

type Provider int

const (
	Unknown     Provider = iota // 0
	GitHubAtom                  // 1
	SourceForge                 // 2
	Sparkle                     // 3
)

var providers = [...]string{
	"-",
	"GitHub Atom",
	"SourceForge",
	"Sparkle",
}

// GuessByContent returns the correct Provider based on the provided content.
func (self Provider) GuessByContent(content string) Provider {
	regexSparkle := regexp.MustCompile(`(?s)(<rss.*xmlns:sparkle)|(?s)(<rss.*<enclosure)`)
	regexGitHubAtom := regexp.MustCompile(`(?s)<feed.*<id>tag:github.com`)
	regexSourceForge := regexp.MustCompile(`(?s)(<rss.*xmlns:sf)|(?s)(<channel.*xmlns:sf)`)

	if regexSparkle.MatchString(content) {
		return Sparkle
	}

	if regexGitHubAtom.MatchString(content) {
		return GitHubAtom
	}

	if regexSourceForge.MatchString(content) {
		return SourceForge
	}

	return Unknown
}

// GuessByContent returns the correct Provider based on the provided content.
func (self Provider) GuessByUrl(url string) (Provider, string) {
	regexGitHubAtom := regexp.MustCompile(`.*github\.com\/(?P<user>.*?)\/(?P<repo>.*?)\/.*\.atom`)

	if regexGitHubAtom.MatchString(url) {
		names := regexGitHubAtom.SubexpNames()
		matches := regexGitHubAtom.FindAllStringSubmatch(url, -1)[0]

		md := map[string]string{}
		for i, n := range matches {
			md[names[i]] = n
		}

		url = fmt.Sprintf("https://api.github.com/repos/%s/%s/releases", md["user"], md["repo"])
		return GitHubAtom, url
	}

	return Unknown, url
}

// String returns the string representation of Provider struct.
func (self Provider) String() string {
	return providers[self]
}

// Colorized returns the colorized string.
func (self Provider) Colorized() string {
	if self == Unknown {
		return self.String()
	}

	return color.WhiteString(self.String())
}
