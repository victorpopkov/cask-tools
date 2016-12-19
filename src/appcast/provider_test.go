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
		"sourceforge.xml":                    SourceForge,
		"sparkle_attributes_as_elements.xml": Sparkle,
		"sparkle_default_asc.xml":            Sparkle,
		"sparkle_default.xml":                Sparkle,
		"sparkle_incorrect_namespace.xml":    Sparkle,
		"sparkle_multiple_enclosure.xml":     Sparkle,
		"sparkle_no_releases.xml":            Sparkle,
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

	// GitHub
	actualProvider, actualUrl := p.GuessByUrl("https://github.com/atom/atom/releases.atom")
	assert.Equal(t, GitHubAtom, actualProvider)
	assert.Equal(t, "https://api.github.com/repos/atom/atom/releases", actualUrl)

	// Unknown
	actualProvider, actualUrl = p.GuessByUrl("https://example.com/")
	assert.Equal(t, Unknown, actualProvider)
	assert.Equal(t, "https://example.com/", actualUrl)
}

func TestString(t *testing.T) {
	assert.Equal(t, "-", Unknown.String())
	assert.Equal(t, "GitHub Atom", GitHubAtom.String())
	assert.Equal(t, "SourceForge", SourceForge.String())
	assert.Equal(t, "Sparkle", Sparkle.String())
}

func TestColorized(t *testing.T) {
	assert.Equal(t, "-", Unknown.Colorized())
	assert.Equal(t, "GitHub Atom", GitHubAtom.Colorized())
	assert.Equal(t, "SourceForge", SourceForge.Colorized())
	assert.Equal(t, "Sparkle", Sparkle.Colorized())
}
