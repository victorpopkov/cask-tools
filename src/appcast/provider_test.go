package appcast

import (
	"fmt"
	"testing"

	"general"

	"github.com/stretchr/testify/assert"
)

func TestGuessByContent(t *testing.T) {
	testCases := map[string]Provider{
		"github_default.xml":                 GitHubAtom,
		"sourceforge_default.xml":            SourceForge,
		"sourceforge_empty.xml":              SourceForge,
		"sourceforge_single.xml":             SourceForge,
		"sparkle_attributes_as_elements.xml": Sparkle,
		"sparkle_default_asc.xml":            Sparkle,
		"sparkle_default.xml":                Sparkle,
		"sparkle_incorrect_namespace.xml":    Sparkle,
		"sparkle_multiple_enclosure.xml":     Sparkle,
		"sparkle_no_releases.xml":            Sparkle,
		"sparkle_single.xml":                 Sparkle,
		"sparkle_without_comments.xml":       Sparkle,
		"sparkle_without_namespaces.xml":     Sparkle,
		"unknown.xml":                        Unknown,
	}

	for filename, provider := range testCases {
		// preparations
		content := string(general.GetFileContent(fmt.Sprintf(testdataPath, filename)))
		p := new(Provider)

		expected := provider
		actual := p.GuessByContent(content)
		assert.Equal(t, expected, actual, fmt.Sprintf("Provider for \"%s\" doesn't match expected value.", filename))
	}
}

func TestGuessByUrl(t *testing.T) {
	p := new(Provider)

	// before
	assert.Equal(t, Unknown, *p)

	// after (GitHub)
	actualProvider, actualUrl := p.GuessByUrl("https://github.com/atom/atom/releases.atom")
	assert.Equal(t, GitHubAtom, actualProvider)
	assert.Equal(t, "https://api.github.com/repos/atom/atom/releases", actualUrl)

	// after (Unknown)
	actualProvider, actualUrl = p.GuessByUrl("https://example.com/")
	assert.Equal(t, Unknown, actualProvider)
	assert.Equal(t, "https://example.com/", actualUrl)
}

func TestString(t *testing.T) {
	assert.Equal(t, "-", Unknown.String())
	assert.Regexp(t, "GitHub Atom", GitHubAtom.String())
	assert.Regexp(t, "SourceForge", SourceForge.String())
	assert.Regexp(t, "Sparkle", Sparkle.String())
}

func TestColorized(t *testing.T) {
	assert.Equal(t, "-", Unknown.Colorized())
	assert.Regexp(t, "GitHub Atom", GitHubAtom.Colorized())
	assert.Regexp(t, "SourceForge", SourceForge.Colorized())
	assert.Regexp(t, "Sparkle", Sparkle.Colorized())
}
